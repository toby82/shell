#!/usr/bin/python
import subprocess
import sys
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
            local_host, local_port = chunks[4].rsplit(':', 1)
            hosts.append(local_host)
    return list(set(hosts))
print(get_local_hosts())
        #remote_host, remote_port = chunks[5].rsplit('.', 1)


