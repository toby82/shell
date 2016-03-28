#!mako|yaml
<%namespace name="util" file="salt://comm/util.mako" />
<%
import re
hostname2ip = util.get_pillar('mg_nw:hosts:present', "")
cc_node = util.get_pillar('iaas_role:cc', "")
nc_nodes_re = util.get_pillar('iaas_role:nc', ".*nc|cc\S*\..*")
nn_nodes = util.get_pillar('iaas_role:nn', "")
nn_nodes = util.split_to_array(nn_nodes, ',', [cc_node])

autodeploy_node = util.get_pillar('iaas_role:autodeploy', cc_node)

vmware_nodes = util.get_pillar('iaas_role:vm_agent', "")
vmware_nodes = util.split_to_array(vmware_nodes, ',', [])

ironic_nodes = util.get_pillar('iaas_role:ironic_host', "")
ironic_nodes = util.split_to_array(ironic_nodes, ',', [])

cc_ip = hostname2ip[cc_node]
autodeploy_ip = hostname2ip[autodeploy_node]
ipvm_list = []
for node in vmware_nodes:
  ipvm_list.append(hostname2ip[node])

ipnc_list = ipvm_list
nc_ips = ','.join(ipnc_list)

ipnn_list = []
for node in nn_nodes:
  ipnn_list.append(hostname2ip[node])
nn_ips = ','.join(ipnn_list)


exclude_ips_from_grains = salt['grains.get']('exclude_ips', '')
exclude_ips = exclude_ips_from_grains
exclude_ips = util.split_to_array(exclude_ips, ',', [])
exclude_ips_set = set(exclude_ips)
exclude_ips_set.update(ipnc_list)
exclude_ips_set.update(ipnn_list)
if cc_ip in exclude_ips_set:
  exclude_ips_set.remove(cc_ip)

if "" in exclude_ips_set:
  exclude_ips_set.remove("")
exclude_ips = ','.join(exclude_ips_set)

devnet = util.get_pillar('neutron_info:pri_if', "eth1")
if devnet is None:
  br_mapping = ""
  br_ifaces = ""
else:
  br_mapping = "physnet1:br-" + devnet
  br_ifaces = "br-" + devnet + ":" + devnet
%>
<%
lvm_y_n = util.get_pillar('cinder_info:lvm_enable', "n")
size = util.get_pillar('cinder_info:lvm_volumes_size', "10G")
backend = util.get_pillar('cinder_info:backend', "gluster")
if lvm_y_n == 'y':
  cinder_backend = 'lvm' + ',' + backend + ',' + 'vmdk'
  volume_size = size
  print cinder_backend
elif lvm_y_n == 'n':
  cinder_backend = backend + ',' + 'vmdk'
  volume_size = "1G"
  print cinder_backend
%>

packstack.installed:
  pkg.installed:
    - pkgs:
      - openstack-packstack

