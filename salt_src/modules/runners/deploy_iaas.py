# -*- coding: utf-8 -*-
import salt.client
import salt.pillar
import salt.runner
import salt.runners.pillar
import pprint
import salt.output
import comm
import re
import copy

####################
# README
# For debug comand:
#   /bin/rm /etc/salt/grains ; salt '*' saltutil.sync_all > /dev/null && salt-run deploy_iaas.deploy 
# For test answer_file:
#   salt '*' saltutil.sync_all > /dev/null && salt-run deploy_iaas.deploy test_answer_file=True
#
# 执行流程
#
# RDO_iaas_cc
#   run_deploy_iaas_module
#     use_packstack_deploying: master_caller("packstack.deploy_iaas")
#     set_dir_mode
#     do_other_processes
#       master_caller("ncha.cc_install")
#       master_caller("heat_docker.heat_docker_install")
#       master_caller("vmw2os.install")
#       upload_ironic_image
#     install_docker: localclient_run("heat_docker.docker_install")
#     
# RDO_iaas_kvm
#   run_deploy_iaas_module
#     use_packstack_deploying: master_caller("packstack.deploy_iaas")
#     set_dir_mode
#     do_other_processes
#       master_caller("ncha.nc_install")
#     install_docker: localclient_run("heat_docker.docker_install")
#     
# RDO_iaas_vmware
#     use_packstack_deploying: master_caller("packstack.deploy_iaas")
#     set_dir_mode
#     do_other_processes
#       ceilometer_modify: localclient_run("openstack_config.set")
#     install_docker: localclient_run("heat_docker.docker_install")
# 
# RDO_iaas_ironic
#     use_packstack_deploying: master_caller("packstack.deploy_iaas")
#     set_dir_mode
#     do_other_processes
#       None
#     install_docker: localclient_run("heat_docker.docker_install")
####################

