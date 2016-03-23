#!/usr/bin/python
import yaml
import sys
import re
import os
import salt.client
try:
    config = yaml.load(file('/srv/pillar/config.sls', 'r'))
except yaml.YAMLError, exc:
    print "Error in config configuration file:", exc
try:
    top = yaml.load(file('/srv/pillar/top.sls', 'r'))
except yaml.YAMLError, exc:
    print "Error in top.sls configuration file:", exc
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
    online_hostnameip = dict(local.cmd('*','grains.get',['ip_interfaces:eth0']))
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
def set_st_nw():
    if config['storage_network']:
        for host in config['st_nw'].keys():
            if host not in get_allhostnameip().keys():
                print "Please check config.sls [st_nw]...hostname"
                sys.exit(1)
    else:
        del config['st_nw']
               
def gluster_server_hostname():
    for host in config['glusterfs']['nodes']:
        if 'server' in host.values()[0].values():
            return host.keys()[0]
def gluster_server_mg_nw():
    return get_allhostnameip()[gluster_server_hostname()]
def st_nw_info():
    return config['st_nw'][gluster_server_hostname()]
def gluster_st_ip():
    return st_nw_info()['ip']
def get_st_type():
    if config['storage_type'] in ['local','gluster','ceph','ocfs2']:
        return config['storage_type']
def get_allinone_hypervisor():
    try:
        allinone_hypervisor = []
        allinone_hypervisor = config['allinone_hypervisor'].split(',')
    except:
        print "Please check [allinone_hypervisor]"
        sys.exit(1)
    return allinone_hypervisor

def set_storage_type():
    if config['storage_type'] in ['local','gluster','ceph','ocfs2']:
        if config['storage_type'] == 'local':
            print config['storage_type'] + ' storage'
            config['storage_type'] = 'local'
            del config['cinder_info']['gluster_mounts']
            del config['nova_info']
            del config['glance_info']
            config['glusterfs']['enable'] = False
            config['cinder_info']['backend'] = 'lvm'
            config['cinder_info']['lvm_enable'] = 'y'
            try:
                lv_size = config['cinder_info']['lvm_volumes_size']
                m = re.search(r'[^0]\d+G', lv_size)
            except:
                print "Please check lvm_volumes_size."
                sys.exit(1)
            if m:
                pass
            else:
                config['cinder_info']['lvm_volumes_size'] = get_ccdisk()
        
        elif config['storage_type'] == 'gluster':
            print config['storage_type'] + ' storage'
            del config['nova_info']
            del config['glance_info']
            config['storage_type'] = 'gluster'
            config['glusterfs']['enable'] = True
            config['cinder_info']['backend'] = 'gluster'
            config['cinder_info']['lvm_enable'] = 'n'
            try:
                if config['storage_network']:
                    config['cinder_info']['gluster_mounts'] = gluster_st_ip() + '/cinder-vol'
                else:
                    config['cinder_info']['gluster_mounts'] = gluster_server_mg_nw() + '/cinder-vol'
            except:
                print "Please check config.sls [glusterfs]"
                sys.exit(1)
        elif config['storage_type'] == 'ceph':
            print config['storage_type'] + ' storage'
            config['storage_type'] = 'ceph'
            config['nova_info'] = {'backend':'rbd','rbd_image_pool':'images-vol'}       
            config['glance_info'] = {'backend':'rbd',
                                    'rbd_image_pool':'images-vol',
                                    'rbd_chunk_size':8}
            config['glusterfs']['enable'] = False
            config['cinder_info'] = {'backend':'rbd',
                                    'rbd_image_pool':'volumes',
                                    'rbd_max_clone_path':5,
                                    'lvm_enable':'n'}
        elif config['storage_type'] == 'ocfs2':
            if config['lun_info']['enable'] == False or config['ocfs2_cluster']['enable'] == False:
                print "Please check config.sls [lun_info] and [ocfs2_cluster]"
                sys.exit(1)
            print config['storage_type'] + ' storage'
            del config['nova_info']
            del config['glance_info']
            config['storage_type'] = 'ocfs2'
            config['glusterfs']['enable'] = False
            config['cinder_info'] = {'ocfs2_mounts':'/var/lib/cinder/ocfs2-volumes',
                                    'backend':'ocfs2',
                                    'lvm_enable':'n'}
            
    else:
        print "Please check storage type in config.sls:[local,gluster,ceph,ocfs2]"
        sys.exit(1)
        
