import salt.client
import salt.pillar
import salt.runner
import salt.runners.pillar
import pprint
import salt.output
import comm

def run():
    client = salt.client.LocalClient(__opts__['conf_file'])
    pillar_dic = comm.get_pillar(__opts__)
    cc_hostname = pillar_dic['iaas_role']['cc']
    vm_hostname = pillar_dic['iaas_role']['vm_agent']
    vm_hostname = vm_hostname.split(',')
    print vm_hostname
    vm_ip = pillar_dic['vmware_vcenter_info']['vmware_host']
    vm_username = pillar_dic['vmware_vcenter_info']['vmware_user']
    vm_password = pillar_dic['vmware_vcenter_info']['vmware_password']
    setcmd = 'openstack_config.set'
    conf = '/etc/ceilometer/ceilometer.conf'
    conn_str = 'mongodb://' + cc_hostname + ':27017/ceilometer'
    result_list = []
    for vm_host in vm_hostname:
        result = client.cmd(vm_host, [setcmd] * 7, [[conf, 'DEFAULT', 'hypervisor_inspector', 'vsphere'],
                                      [conf, 'vmware', 'api_retry_count', '10'],
                                      [conf, 'vmware', 'task_poll_interval', '0.5'],
                                      [conf, 'vmware', 'host_ip', vm_ip],
                                      [conf, 'vmware', 'host_password', vm_password],
                                      [conf, 'vmware', 'host_username', vm_username],
                                      [conf, 'database', 'connection', conn_str]])
        result_list.append(result)
    return result_list
    
def restart():
    client = salt.client.LocalClient(__opts__['conf_file'])
    pillar_dic = comm.get_pillar(__opts__)
    vm_hostname = pillar_dic['iaas_role']['vm_agent']
    restart_str = 'systemctl restart openstack-ceilometer-compute'
    re_list = []
    vm_hostname = vm_hostname.split(',')
    print vm_hostname
    for vm_host in vm_hostname:
        result = client.cmd(vm_host,'cmd.run',[restart_str])
        re_list.append(result)
    return re_list