def deploy(display_progress=True, test_answer_file=False):
    client = salt.client.LocalClient(__opts__['conf_file'])
    master_caller = salt.client.Caller()
    runner = salt.runner.RunnerClient(__opts__)
    pillar = comm.get_pillar(__opts__)
    deploy_result_list = []

    # the hostname of host node:
    hostname2ip  = comm.get_dic_value(pillar, 'mg_nw:hosts:present', {})
    cc_node      = comm.get_dic_value(pillar, 'iaas_role:cc', None)
    deploy_node  = comm.get_dic_value(pillar, 'iaas_role:autodeploy', cc_node)
    nn_nodes     = comm.split_with_comma( comm.get_dic_value(pillar, 'iaas_role:nn', cc_node) )
    ironic_nodes = []

    ironic_install = comm.get_dic_value(pillar, 'ironic_info:install', 'n')

    # compute_type_nodes
    cc_nodes_set = set([cc_node])
    if ironic_install == 'y':
        ironic_nodes = [cc_node]
    vmware_nodes = comm.split_with_comma( comm.get_dic_value(pillar, 'iaas_role:vm_agent', "") )
    vmware_nodes_set = set(vmware_nodes)
    docker_nodes = comm.split_with_comma( comm.get_dic_value(pillar, 'iaas_role:vmw_agent', "") )
    docker_nodes_set = set(docker_nodes)
    nc_nodes = []
    nc_nodes_re  = comm.get_dic_value(pillar, 'iaas_role:nc', ".*nc|cc\S*\..*")
    pattern = re.compile(nc_nodes_re)
    for node_hostname, ip in hostname2ip.items():
        match = pattern.match(node_hostname)
        if match:
            nc_nodes.append(node_hostname)
    nc_nodes_set = set(nc_nodes)
    grains_exclude_nodes = master_caller.function("grains.get", "exclude_nodes")
    if type(grains_exclude_nodes) is not list:
        grains_exclude_nodes = []
    grains_exclude_nodes_set = set(grains_exclude_nodes)
    exclude_nodes_set = copy.copy(grains_exclude_nodes_set)
    hostname2ip = comm.get_dic_value(pillar, 'mg_nw:hosts:present', "")

    glusterfs_server_node = []
    glusterfs_nodes = comm.get_dic_value(pillar, 'glusterfs:nodes', [])
    for node_dic in glusterfs_nodes:
        for hostname, node_info in node_dic.items():
            if not node_info:
                continue
            if 'role' in node_info and node_info['role'] == 'server':
                glusterfs_server_node.append(hostname)
    glusterfs_server_node_set = set(glusterfs_server_node)

    params={
        'hostname2ip': hostname2ip,
        'cc_node': cc_node,
        'deploy_node': deploy_node,
        'nn_nodes': nn_nodes,
        'exclude_nodes': list(exclude_nodes_set),
        'test_answer_file': test_answer_file,
    }

    if display_progress and not test_answer_file:
        __jid_event__.fire_event({'message': 'To prepare for deploying.'}, 'deploy_iaas')

    hosts_pillar_dic = client.cmd("*", "pillar.items")
    online_hosts_set = set(hosts_pillar_dic.keys())

    # deploy_iaas: cc
    hostname = cc_node
    if hostname in online_hosts_set and hostname not in grains_exclude_nodes_set:
        process= RDO_iaas_cc(client, master_caller, runner, hosts_pillar_dic[hostname], params)
        ret = process.run_deploy_iaas_module(hostname)
        deploy_result_list.append( 
            { hostname: ret } 
        )
        if len(ret) == 0:
            return deploy_result_list
        if not check_packstack_retcode_ok(ret):
            return deploy_result_list
    base_service_exclude_nodes_set = set( [cc_node] )
    base_service_exclude_nodes_set |= set( nn_nodes )

    # deploy_iaas: nc
    for hostname in nc_nodes:
        exclude_nodes_set = copy.copy(grains_exclude_nodes_set)
        base_service_exclude_nodes_set_clone = copy.copy(base_service_exclude_nodes_set)
        if hostname in online_hosts_set \
            and hostname not in grains_exclude_nodes_set \
            and hostname not in vmware_nodes_set:
            # nc节点上，docker和glulsterfs不可共存；而在cc节点上，docker和glulsterfs是可共存
            if hostname not in cc_nodes_set:
                # 对nc节点的docker和glulsterfs是共存的判断
                if hostname in docker_nodes_set:
                    continue

            if hostname in base_service_exclude_nodes_set_clone:
                base_service_exclude_nodes_set_clone.remove(hostname)
            exclude_nodes_set |= base_service_exclude_nodes_set_clone
            params['exclude_nodes'] = list(exclude_nodes_set)
            process= RDO_iaas_kvm(client, master_caller, runner, hosts_pillar_dic[hostname], params)
            ret = process.run_deploy_iaas_module(hostname)
            deploy_result_list.append( 
                { hostname: ret } 
            )

    # deploy_iass: vmware
    for hostname in vmware_nodes:
        exclude_nodes_set = copy.copy(grains_exclude_nodes_set)
        base_service_exclude_nodes_set_clone = copy.copy(base_service_exclude_nodes_set)
        # 因为 vmware agent 安装的时候，cc节点也需要更新，因此将CC节点从EXCLUDE名单中移除
        base_service_exclude_nodes_set_clone.remove(cc_node)
        if hostname in online_hosts_set \
            and hostname not in grains_exclude_nodes_set \
            and hostname not in docker_nodes_set:
            if hostname in base_service_exclude_nodes_set_clone:
                base_service_exclude_nodes_set_clone.remove(hostname)
            exclude_nodes_set |= base_service_exclude_nodes_set_clone
            params['exclude_nodes'] = list(exclude_nodes_set)
            process= RDO_iaas_vmware(client, master_caller, runner, hosts_pillar_dic[hostname], params)
            ret = process.run_deploy_iaas_module(hostname)
            deploy_result_list.append( 
                { hostname: ret } 
            )

    # deploy_iass: ironic
    for hostname in ironic_nodes:
        exclude_nodes_set = copy.copy(grains_exclude_nodes_set)
        base_service_exclude_nodes_set_clone = copy.copy(base_service_exclude_nodes_set)
        if hostname in online_hosts_set \
            and hostname not in grains_exclude_nodes_set: 
            if hostname in base_service_exclude_nodes_set_clone:
                base_service_exclude_nodes_set_clone.remove(hostname)
            exclude_nodes_set |= base_service_exclude_nodes_set_clone
            params['exclude_nodes'] = list(exclude_nodes_set)
            process= RDO_iaas_ironic(client, master_caller, runner, hosts_pillar_dic[hostname], params)
            ret = process.run_deploy_iaas_module(hostname)
            deploy_result_list.append( 
                { hostname: ret } 
            )
    
    # deploy_docker
    for hostname in docker_nodes:
        if hostname in online_hosts_set \
            and hostname not in vmware_nodes_set:
            # 只允许在cc节点上，docker和glulsterfs共存：此外的条件都不允许
            #if hostname not in glusterfs_server_node_set or (hostname in glusterfs_server_node_set and hostname in cc_nodes_set):
            deploy_task = "heat_docker.docker_install"
            ret = client.cmd(hostname, 'state.sls', [deploy_task])
            ret_hostname, ret_value = ret.items()[0]
            deploy_result_list.append(
                { ret_hostname: [ {deploy_task: ret_value}] }
            )

    # deal with host deployed successfully to grains_exclude_nodes_set
    for result in deploy_result_list:
        for hostname, ret in result.items():
            if len(ret) == 0:
                continue
            if check_packstack_retcode_ok(ret):
                grains_exclude_nodes_set.add(hostname)
    grains_exclude_nodes_set |= base_service_exclude_nodes_set
    if not test_answer_file:
        master_caller.function("grains.setval", "exclude_nodes", list(grains_exclude_nodes_set)) 

    if display_progress and not test_answer_file:
        __jid_event__.fire_event({'message': 'Finish deploying.'}, 'deploy_iaas')

    return deploy_result_list