#main    
if config['allinone_enable']:
    get_set = set(get_allinone_hypervisor())
    all_set = set(['kvm','vmware','ironic'])
    if get_set.issubset(all_set) and get_set != set(['kvm','ironic']) or get_set != set(['kvm','vmware','ironic']):    
        if set(get_allinone_hypervisor()) == set(['kvm']):
            print "running allinone env..."
            print "hypervisor kvm..."
            del config['iaas_role']['vmw_agent']
            config['mg_nw']['hosts']['present'] = get_allhostnameip()
            config['iaas_role']['autodeploy'] = get_cchostname()
            config['iaas_role']['cc'] = get_cchostname()
            config['iaas_role']['nn'] = get_cchostname()
            config['iaas_role']['nc'] = '.*nc|cc\S*\..*'
            config['ironic_info']['install'] = 'n'
        elif set(get_allinone_hypervisor()) == set(['vmware']):
            print "running allinone env..."
            print "hypervisor vmware..."
            config['mg_nw']['hosts']['present'] = get_allhostnameip()
            config['iaas_role']['autodeploy'] = get_cchostname()
            config['iaas_role']['cc'] = get_cchostname()
            config['iaas_role']['nn'] = get_cchostname()
            config['iaas_role']['nc'] = '.*nc\S*\..*'
            config['ironic_info']['install'] = 'n'
            config['iaas_role']['vmw_agent'] = get_cchostname()
        elif set(get_allinone_hypervisor()) == set(['ironic']):
            print "running allinone env..."
            print "hypervisor ironic..."
            del config['iaas_role']['vmw_agent']
            config['mg_nw']['hosts']['present'] = get_allhostnameip()
            config['iaas_role']['autodeploy'] = get_cchostname()
            config['iaas_role']['cc'] = get_cchostname()
            config['iaas_role']['nn'] = get_cchostname()
            config['iaas_role']['nc'] = '.*nc\S*\..*'
            config['ironic_info']['install'] = 'y'
        elif set(get_allinone_hypervisor()) == set(['kvm','vmware']):
            print "running allinone env..."
            print "hypervisor kvm,vmware..."
            config['iaas_role']['vmw_agent'] = get_cchostname()
            config['mg_nw']['hosts']['present'] = get_allhostnameip()
            config['iaas_role']['autodeploy'] = get_cchostname()
            config['iaas_role']['cc'] = get_cchostname()
            config['iaas_role']['nn'] = get_cchostname()
            config['iaas_role']['nc'] = '.*nc|cc\S*\..*'
            config['ironic_info']['install'] = 'n'
        elif set(get_allinone_hypervisor()) == set(['vmware','ironic']):
            print "running allinone env..."
            print "hypervisor vmware,ironic..."
            config['mg_nw']['hosts']['present'] = get_allhostnameip()
            config['iaas_role']['autodeploy'] = get_cchostname()
            config['iaas_role']['cc'] = get_cchostname()
            config['iaas_role']['nn'] = get_cchostname()
            config['iaas_role']['nc'] = '.*nc\S*\..*'
            config['ironic_info']['install'] = 'y'
            config['iaas_role']['vmw_agent'] = get_cchostname()
        else:
            print "Please check hypervisor allinone_hypervisor in config.sls:[kvm,vmware,ironic]"
            sys.exit(1)
    else:
        print "Please check hypervisor allinone_hypervisor in config.sls:[kvm,vmware,ironic]"
        sys.exit(1)
    if get_st_type() in ['local','gluster']:
        set_storage_type()
        if get_st_type() == 'gluster':             
            gluster_server = {}
            gluster_server_list = []
            gluster_server[get_cchostname()] = {'role': 'server'}
            gluster_server_list.append(gluster_server)
            config['glusterfs']['nodes'] = gluster_server_list
        set_st_nw()
    else:
        print "allinone env storage_type in ['local','gluster']"
        sys.exit(1)
else:
    print "running multi node env..."
    try:
        hypervisor_type = config['multi_node_hypervisor'].split(',')
    except:
        print "Please check multi_node_hypervisor in config.sls:  kvm,vmware,ironic"
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
    set_storage_type()
    set_st_nw()
if config['allinone_enable']:
    st_type = config['storage_type']
    hy_type = '_'.join(get_allinone_hypervisor())
    file_name = '/srv/pillar/' + 'allinone_' + hy_type + '_' + st_type + '.sls'
    out_config = file(file_name,'w')
    yaml.dump(config,out_config,default_flow_style=False)
    if os.path.isfile(file_name):
        conf = []
        conf.append(os.path.basename(file_name).split('.')[0])
        conf.append('custom')
        top['base']['*'] = conf
        out_config = file('/tmp/tmpfile','w')
        yaml.dump(top,out_config,default_flow_style=False)
        os.rename('/tmp/tmpfile','/srv/pillar/top.sls')
else:
    multi_node_hy_type = config['multi_node_hypervisor'].split(',')
    multi_node_hy_type = '_'.join(multi_node_hy_type)
    st_type = config['storage_type']
    file_name = '/srv/pillar/' + 'multi_' + multi_node_hy_type + '_' + st_type + '.sls'
    out_config = file(file_name,'w')
    yaml.dump(config,out_config,default_flow_style=False) 
    if os.path.isfile(file_name):
        conf = []
        conf.append(os.path.basename(file_name).split('.')[0])
        conf.append('custom')
        top['base']['*'] = conf
        out_config = file('/tmp/tmpfile','w')
        yaml.dump(top,out_config,default_flow_style=False)
        os.rename('/tmp/tmpfile','/srv/pillar/top.sls')

    
