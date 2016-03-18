#!/usr/bin/python
import yaml
import sys
import re
import salt.client
try:
    config = yaml.load(file('config.sls', 'r'))
except yaml.YAMLError, exc:
    print "Error in config configuration file:", exc
def get_allnode():
    local = salt.client.LocalClient()
    online_host = dict(local.cmd('*','test.ping'))
    allnode = {}
    for k,v in online_host.items():
        if v == True:
            allnode[k] = online_host[k]
        else:
            continue
    return allnode  
def get_allhostnameip():
    local = salt.client.LocalClient()
    online_hostnameip = dict(local.cmd('*','grains.get',['fqdn_ip4']))
    hostnameip = {}
    for k,v in online_hostnameip.items():
        hostnameip[k] = v[0]
    return hostnameip     
def get_cchostname():
    local = salt.client.LocalClient()
    online_host = dict(local.cmd('*','test.ping'))
    for cchostname,cchostip in online_host.items():
        match = re.search(r'^cc\d*\.\S+', cchostname)
        if match:
            return cchostname
def get_ncnode():
    local = salt.client.LocalClient()
    online_host = dict(local.cmd('*','test.ping'))
    ncnode = []
    for nc,ncip in online_host.items():
        match = re.search(r'^nc\d*\.\S+', nc)
        if match:
            ncnode.append(nc)
    return ncnode
def get_nodecount():
    local = salt.client.LocalClient()
    online_host = dict(local.cmd('*','test.ping'))
    count = 0
    for k,v in online_host.items():
        if v == True:
            count += 1
        else:
            continue
    return count
def get_ccdisk():
    local = salt.client.LocalClient()
    disk = dict(local.cmd(get_cchostname(),'status.diskusage',['/datas']))
    disk_available = int(disk[get_cchostname()]['/datas']['available']/1024/1024/1024*0.8)
    return str(disk_available) + 'G'
    
#´æ´¢Ñ¡Ôñ
def get_storage_type():
    if config['storage_type'] in ['local','gluster','ceph','ocfs2']:
        if config['storage_type'] == 'local':
            print 'storage ' + config['storage_type']
            config['storage_type'] = 'local'
            del config['cinder_info']['gluster_mounts']
            del config['nova_info']
            del config['glance_info']
            config['glusterfs']['enable'] = False
            config['cinder_info']['backend'] = 'lvm'
            config['cinder_info']['lvm_enable'] = 'y'
            lv_size = config['cinder_info']['lvm_volumes_size']
            m = re.search(r'^\d+G', lv_size)
            if m:
                pass
            else:
                config['cinder_info']['lvm_volumes_size'] = get_ccdisk()
        
        elif config['storage_type'] == 'gluster':
            print 'storage ' + config['storage_type']
        elif config['storage_type'] == 'ceph':
            print 'storage ' + config['storage_type']
        elif config['storage_type'] == 'ceph':
            print 'storage ' + config['storage_type']
    else:
        print "Please check storage type in config.sls:[local,gluster,ceph,ocfs2]"
        sys.exit(1)
        
#main    
if config['allinone_enable']:
    if config['allinone_type'] == 'kvm':
        print "running allinone env..."
        print "hypervisor kvm..."
        del config['cinder_info']['gluster_mounts']
        del config['nova_info']
        del config['glance_info']
        del config['iaas_role']['vmw_agent']
        del config['st_nw']
        config['iaas_role']['autodeploy'] = get_cchostname()
        config['iaas_role']['cc'] = get_cchostname()
        config['iaas_role']['nn'] = get_cchostname()
        config['iaas_role']['nc'] = '.*nc|cc\S*\..*'
        config['ironic_info']['install'] = 'n'
    elif config['allinone_type'] == 'vmware':
        print "running allinone env..."
        print "hypervisor vmware..."
        del config['cinder_info']['gluster_mounts']
        del config['nova_info']
        del config['glance_info']
        del config['iaas_role']['vmw_agent']
        del config['st_nw']
    elif config['allinone_type'] == 'ironic':
        print "running allinone env..."
        print "hypervisor ironic..."
        del config['cinder_info']['gluster_mounts']
        del config['nova_info']
        del config['glance_info']
        del config['iaas_role']['vmw_agent']
        del config['st_nw']
    else:
        print "Please check hypervisor allinone_type in config.sls:[kvm,vmware,ironic]"
        sys.exit(1)       
else:
    print "running multi node env..."
    try:
        hypervisor_type = config['multi_node_type'].split(',')
    except:
        print "Please check hypervisor multi_node_type in config.sls:  kvm,vmware,ironic"
        sys.exit(1)
    if 'kvm' in hypervisor_type:
        config['mg_nw']['hosts']['present'] = get_allhostnameip()
        config['iaas_role']['nc'] = '.*nc\S*\..*'
        config['iaas_role']['autodeploy'] = get_cchostname()
        config['iaas_role']['cc'] = get_cchostname()
        config['iaas_role']['nn'] = get_cchostname()
    if 'vmware' in hypervisor_type:
        if len(get_ncnode()) >= 1:
            config['iaas_role']['vmw_agent'] = get_ncnode()[-1]
    if 'ironic' in hypervisor_type:
        config['ironic_info']['install'] = 'y'
    if config['storage_network']:
        pass
    else:
        del config['st_nw']

print '#' * 50
for k in config.keys():
    if k == 'glusterfs':
        print config[k]
    
out_config = file('config.sls.yaml','w')
yaml.dump(config,out_config,default_flow_style=False)   
sys.exit(0)