def check_packstack_retcode_ok(ret):
    packstack_cmd_pattern = re.compile(r'.*packstack.+--answer-file.+')
    for ret_item in ret:
        for key in ret_item.keys():
            match = packstack_cmd_pattern.match(key)
            if match:
                packstack_run_status = ret_item[key]
                if 'retcode' not in packstack_run_status.keys() or packstack_run_status['retcode'] != 0:
                    return False
                else:
                    return True

class RDO_iaas(object):

    display_progress = True

    def __init__(self, client, master_caller, runner, pillar, defaults):
        self.client = client
        self.master_caller = master_caller
        self.runner = runner
        self.pillar = pillar
        self.defaults = defaults
        self.hostname2ip = defaults['hostname2ip']
        self.set_defaults_from_pillar()
        self.result = []
        self.hostname = ""
        self.test_answer_file = defaults['test_answer_file']

    def get_node_ip_str(self, nodes):
        nodes_list = []
        if nodes is None:
            return ""
        if type(nodes) is str and len(nodes.strip()) == 0:
            return ""
        if type(nodes) is not list:
            nodes_list = [nodes]
        else:
            nodes_list = nodes
        ip_list = []
        for hostname in nodes_list:
            if self.hostname2ip.has_key(hostname):
                host_ip = self.hostname2ip[hostname]
                ip_list.append(host_ip)
        return comm.join(ip_list)
    
    def localclient_run(self, module_name, cmd_params=[]):
        if type(cmd_params) is str:
            cmd_params = [cmd_params]
        tmp_ret = self.client.cmd(self.hostname, module_name, cmd_params)
        tmp_host, ret = tmp_ret.items()[0]
        return ret

    
    def set_defaults_from_pillar(self):
        self.defaults['REPO_URL']               = "http://%(autodeploy_ip)s:81/pulsar2.0/Packages/" %{'autodeploy_ip': self.get_node_ip_str(self.defaults['deploy_node'])}
        cc_ip_str                               = self.get_node_ip_str(self.defaults['cc_node'])
        self.defaults['CONTROLLER_HOST']        = cc_ip_str
        self.defaults['COMPUTE_HOSTS']          = 'CONFIG_COMPUTE_HOSTS='
        self.defaults['NETWORK_HOSTS']          = 'CONFIG_NETWORK_HOSTS=' + self.get_node_ip_str(self.defaults['nn_nodes'])
        exclude_nodes                           = comm.get_dic_value(self.defaults, 'exclude_nodes', "")
        exclude_nodes_str                       = self.get_node_ip_str(exclude_nodes)
        self.defaults['EXCLUDE_SERVERS']        = 'EXCLUDE_SERVERS=' + exclude_nodes_str
        self.defaults['STORAGE_HOST']           = cc_ip_str
        self.defaults['MONGODB_HOST']           = cc_ip_str 
        self.defaults['REDIS_MASTER_HOST']      = cc_ip_str
        self.defaults['AMQP_HOST']              = cc_ip_str    
        self.defaults['MARIADB_HOST']           = cc_ip_str
        self.defaults['MARIADB_PW']             = comm.get_dic_value(self.pillar, 'db_info:db_root_pw', "huacloudhuacloud")
        self.defaults['KEYSTONE_DB_PW']         = comm.get_dic_value(self.pillar, 'db_info:db_keystone_pw', "huacloudhuacloud")
        self.defaults['IRONIC_DB_PW']           = comm.get_dic_value(self.pillar, 'db_info:db_ironic_pw', "huacloudhuacloud")
        self.defaults['NOVA_DB_PW']             = comm.get_dic_value(self.pillar, 'db_info:db_nova_pw', "huacloudhuacloud")
        self.defaults['GLANCE_DB_PW']           = comm.get_dic_value(self.pillar, 'db_info:db_glance_pw', "huacloudhuacloud")
        self.defaults['CINDER_DB_PW']           = comm.get_dic_value(self.pillar, 'db_info:db_cinder_pw', "huacloudhuacloud")
        self.defaults['NEUTRON_DB_PW']          = comm.get_dic_value(self.pillar, 'db_info:db_neutron_pw', "huacloudhuacloud")
        self.defaults['KEYSTONE_ADMIN_PW']      = comm.get_dic_value(self.pillar, 'keystone_info:admin_password', "huacloudhuacloud")
        self.defaults['KEYSTONE_ADMIN_TOKEN']   = comm.get_dic_value(self.pillar, 'keystone_info:admin_tocken', "huacloudhuacloud")
        self.defaults['NOVA_CPU_ALLOC_RATIO']   = comm.get_dic_value(self.pillar, 'nova_info:cpu_alloc_ratio', "16.0")
        self.defaults['NOVA_RAM_ALLOC_RATIO']   = comm.get_dic_value(self.pillar, 'nova_info:ram_alloc_ratio', "1.5")

        cinder_backend_str = comm.get_dic_value(self.pillar, 'cinder_info:backend', "")
        cinder_backend_set = set(comm.split_with_comma(cinder_backend_str))
        if comm.get_dic_value(self.pillar, 'cinder_info:lvm_enable', "n") == 'y':
            cinder_backend_set.add('lvm')
        if 'rbd' in cinder_backend_set:
            cinder_backend_set.remove('rbd')
            cinder_backend_set.add('ceph')
        cinder_backend_str = comm.join(list(cinder_backend_set))
        self.defaults['CINDER_BACKEND']         = cinder_backend_str
        

        self.defaults['VOLUMES_SIZE']           = 'CONFIG_CINDER_VOLUMES_SIZE=' + comm.get_dic_value(self.pillar, 'cinder_info:lvm_volumes_size', "10G")
        self.defaults['CINDER_GLUSTER_MOUNTS']  = 'CONFIG_CINDER_GLUSTER_MOUNTS=' + comm.get_dic_value(self.pillar, 'cinder_info:gluster_mounts', "")
        # netinterface info
        network_privif                          = comm.get_dic_value(self.pillar, 'neutron_info:pri_if', "eth1")
        self.defaults['PUBEXPORT']              = 'CONFIG_NEUTRON_L3_EXT_PORT=' + comm.get_dic_value(self.pillar, 'neutron_info:pub_if', "eth0")
        br_mapping                              = "physnet1:br-" + network_privif
        br_ifaces                               = "br-" + network_privif + ":" + network_privif
        self.defaults['BRIDGE_MAPPINGS']        = 'CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=' + br_mapping
        self.defaults['BRIDGE_IFACES']          = 'CONFIG_NEUTRON_OVS_BRIDGE_IFACES=' + br_ifaces
        self.defaults['ML2_MECHANISM_DRIVERS']  = 'openvswitch'
        # ironic info
        self.defaults['IRONIC_INSTALL']         = 'CONFIG_IRONIC_INSTALL=n'
        # vmware info
        self.defaults['VMWARE_BACKEND']         = 'CONFIG_VMWARE_BACKEND=n'
        self.defaults['VCENTER_HOST']           = 'CONFIG_VCENTER_HOST='
        self.defaults['VCENTER_USER']           = 'CONFIG_VCENTER_USER='
        self.defaults['VCENTER_PASSWORD']       = 'CONFIG_VCENTER_PASSWORD='
        self.defaults['VCENTER_CLUSTER']        = 'CONFIG_VCENTER_CLUSTER_NAME='
        # ceph info
        self.defaults['RBD_USER']               = comm.get_dic_value(self.pillar, 'ceph_info:rbd_user', "")
        self.defaults['RBD_SECRET_UUID']        = comm.get_dic_value(self.pillar, 'ceph_info:rbd_secret_uuid', "")
        self.defaults['RBD_CEPH_CONF']          = comm.get_dic_value(self.pillar, 'ceph_info:ceph_conf_path', "/etc/ceph/ceph.conf")
        #  nova        
        self.defaults['NOVA_BACKEND']           = comm.get_dic_value(self.pillar, 'nova_info:backend', "none")
        self.defaults['NOVA_RBD_IMAGE_POOL']    = comm.get_dic_value(self.pillar, 'nova_info:rbd_image_pool', "images-vol")
        #  glance
        self.defaults['GLANCE_BACKEND']         = comm.get_dic_value(self.pillar, 'glance_info:backend', "")
        self.defaults['GLANCE_RBD_IMAGE_POOL']  = comm.get_dic_value(self.pillar, 'glance_info:rbd_image_pool', "images-vol")
        self.defaults['GLANCE_RBD_CHUNK_SIZE']  = comm.get_dic_value(self.pillar, 'glance_info:rbd_chunk_size', "8")
        self.defaults['GLANCE_SHOW_IMAGE_DIRECT_URL']     = comm.get_dic_value(self.pillar, 'glance_info:show_image_direct_url', "")
        #  cinder
        self.defaults['CINDER_RBD_IMAGE_POOL']            = comm.get_dic_value(self.pillar, 'cinder_info:rbd_image_pool', "volumes")
        self.defaults['CINDER_CEPH_GLANCE_API_VERSION']   = comm.get_dic_value(self.pillar, 'cinder_info:glance_api_version', "1")
        self.defaults['CINDER_RBD_MAX_CLONE_DEPTH']       = comm.get_dic_value(self.pillar, 'cinder_info:rbd_max_clone_path', "5")


    def run_deploy_iaas_module(self, hostname):
        self.hostname = hostname
        ip = self.hostname2ip[hostname]
        self.set_answer_file_path(hostname, ip)
        self.set_compute_hosts(ip)
        self.prepare(hostname, ip)
        if self.test_answer_file:
            result = self.master_caller.function("packstack.build_answer_file", self.defaults)
            self.result.append(result)
            return self.result
        if self.display_progress:
                __jid_event__.fire_event({'message': 'To deploy host ' + hostname + "."}, 'deploy_iaas')
        result = self.master_caller.function("packstack.deploy_iaas", self.defaults)
        self.result.append(result)
        self.set_dir_mode(hostname)
        self.do_other_processes(hostname)
        # 因 docker 容器将使用物理服务器节点的LV卷，因此不再每台物理服务器上部署该服务
        self.install_docker(hostname)
        return self.result
    
    def set_answer_file_path(self, hostname, ip):
        self.defaults['answer_file_path'] = '/opt/server/iaas/answerfile_%(role)s-%(hostname)s_%(ip)s.txt' %{'role': self.get_role(), 'hostname': hostname, 'ip':ip }

    def get_role(self):
        return 'none'

    def set_compute_hosts(self, ip):
        self.defaults['COMPUTE_HOSTS'] = "CONFIG_COMPUTE_HOSTS=" + ip
        
    def prepare(self, hostname, ip):
        # 处理ceph配置文件
        self.prepare_for_cephconf()
    
    def prepare_for_cephconf(self):
        rbd_param_set = set(comm.split_with_comma(self.defaults['NOVA_BACKEND']))
        rbd_param_set = rbd_param_set | set(comm.split_with_comma(self.defaults['GLANCE_BACKEND']))
        rbd_param_set = rbd_param_set | set(comm.split_with_comma(self.defaults['CINDER_BACKEND'])) 
        if 'ceph' in rbd_param_set:
            cmd = ['/etc/ceph/ceph.conf', 'jinja', 'salt://ceph/template/ceph.conf', None, '774']
            ret = self.localclient_run('comm.file_managed', cmd)
            self.result.append({"prepare for /etc/ceph/ceph.conf": ret})
    
    def set_dir_mode(self, hostname):
        cmd = 'chmod -R 0777 /var/lib/nova/instances'
        ret = self.localclient_run('cmd.run_all', cmd)
        self.result.append({cmd: ret})

        cmd = 'chmod -R 0777 /var/lib/glance'
        ret = self.localclient_run('cmd.run_all', cmd)
        self.result.append({cmd: ret})
 
    def install_docker(self, hostname):
        deploy_task = "heat_docker.docker_install"
        ret = self.localclient_run('state.sls', deploy_task)
        self.result.append({deploy_task: ret})

    def do_other_processes(self, hostname):
        pass


