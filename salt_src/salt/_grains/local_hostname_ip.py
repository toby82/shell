#!/usr/bin/python
import subprocess
import sys
import commands
def _local_hostname():
    return commands.getoutput('hostname')
def _local_ip():
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
            r_host, r_port = chunks[4].rsplit(':', 1)
            if r_port == '4505':
                #print chunks[3].rsplit(':', 1)
                local_host, local_port = chunks[3].rsplit(':', 1)
                hosts.append(local_host)
    return hosts

    
def main():
    grains = {}
    grains['local_hostname_ip'] = _local_ip()[0]
    return grains

   
