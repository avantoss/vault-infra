#!/usr/bin/env python3

import sys
import textwrap
import argparse
import logging
import lgr
import re
import tempfile
import subprocess
import shutil
import json
import os.path
import gnupg
import yu
import base64
import getpass

from pathlib import Path

log = logging.getLogger( "vadmin" )

here = os.path.dirname(os.path.realpath(__file__))
root = Path(here).parent

def b64dec( v ):
    return base64.b64decode(v) if v is not None else None

def run( cmd, inp=None, out=None ):
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE if inp else None, stdout=subprocess.PIPE if out else None)
    out, err = p.communicate(input=inp.encode('utf-8') if inp else None)
    log.debug( "run: command: {}, input: {}, output: {}".format(cmd, inp, out) )
    if p.returncode != 0:
        raise Exception("Failed executing: {}: {}".format(cmd, p.returncode))

    od = out.decode('utf-8') if out else None
    log.debug( "run: output: {}".format(od) )
    return od, err


def vault( *args ):
    cmd = [shutil.which('vault'), 'operator' ]
    cmd.extend( args )
    return cmd

def get_opts():
    cli = argparse.ArgumentParser(
        description=textwrap.dedent("Vault administration utility"),
        formatter_class=argparse.RawTextHelpFormatter)

    lgr.add_options( cli )

    subs = cli.add_subparsers()
    add_gpg_options( subs )
    add_rekey_options( subs )
    add_root_options( subs )

    return cli

def add_gpg_options( subs ):
    sps = subs.add_parser('gpg', help='gpg operations').add_subparsers()

    spp = sps.add_parser('list', help='list keys')
    spp.set_defaults(fn=process_gpg_list)

    spp = sps.add_parser('decrypt', help='decrypt key')
    spp.add_argument('file', help="encrypted keyfile")
    spp.set_defaults(fn=process_gpg_decrypt)

def add_rekey_options( subs ):
    sps = subs.add_parser('rekey', help='Rekey operations').add_subparsers()

    spp = sps.add_parser('init', help='initialize rekey process')
    spp.add_argument('--config', '-c', default=os.path.join(root,"vadmin.yml"), help="number of shards required to unseal")
    spp.set_defaults(fn=process_rekey_init)

    spp = sps.add_parser('add', help='add a new key to the rekey operation')
    spp.add_argument('--config', '-c', default=os.path.join(root,"vadmin.yml"), help="number of shards required to unseal")
    spp.add_argument('--nonce', '-n', required=True, help="nonce from rekey -init")
    spp.add_argument('--key', '-k', help="key plaintext")
    spp.add_argument('--file', '-f', help="encrypted keyfile")
    spp.set_defaults(fn=process_rekey_add)

    spp = sps.add_parser('verify', help='verify a new key to the rekey operation')
    spp.add_argument('--nonce', '-n', required=True, help="nonce from rekey -init")
    spp.add_argument('--key', '-k', help="key plaintext")
    spp.add_argument('--file', '-f', help="encrypted keyfile")
    spp.set_defaults(fn=process_rekey_verify)

def add_root_options( subs ):
    sps = subs.add_parser('root', help='Generate root operations').add_subparsers()

    spp = sps.add_parser('init', help='initialize the new root key process')
    spp.add_argument('--key', '-k', help="key plaintext")
    spp.add_argument('--file', '-f', help="encrypted keyfile")
    spp.set_defaults(fn=process_root_init)

    spp = sps.add_parser('add', help='verify a new key to the rekey operation')
    spp.add_argument('nonce', help="nonce")
    spp.add_argument('--key', '-k', help="key plaintext")
    spp.add_argument('--file', '-f', help="encrypted keyfile")
    spp.set_defaults(fn=process_root_add)

    spp = sps.add_parser('decode', help='decode the encoded root token')
    spp.add_argument('token', help="encoded token")
    spp.add_argument('otp', help="one-time password")
    spp.set_defaults(fn=process_root_decode)

def get_user_key( user, keys ):
    ret = None
    for key in keys:
        for uid in key['uids']:
            if user in uid:
                if not ret:
                    ret = key
                else:
                    raise Exception( "Found multiple keys matching user: {}, {} and {}".format(user, ret, key) )
    if not ret:
        raise Exception( "Could not find key matching: {}".format(user) )

    return ret

def each_user_key( users ):
    gpg = gnupg.GPG()
    keys = gpg.list_keys()
    ret = []
    for user in users:
        yield user, get_user_key(user,keys)

def with_user_key_files( users, handler ):
    gpg = gnupg.GPG()
    with tempfile.TemporaryDirectory() as tmp:
        user_key_files = list()
        for user, key in each_user_key( users ):
            asc = gpg.export_keys(key['keyid'])
            log.debug( "key: {}".format(key) )
            filename = "{}.asc".format(user.replace('.','_').replace('@','_').replace( '__','_') )
            file = os.path.join( tmp, filename )
            log.debug( "Writing: {}".format(filename) )
            with open( file, "w" ) as fd:
                fd.write( asc )
            user_key_files.append( (user, file) )

        handler( user_key_files )