iaas.installed:
  cmd.run:
    - name: packstack -d --answer-file /opt/server/iaas/answer.txt
    - env:
      - HOME: /root
      - LANG: en_US.UTF-8
      - LC_ALL: en_US.UTF-8
    - require:
      - pkg: packstack.installed
      - file: iaas.installed
  file.managed:
    - name: /opt/server/iaas/answer.txt
    - source: salt://packstack/template/answer.txt
    - template: jinja
    - makedirs: True
    - defaults:
      REPO_URL:              http://${autodeploy_ip}:81/pulsar2.0/Packages/
      CONTROLLER_HOST:       ${cc_ip}
      COMPUTE_HOSTS:         CONFIG_COMPUTE_HOSTS=${nc_ips}
      NETWORK_HOSTS:         CONFIG_NETWORK_HOSTS=${nn_ips}
      EXCLUDE_SERVERS:       EXCLUDE_SERVERS=${exclude_ips_from_grains}
      STORAGE_HOST:          ${cc_ip}
      MONGODB_HOST:          ${cc_ip}
      REDIS_MASTER_HOST:     ${cc_ip}
      AMQP_HOST:             ${cc_ip}
      MARIADB_HOST:          ${cc_ip}
      MARIADB_PW:            ${util.get_pillar('db_info:db_root_pw', "huacloudhuacloud")}
      KEYSTONE_DB_PW:        ${util.get_pillar('db_info:db_keystone_pw', "huacloudhuacloud")}
      IRONIC_DB_PW:          ${util.get_pillar('db_info:db_ironic_pw', "huacloudhuacloud")}
      NOVA_DB_PW:            ${util.get_pillar('db_info:db_nova_pw', "huacloudhuacloud")}
      GLANCE_DB_PW:          ${util.get_pillar('db_info:db_glance_pw', "huacloudhuacloud")}
      CINDER_DB_PW:          ${util.get_pillar('db_info:db_cinder_pw', "huacloudhuacloud")}
      NEUTRON_DB_PW:         ${util.get_pillar('db_info:db_neutron_pw', "huacloudhuacloud")}
      KEYSTONE_ADMIN_PW:     ${util.get_pillar('keystone_info:admin_password', "huacloudhuacloud")}
      KEYSTONE_ADMIN_TOKEN:  ${util.get_pillar('keystone_info:admin_tocken', "huacloudhuacloud")}
      NOVA_CPU_ALLOC_RATIO:  ${util.get_pillar('nova_info:cpu_alloc_ratio', "16.0")} 
      NOVA_RAM_ALLOC_RATIO:  ${util.get_pillar('nova_info:ram_alloc_ratio', "1.5")}
      CINDER_BACKEND:        CONFIG_CINDER_BACKEND=${cinder_backend}
      VOLUMES_SIZE:          CONFIG_CINDER_VOLUMES_SIZE=${volume_size}
      CINDER_GLUSTER_MOUNTS: CONFIG_CINDER_GLUSTER_MOUNTS=${util.get_pillar('cinder_info:gluster_mounts', "")}
      COMPUTE_PRIVIF:        CONFIG_NOVA_COMPUTE_PRIVIF=${util.get_pillar('neutron_info:pri_if', "eth1")}
      NETWORK_PRIVIF:        CONFIG_NOVA_NETWORK_PRIVIF=${util.get_pillar('neutron_info:pri_if', "eth1")}
      PUBIF:                 CONFIG_NOVA_NETWORK_PUBIF=${util.get_pillar('neutron_info:pub_if', "eth0")}
      PUBEXPORT:             CONFIG_NEUTRON_L3_EXT_PORT=${util.get_pillar('neutron_info:pub_if', "eth0")}
      BRIDGE_MAPPINGS:       CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=${br_mapping}
      BRIDGE_IFACES:         CONFIG_NEUTRON_OVS_BRIDGE_IFACES=${br_ifaces}
      IRONIC_INSTALL:        CONFIG_IRONIC_INSTALL=n
      ML2_MECHANISM_DRIVERS: openvswitch,vmware
      VMWARE_BACKEND:        CONFIG_VMWARE_BACKEND=y
      VCENTER_HOST:          CONFIG_VCENTER_HOST=${util.get_pillar('vmware_vcenter_info:vmware_host', "")}
      VCENTER_USER:          CONFIG_VCENTER_USER=${util.get_pillar('vmware_vcenter_info:vmware_user', "")}
      VCENTER_PASSWORD:      CONFIG_VCENTER_PASSWORD=${util.get_pillar('vmware_vcenter_info:vmware_password', "")}
      VCENTER_CLUSTER:       CONFIG_VCENTER_CLUSTER_NAME=${util.get_pillar('vmware_vcenter_info:vmware_cluster', "")}
  grains.present:
    - name: exclude_ips
    - value: ${exclude_ips}
    - require:
      - cmd: iaas.installed
