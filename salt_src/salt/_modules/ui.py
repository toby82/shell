import os
import salt.utils
import logging

log = logging.getLogger(__name__)

##  salt "*" saltutil.sync_modules && salt "*" ui.scan_hardware_info

def scan_hardware_info():
    result = {}
    result = __salt__['grains.items']()
    result['ipmi_info'] = get_impi_info()
    result['mgnet'] = get_mgip()
    return result

def get_mgip():
    master_port = 4505
    mg_net_dic = {"mgip": "", "mgdev": ""}
    #mg_net_ip = __salt__['cmd.run'](netstat -anp | grep 4505 | grep -v '0.0.0.0' | head -n 1 | awk '{print \$4 }' | awk -F ':' '{print \$1 }')
    #mg_net_dic['mgip'] = mg_net_ip
    tcp_result = __salt__['network.active_tcp']()
    for (num, proc) in tcp_result.items():
        if proc['remote_port'] == master_port:
            if proc['local_addr'] != "127.0.0.1" or proc['local_addr'] != "0.0.0.0" or proc['remote_addr'] != "127.0.0.1" or proc['remote_addr'] != "0.0.0.0":
              mg_net_dic['mgip'] = proc['local_addr']
              break

    if mg_net_dic['mgip'] == "":
        return mg_net_dic

    interface_result = __salt__['network.interfaces']()
    for (dev, info) in interface_result.items():
        if info.has_key('inet') is False:
            continue
        inet_array = info['inet']
        for inet in inet_array:
            if inet['address'] == mg_net_dic['mgip']:
                mg_net_dic['mgdev'] = dev
                break
    return mg_net_dic


def get_impi_info():
    ipmi_dic = {}
    cmd_exit = __salt__['cmd.has_exec']("ipmitool")
    if cmd_exit == False:
        return ipmi_dic

    ipmistr = ""
    try:
        ipmistr = __salt__['cmd.run']("ipmitool lan print")
        log.warning(ipmistr)
        ipmistr_arr = ipmistr.split('\n')
        for line in ipmistr_arr:
            line = line.strip()
            pos = line.index(":")
            if pos == -1:
                continue
            key = line[0:pos].strip()
            if len(key) == 0:
                continue
            value = line[pos+1:].strip()
            ipmi_dic[key] = value
    except:
        log.warning(ipmistr)

    return ipmi_dic