class RDO_iaas_cc(RDO_iaas):

    def __init__(self, client, master_caller, runner, pillar, defaults):
        super(RDO_iaas_cc, self).__init__(client, master_caller, runner, pillar, defaults)
    
    def set_compute_hosts(self, ip):
        self.defaults['COMPUTE_HOSTS'] = "CONFIG_COMPUTE_HOSTS="
        
    def get_role(self):
        return "cc"

    def set_dir_mode(self, hostname):
        super(RDO_iaas_cc, self).set_dir_mode(hostname)
        cmd = 'systemctl restart openstack-glance-api'
        ret = self.localclient_run('cmd.run_all', cmd)
        self.result.append({cmd: ret})

    def do_other_processes(self, hostname):
        # deploy NC-HA
        deploy_task = "ncha.cc_install"
        ret = self.master_caller.function("state.sls", deploy_task)
        self.result.append({deploy_task: ret})
        
        # deploy heat docker
        deploy_task = "heat_docker.heat_docker_install"
        ret = self.localclient_run("state.sls", deploy_task)
        self.result.append({deploy_task: ret})

        # deploy vmw2os
        deploy_task = "vmw2os.install"
        ret = self.localclient_run("state.sls", deploy_task)
        self.result.append({deploy_task: ret})
        
        # upload ironic image
        ironic_host_str = comm.get_dic_value(self.pillar, 'ironic_info:install', "")
        if ironic_host_str == 'y' :
            cmd = '/opt/software/other/uploadironic.sh all /opt/software/ironic_images 1'
            ret = self.localclient_run('cmd.run_all', cmd)
            self.result.append({cmd: ret})
        
        # create vmdk cinder type
        pattern = re.compile(r'^(cc|nc|nn|autodeploy)\S*\..+')
        vmw_host_str = comm.get_dic_value(self.pillar, 'iaas_role:vmw_agent', "")
        match = pattern.search(vmw_host_str)
        if match:
            cmd = 'bash /srv/salt/heat_docker/cinder_type.sh'
            ret = self.localclient_run('cmd.run_all', cmd)
            self.result.append({cmd: ret})
        # update admin tenant quota
        cmd = 'bash /srv/salt/other/modify_quota.sh'
        ret = self.localclient_run('cmd.run_all', cmd)
        self.result.append({cmd: ret})
     

