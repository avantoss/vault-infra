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
import requests
import boto3
import urllib3

from pathlib import Path

log = logging.getLogger( "vadmin" )

here = os.path.dirname(os.path.realpath(__file__))
root = Path(here).parent

def header():
    print( "-" * 70 )

def b64dec( v ):
    return base64.b64decode(v) if v is not None else None

def b64enc( v ):
    return base64.b64encode(v.encode("utf-8")).decode("utf-8") if v is not None else None

def run( cmd, inp=None, out=None, env=None ):
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE if inp else None, stdout=subprocess.PIPE if out else None, env=env )
    out, err = p.communicate(input=inp.encode('utf-8') if inp else None)
    log.debug( "run: command: {}, input: {}, output: {}".format(cmd, inp, out) )
    if p.returncode != 0:
        raise Exception("Failed executing: {} : {} : {} : {}".format(cmd, p.returncode, out, err))

    od = out.decode('utf-8') if out else None
    log.debug( "run: output: {}".format(od) )
    return od, err


def find_single(out, expr, group=1):
    ret = None
    for line in out.splitlines():
        print( line )
        match = expr.match(line)
        if match:
            ret = match.group(group)
    return ret

def find_multi(out, expr, group=1):
    ret = list()
    for line in out.splitlines():
        print( line )
        match = expr.match(line)
        if match:
            ret.append( match.group(group) )
    return ret


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
    add_unseal_options( subs )
    add_server_options( subs )

    return cli

def add_server_options( subs ):
    sps = subs.add_parser('server', help='server operations').add_subparsers()

    spp = sps.add_parser('list', help='list keys')
    spp.set_defaults(fn=process_server_list)

def add_gpg_options( subs ):
    sps = subs.add_parser('gpg', help='gpg operations').add_subparsers()

    spp = sps.add_parser('list', help='list keys')
    spp.set_defaults(fn=process_gpg_list)

    spp = sps.add_parser('decrypt', help='decrypt key')
    spp.add_argument('file', help="encrypted keyfile")
    spp.set_defaults(fn=process_gpg_decrypt)

def add_key_args( spp ):
    spp.add_argument('--key', '-k', help="key plaintext")
    spp.add_argument('--file', '-f', help="encrypted keyfile")

def add_config_arg( spp ):
    spp.add_argument('--config', '-c', default=os.path.join(root,"vadmin.yml"), help="config file location")

def add_nonce_arg( spp ):
    spp.add_argument('nonce', help="nonce for rekey/generate-root")

def add_rekey_options( subs ):
    sps = subs.add_parser('rekey', help='Rekey operations').add_subparsers()

    spp = sps.add_parser('init', help='initialize rekey process')
    add_config_arg( spp )
    spp.set_defaults(fn=process_rekey_init)

    spp = sps.add_parser('add', help='add a new key to the rekey operation')
    add_nonce_arg( spp )
    add_key_args( spp )
    add_config_arg( spp )
    spp.set_defaults(fn=process_rekey_add)

    spp = sps.add_parser('verify', help='verify a new key to the rekey operation')
    add_nonce_arg( spp )
    add_key_args( spp )
    spp.set_defaults(fn=process_rekey_verify)

def add_root_options( subs ):
    sps = subs.add_parser('root', help='Generate root operations').add_subparsers()

    spp = sps.add_parser('init', help='initialize the new root key process')
    add_key_args( spp )
    spp.set_defaults(fn=process_root_init)

    spp = sps.add_parser('add', help='verify a new key to the rekey operation')
    add_nonce_arg( spp )
    add_key_args( spp )
    spp.set_defaults(fn=process_root_add)

    spp = sps.add_parser('decode', help='decode the encoded root token')
    spp.add_argument('token', help="encoded token")
    spp.add_argument('otp', help="one-time password")
    spp.set_defaults(fn=process_root_decode)

def add_unseal_options( subs ):
    spp = subs.add_parser('unseal', help='initialize the new root key process')
    spp.add_argument('address', help="IP or url to vault server")
    add_key_args( spp )
    spp.set_defaults(fn=process_unseal)

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
    key_line = re.compile("^Key \\d+ (.*)")
    return find_multi( out, key_line )

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

def get_input_key( file, key ):
    kf = file if file else os.environ.get('VAULT_KEY')
    inp = get_decrypted_key( kf ) if kf else key
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
    inp = get_input_key( file, key )
    keys = run_command_and_parse_keys( cmd, inp )

    if keys:
        if len(keys) == len(users):
            header()
            for user, key in zip( users, keys ):
                print( "{} : {}".format(user, key) )
            header()
        else:
            log.error( "Key length does not match user length: {} != {}".format(users, keys) )
    else:
        log.info( "No keys returned" )


