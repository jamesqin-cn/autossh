#!/usr/bin/env python
import hmac
import base64
import struct
import hashlib
import time
import json
import os 
import sys

class GoogleAuthenticator():
    def __init__(self, secret = None):
        self.SetSecret(secret)
        
    def GetHotpToken(self, secret, intervals_no):
        """This is where the magic happens."""
        key = base64.b32decode(self.Normalize(secret), True) # True is to fold lower into uppercase
        msg = struct.pack(">Q", intervals_no)
        h = hmac.new(key, msg, hashlib.sha1).digest()
        o = ord(h[19]) & 15
        h = str((struct.unpack(">I", h[o:o+4])[0] & 0x7fffffff) % 1000000)
        return self.Prefix0(h)


    def GetTotpToken(self, secret):
        """The TOTP token is just a HOTP token seeded with every 30 seconds."""
        return self.GetHotpToken(secret, intervals_no=int(time.time())//30)


    def Normalize(self, key):
        """Normalizes secret by removing spaces and padding with = to a multiple of 8"""
        k2 = key.strip().replace(' ','')
        # k2 = k2.upper()	# skipped b/c b32decode has a foldcase argument
        if len(k2)%8 != 0:
            k2 += '='*(8-len(k2)%8)
        return k2


    def Prefix0(self, h):
        """Prefixes code with leading zeros if missing."""
        if len(h) < 6:
            h = '0'*(6-len(h)) + h
        return h

    def SetSecret(self, secret):
        self._secret = secret

    def GetToken(self):
        return self.GetTotpToken(self._secret)

if __name__ == "__main__":
    if len(sys.argv) == 1:
        print 'Error, missing parameter <secret>'
        print 'Usage:'
        print "    %s <secret>" % (sys.argv[0])
        quit()

    secret = sys.argv[1]
    print GoogleAuthenticator(secret).GetToken()

