#!/usr/bin/env python
import socket
import sys
import commands
def _local_hostname():
    return commands.getoutput('hostname')
def _local_ip(cc_host,port):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    except socket.error, msg:
        print 'Failed to create socket.Error code:' + str(msg[0])
        sys.exit()
    s.connect((cc_host,port))
    return s.getsockname()[0]
def main():
    cc_host = '192.168.1.50'
    port = 4505
    grains = {}
    grains['local_hostname_ip'] = {_local_hostname():_local_ip(cc_host,port)}
    return grains
#main()