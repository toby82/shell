#!/usr/bin/python
import subprocess
import sys
grains = {}
def get_local_hosts():
    hosts = list()
    try: 
        data = subprocess.check_output(['netstat','-tn'])
    except:
        raise
    lines = data.split('\n')
    for line in lines:
        if 'ESTABLISHED' not in line:
            continue
        else:
            chunks = line.split()
            local_host, local_port = chunks[3].rsplit(':', 1)
            hosts.append(local_host)
    grains['local_ip'] = list(set(hosts))[0]
    return grains

        #remote_host, remote_port = chunks[5].rsplit('.', 1)


