#!/bin/bash
cd /etc/sysconfig/network-scripts/
for eth in ifcfg-*; do
    if [ $eth == "ifcfg-lo" ]; then
        continue
    fi
    ip=$(ip -o -4 addr list | grep ${eth#*-} | awk '{print $4}')
    echo "${eth#*-} deleted"
    ip addr del $ip dev ${eth#*-} && rm -f ${eth}
done