def process_rekey_verify( key, file, nonce, **_ ):
    cmd = vault( 'rekey', '-verify', '-nonce={}'.format(nonce), '-' )
    inp = get_input_key( file, key )
    run( cmd, inp )

def root_add( key, nonce ):
    cmd = vault( 'generate-root', '-nonce={}'.format(nonce), '-' )
    return run( cmd, key, out=True )

def process_root_init( key, file, **_ ):
    inp = get_input_key( file, key )
    cmd = vault( 'generate-root', '-generate-otp' )
    otp, err = run( cmd, out=True )

    otp = otp.strip()
    cmd = vault( 'generate-root', '-init', '-otp={}'.format(otp) )
    out, err = run( cmd, out=True )

    nonce_line = re.compile("^Nonce\\s+(.*)")
    nonce = find_single( out, nonce_line )

    root_add( inp, nonce )
    header()
    print( "One time password: {}".format(otp) )
    print( "Nonce: {}".format(nonce) )
    header()

def process_root_decode( token, otp,**_ ):
    cmd = vault( 'generate-root', '-decode={}'.format(token), '-otp={}'.format(otp) )
    decoded, err = run( cmd, out=True )
    header()
    print( "Root token: {}".format(decoded) )
    header()

def process_root_add( key, file, nonce, **_ ):
    inp = get_input_key( file, key )
    out, err = root_add( inp, nonce )
    token_line = re.compile("^Encoded Token\\s+(.*)")
    token = find_single( out, token_line )
    if token:
        header()
        print( "Encoded token: {}".format(token) )
        header()
    else:
        print( "Token not available yet. Need additional keys to be entered" )

def process_unseal( address, key, file, **_ ):
    addr = address if address.startswith('http') else 'https://{}:8200'.format(address)
    inp = get_input_key( file, key )
    response = requests.post( '{}/v1/sys/unseal'.format(addr), json={ 'key': inp }, verify=False )
    print(json.dumps(response.json(), sort_keys=True, indent=2))
    response.raise_for_status()


def process_gpg_decrypt( file, **_ ):
    decrypted = get_decrypted_key( file )
    print( decrypted )

def process_gpg_list( **_ ):
    gpg = gnupg.GPG()
    keys = gpg.list_keys()
    for key in keys:
        print( json.dumps(key, sort_keys=True, indent=2) )
        header()

def describe_instances( prefix ):
    client = boto3.client('ec2')
    args = {'Filters': [{
        'Name': 'tag:Name',
        'Values': [ '{}*'.format(prefix) ]
    } ] }

    instances = []
    while True:
        response = client.describe_instances( **args )
        for res in response['Reservations']:
            instances.extend( res['Instances'] )
        if 'NextToken' in response:
            args['NextToken'] = response['NextToken']
        else:
            break

    return instances

def server_status( ip ):
    addr = 'https://{}:8200'.format(ip)
    url = '{}/v1/sys/health'.format(addr)
    log.debug( "server_status: url: {}".format(url) )
    response = requests.get( url, verify=False )
    # response.raise_for_status()
    ret = response.json()
    log.debug( "server_status: ip: {}, status: {}".format(ip, ret) )
    return ret

def process_server_list( **_ ):
    instances = describe_instances( 'vault-prod' )
    for inst in instances:
        try:
            inst['ServerStatus'] = server_status( inst['PrivateIpAddress'] )
        except Exception as ex:
            log.error( "process_server_list: could not get information on instance: {}".format(inst) )

    def check(v):
        return 'X' if v else ''

    fmt = '{0: <20} {1: <17} {2: <11} {3: <7} {4: <6}'
    print( fmt.format( "Instance", "IP", "Initialized", "Master", "Sealed") )
    for inst in instances:
        status = inst.get('ServerStatus')
        if status:
            print( fmt.format(
                inst.get('InstanceId'),
                inst.get('PrivateIpAddress'),
                check(status.get('initialized')),
                check(not status.get('standby')),
                check(status.get('sealed'))) )


cli = get_opts()
options = cli.parse_args( sys.argv[1:] )
lgr.init( options )

urllib3.disable_warnings()
boto3.set_stream_logger('botocore', logging.WARNING)
boto3.set_stream_logger('s3transfer', logging.WARNING)

if 'fn' in options:
    options.fn( **vars(options) )
else:
    cli.print_help()