def load_config( config ):
    return yu.yaml_load_file( config )

def run_command_and_parse_keys( cmd, inp ):
    log.debug( "run_command_and_parse_keys: command: {}, input: {}".format(cmd,inp) )
    out, err = run( cmd, inp, True )
    keys = list()
    key_line = re.compile("^Key \\d+ (.*)")
    for line in out.splitlines():
        print( line )
        match = key_line.match(line)
        if match:
            keys.append( match.group(1) )
    return keys

def get_passphrase():
    passphrase = None
    while not passphrase:
        try:
            passphrase = getpass.getpass(prompt='Entry GPG passphrase > ')
        except Exception as error:
            print('ERROR', error, file=sys.stderr)

    return passphrase

def get_decrypted_key( file ):
    gpg = gnupg.GPG()
    passphrase = get_passphrase()
    with open( file, "rb") as fd:
        encrypted = fd.read()
        log.debug( "get_decrypted_key: encrypted key: {}".format(encrypted) )
        decrypted = gpg.decrypt( b64dec(encrypted), passphrase=passphrase )
        if decrypted.ok:
            ret = decrypted.data.decode('utf-8')
            log.debug( "get_decrypted_key: decrypted key: {}".format(decrypted) )
        else:
            raise Exception( "Failed decrypting: {} : {}".format(decrypted.status,decrypted.stderr) )

        return ret

def get_user_key( file, key ):
    inp = get_decrypted_key( file ) if file else key
    if not inp: raise Exception( "No decryption key/file provided")
    return inp

def process_rekey_init( config, **_ ):
    cfg = load_config( config )
    threshold = cfg['threshold']
    def handler( user_key_files ):
        shares = len(user_key_files)
        keys_arg = ','.join([ file for user, file in user_key_files ] )
        cmd = vault( 'rekey', '-init', '-verify', '-backup',
            '-key-shares={}'.format(shares),
            '-key-threshold={}'.format(threshold),
            '-pgp-keys={}'.format(keys_arg)
        )
        log.debug( "process_rekey_init: command: {}".format(cmd) )
        run( cmd )

    with_user_key_files( cfg['users'], handler )

def process_rekey_add( config, key, file, nonce, **_ ):
    cfg = yu.yaml_load_file( config )
    users = cfg['users']
    cmd = vault( 'rekey', '-nonce={}'.format(nonce), '-' )
    inp = get_user_key( file, key )
    keys = run_command_and_parse_keys( cmd, inp )

    if keys:
        if len(keys) == len(users):
            for user, key in zip( users, keys ):
                print( "{} : {}".format(user, key) )
        else:
            log.error( "Key length does not match user length: {} != {}".format(users, keys) )
    else:
        log.info( "No keys returned" )


def process_rekey_verify( key, file, nonce, **_ ):
    cmd = vault( 'rekey', '-verify', '-nonce={}'.format(nonce), '-' )
    inp = get_user_key( file, key )
    out, err = run( cmd, inp )

def root_add( key, nonce ):
    cmd = vault( 'generate-root', '-nonce={}'.format(nonce), '-' )
    return run( cmd, key )

def process_root_init( key, file, **_ ):
    inp = get_user_key( file, key )
    cmd = vault( 'generate-root', '-generate-otp' )
    otp, err = run( cmd, out=True )
    otp = otp.strip()
    cmd = vault( 'generate-root', '-init', '-otp={}'.format(otp) )
    out, err = run( cmd, out=True )
    nonce_line = re.compile("^Nonce\\s+(.*)")

    nonce = None
    for line in out.splitlines():
        print( line )
        match = nonce_line.match(line)
        if match:
            nonce = match.group(1)

    root_add( inp, nonce )
    print( "-" * 70 )
    print( "One time password: {}".format(otp) )
    print( "Nonce: {}".format(nonce) )
    print( "-" * 70 )

def process_root_decode( token, otp,**_ ):
    cmd = vault( 'generate-root', '-decode={}'.format(token), '-otp={}'.format(otp) )
    decoded, err = run( cmd, out=True )
    print( "Root token: {}".format(decoded) )

def process_root_add( key, file, nonce, **_ ):
    inp = get_user_key( file, key )
    out, err = root_add( inp, nonce )
    print( out )

def process_gpg_decrypt( file, **_ ):
    decrypted = get_decrypted_key( file )
    print( decrypted )

def process_gpg_list( **_ ):
    gpg = gnupg.GPG()
    keys = gpg.list_keys()
    for key in keys:
        print( json.dumps(key, sort_keys=True, indent=2) )
        print( '-' * 80 )

cli = get_opts()
options = cli.parse_args( sys.argv[1:] )
lgr.init( options )

if 'fn' in options:
    options.fn( **vars(options) )
else:
    cli.print_help()

