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
from pathlib import Path

log = logging.getLogger( "vadmin" )

here = os.path.dirname(os.path.realpath(__file__))
root = Path(here).parent

key_line = re.compile( "^Key \d+: (.*)")

def get_opts():
    cli = argparse.ArgumentParser(
        description=textwrap.dedent("Vault administration utility"),
        formatter_class=argparse.RawTextHelpFormatter)

    lgr.add_options( cli )

    subs = cli.add_subparsers()
    add_gpg_options( subs )
    add_rekey_options( subs )

    return cli

def add_gpg_options( subs ):
    sps = subs.add_parser('gpg', help='gpg operations').add_subparsers()

    spp = sps.add_parser('list', help='list keys')
    spp.set_defaults(fn=process_gpg_list)


def add_rekey_options( subs ):
    sps = subs.add_parser('rekey', help='Rekey operations').add_subparsers()

    spp = sps.add_parser('init', help='initialize rekey process')
    spp.add_argument('--config', '-c', default=os.path.join(root,"vadmin.yml"), help="number of shards required to unseal")
    spp.set_defaults(fn=process_rekey_init)

    spp = sps.add_parser('add', help='add a new key to the rekey operation')
    spp.add_argument('--config', '-c', default=os.path.join(root,"vadmin.yml"), help="number of shards required to unseal")
    spp.add_argument('--nonce', '-n', help="nonce from rekey -init")
    spp.add_argument('--key', '-k', help="key plaintext")
    spp.add_argument('--file', '-f', help="encrypted keyfile")
    spp.add_argument('--test', '-t', action='store_true', help="run code through test file to mimic real rekey")
    spp.set_defaults(fn=process_rekey_add)

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
            # file = filename
            log.debug( "Writing: {}".format(filename) )
            with open( file, "w" ) as fd:
                fd.write( asc )
            user_key_files.append( (user, file) )

        handler( user_key_files )

def load_config( config ):
    return yu.yaml_load_file( config )

def run_command_and_parse_keys( cmd, input ):
    log.debug( "run_command_and_parse_keys: command: {}, input: {}".format(cmd,input) )
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE if input else None, stdout=subprocess.PIPE )
    out, err = p.communicate(input=input)
    if p.returncode != 0:
        raise Exception("Failed executing: {}: {}".format(cmd, p.returncode))

    keys = list()
    for line in out.decode("utf-8").splitlines():
        print( line )
        match = key_line.match(line)
        if match:
            keys.append( match.group(1) )
    return keys

def process_rekey_init( config, **_ ):
    cfg = load_config( config )
    threshold = cfg['threshold']
    def handler( user_key_files ):
        shares = len(user_key_files)
        keys_arg = ','.join([ file for user, file in user_key_files ] )
        cmd = [ shutil.which('vault'), 'operator', 'rekey', '-init', '-verify', '-backup',
            '-key-shares={}'.format(shares),
            '-key-threshold={}'.format(threshold),
            '-pgp-keys={}'.format(keys_arg)
        ]
        log.debug( "process_rekey_init: command: {}".format(cmd) )
        p = subprocess.Popen(cmd)
        p.communicate()
        if p.returncode != 0:
            raise Exception("Failed initializing rekey: {} : {}".format(cmd, p.returncode))

    with_user_key_files( cfg['users'], handler )

def get_passphrase():
    passphrase = None
    while not passphrase:
        print("Entry GPG passphrase > ", end='', file=sys.stderr)
        sys.stderr.flush()
        passphrase = sys.stdin.readline().strip()

    return passphrase

def get_decrypted_key( file ):
    gpg = gnupg.GPG()
    passphrase = get_passphrase()
    with open( file, "rb") as fd:
        encrypted = fd.read()
        log.debug( "process_rekey_add: encrypted key: {}".format(encrypted) )
        decrypted = gpg.decrypt( encrypted, passphrase=passphrase )
        if decrypted.ok:
            ret = decrypted.data
            log.debug( "process_rekey_add: decrypted key: {}".format(input) )
        else:
            raise Exception( "Failed decrypting: {} : {}".format(decrypted.status,decrypted.stderr) )

    return ret

def process_rekey_add( config, key, file, nonce, test, **_ ):
    cfg = yu.yaml_load_file( config )
    users = cfg['users']
    if test:
        cmd = [ shutil.which("cat"), os.path.join(root,"rekey.log") ]
        input = None
    else:
        cmd = [ shutil.which("vault"), 'operator', 'rekey', '-nonce={}'.format(nonce), '-' ]
        if file:
            input = get_decrypted_key( file )
        elif key:
            input = key.encode('utf-8')

    keys = run_command_and_parse_keys( cmd, input )

    if keys:
        if len(keys) == len(users):
            for user, key in zip( users, keys ):
                print( "{} : {}".format(user, key) )
        else:
            log.error( "Key length does not match user length: {} != {}".format(users, keys) )
    else:
        log.info( "No keys returned" )

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

