#!/bin/bash
cd /etc/sysconfig/network-scripts/
for eth in ifcfg-*; do
    if [ $eth == "ifcfg-lo" ]; then
        continue
    fi
    ip=$(ip -o -4 addr list | grep ${eth#*-} | awk '{print $4}')
    ip addr del $ip dev ${eth#*-} && rm -f ${eth}
    if [ $? -eq 0 ]; then
        echo "${eth#*-} deleted"
    fi
done
salt-key -D -y
cat /dev/null > /etc/salt/grains
sed -i -e '/autodeploy/d' -e '/\scc[1-9]*\.*/d' -e '/\snc[1-9]*\.*/d' -e '/\snn[1-9]*\.*/d' /etc/hosts
if [ -d /opt/server/iaas ]; then
    cd /opt/server/iaas && rm -f answerfile*
fi
