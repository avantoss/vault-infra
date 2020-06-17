#!/usr/bin/env python3

import logging
import subprocess
import shutil
import requests
import lgr

log = logging.getLogger( "vault" )

url = "https://vault.tstllc.net"
prefix = "vault://"

class Client:

    def __init__(self, base=url ):
        self._base = base
        self._cache = dict()

    """
    Parses a string that is a reference to a secret in vault in the form of 'vault://<secret path>[:<key in secret>]'
    """
    def resolve(self, vurl ):
        if vurl and vurl.startswith(prefix):
            sub = vurl[len(prefix):]
            pos = sub.find( ':' )
            if pos == -1:
                # raise Exception( "Invalid vault secret url: {}".format(vurl) )
                path = sub
                key = None
            else:
                path = sub[0:pos]
                key = sub[pos+1:]

            ret = self.value( path, key )
            if not ret: raise Exception( "Unable to resolve secret url: {}, path: {}, key: {}".format(vurl, path, key) )
            return ret
        else:
            return vurl

    def value(self, path, key=None ):
        sec = self.get( path )
        if sec:
            if key:
                return sec.get( key )
            else:
                if len(sec) == 1:
                    for k, v in sec.items():
                        log.debug( "value: secret path: {}, has single key: {}".format(path,k) )
                        return v
                else:
                    raise Exception( "Found secret but do not know which value to return: {}".format(sec.keys()))

    def get(self, path):
        ret = self._cache.get( path )
        if not ret:
            ret = self.fetch( path )
            if ret: self._cache[path] = ret
        else:
            log.debug( "value: found cached secret: {}".format(path) )
        return ret

    def fetch(self, path):
        log.debug( "fetch: fetching secret path: {}".format(path) )
        response = self.send_get( "secret/data/{}".format(path) )
        result = response.json()
        if 'data' in result:
            secret = result['data']['data']
            log.log(lgr.TRACE, "fetch: path: {}, secret: {}".format(path, secret))
            return secret
        else:
            log.log(lgr.TRACE, "fetch: path: {}, response: {}".format(path, result))

    def clear(self):
        self._cache.clear()

    def send_get(self, path):
        return requests.get("{}/{}".format(self.base_uri, path), headers=Client.headers())

    def send_list(self, path):
        return requests.request("LIST", "{}/{}".format(self.base_uri, path), headers=Client.headers())

    def send_post(self, path, data):
        return requests.post("{}/{}".format(self.base_uri, path), json=data, headers=Client.headers())

    @property
    def base_uri(self):
        return "{}/v1".format(self._base)

    @staticmethod
    def token():
        exe = shutil.which('vault')
        if not exe: raise Exception( "Coulld not find vault executable" )
        cmd = [ exe, 'print', 'token' ]
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE)
        out, err = p.communicate()
        if p.returncode != 0:
            raise Exception("Failed getting current token: {}".format(p.returncode))
        return out.decode('utf-8').strip()

    @staticmethod
    def headers():
        tok = Client.token()
        return {'X-Vault-Token': tok}