class RDO_iaas_kvm(RDO_iaas):
    
    def __init__(self, client, master_caller, runner, pillar, defaults):
        super(RDO_iaas_kvm, self).__init__(client, master_caller, runner, pillar, defaults)

    def get_role(self):
        return "kvm"

    def do_other_processes(self, hostname):
        # deploy NC-HA
        deploy_task = "ncha.nc_install"
        ret = self.localclient_run('state.sls', deploy_task)
        self.result.append({deploy_task: ret}) 


class RDO_iaas_vmware(RDO_iaas):

    def __init__(self, client, master_caller, runner, pillar, defaults):
        super(RDO_iaas_vmware, self).__init__(client, master_caller, runner, pillar, defaults)

    def set_defaults_from_pillar(self):
        super(RDO_iaas_vmware, self).set_defaults_from_pillar()
        lvm_enable_str = comm.get_dic_value(self.pillar, 'cinder_info:lvm_enable', "n")
        self.defaults['CINDER_BACKEND']         = comm.join_str(self.defaults['CINDER_BACKEND'], "vmdk" )
        self.defaults['ML2_MECHANISM_DRIVERS']  = 'openvswitch,vmware'
        self.defaults['VMWARE_BACKEND']         = 'CONFIG_VMWARE_BACKEND=y'
        self.defaults['VCENTER_HOST']           = 'CONFIG_VCENTER_HOST=' + comm.get_dic_value(self.pillar, 'vmware_vcenter_info:vmware_host', "")
        self.defaults['VCENTER_USER']           = 'CONFIG_VCENTER_USER=' + comm.get_dic_value(self.pillar, 'vmware_vcenter_info:vmware_user', "")
        self.defaults['VCENTER_PASSWORD']       = 'CONFIG_VCENTER_PASSWORD=' + comm.get_dic_value(self.pillar, 'vmware_vcenter_info:vmware_password', "")
        self.defaults['VCENTER_CLUSTER']        = 'CONFIG_VCENTER_CLUSTER_NAME=' + comm.get_dic_value(self.pillar, "vmware_vcenter_info:vmware_cluster", "")

    def get_role(self):
        return "vmware"

    def do_other_processes(self, hostname):
        self.do_ceilometer_modify(hostname)

    def do_ceilometer_modify(self, hostname):
        # For ceilometer_modify
        deploy_task = "ceilometer_modify"
        cc_hostname = self.get_node_ip_str(self.defaults['cc_node'])
        vm_ip = comm.get_dic_value(self.pillar, 'vmware_vcenter_info:vmware_host', "")
        vm_username = comm.get_dic_value(self.pillar, 'vmware_vcenter_info:vmware_user', "")
        vm_password = comm.get_dic_value(self.pillar, 'vmware_vcenter_info:vmware_password', "")
        setcmd = 'openstack_config.set'
        ceilometer_conf = '/etc/ceilometer/ceilometer.conf'
        mongodb_conn_str = 'mongodb://' + cc_hostname + ':27017/ceilometer'
        
        params = [[ceilometer_conf, 'DEFAULT',  'hypervisor_inspector', 'vsphere'],
                  [ceilometer_conf, 'vmware',   'api_retry_count',      '10'],
                  [ceilometer_conf, 'vmware',   'task_poll_interval',   '0.5'],
                  [ceilometer_conf, 'vmware',   'host_ip',              vm_ip],
                  [ceilometer_conf, 'vmware',   'host_password',        vm_password],
                  [ceilometer_conf, 'vmware',   'host_username',        vm_username],
                  [ceilometer_conf, 'database', 'connection',           mongodb_conn_str]
                 ]
        ret = self.localclient_run( [setcmd]*7, params)
        self.result.append({deploy_task: ret})
        
        cmd = "systemctl restart openstack-ceilometer-compute"
        ret = self.localclient_run('cmd.run_all', cmd)
        self.result.append({cmd: ret})
        

class RDO_iaas_ironic(RDO_iaas):

    def __init__(self, client, master_caller, runner, pillar, defaults):
        super(RDO_iaas_ironic, self).__init__(client, master_caller, runner, pillar, defaults)

    def set_defaults_from_pillar(self):
        super(RDO_iaas_ironic, self).set_defaults_from_pillar()
        self.defaults['IRONIC_INSTALL']         = 'CONFIG_IRONIC_INSTALL=y'

    def get_role(self):
        return "ironic"


