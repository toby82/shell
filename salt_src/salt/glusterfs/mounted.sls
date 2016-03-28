#!mako|yaml
<%
mg_nw_hostname2ip = salt['pillar.get']('mg_nw:hosts:present')
gluster_network_hostname2ip = {}
network_flag = salt['pillar.get']('glusterfs:network',"mg_nw")
if network_flag == "mg_nw":
  gluster_network_hostname2ip = mg_nw_hostname2ip
else:
  storage_network_dic = salt['pillar.get'](network_flag)
  for hostname, nw_dic in storage_network_dic.items():
    gluster_network_hostname2ip[hostname] = nw_dic['ip']
    
nova_vol_name = salt['pillar.get']('glusterfs:volumes:nova:name',"nova-vol")
nova_mount_path = salt['pillar.get']('nova_info:nova_mnt_dir',"/var/lib/nova/instances")
glance_mount_path = salt['pillar.get']('glance_info:nova_mnt_dir',"/var/lib/glance/images")
glusterfs_node_list = salt['pillar.get']('glusterfs:nodes')
local_hostname = grains['id']
gluster_default_service_ip = ""
gluster_service_ip = ""
need_mount = False
for node in glusterfs_node_list:
  for hostname, node_info in node.items():
    if hostname == local_hostname:
      need_mount = True
      if "server" == node_info['role']:
        gluster_service_ip = gluster_network_hostname2ip[local_hostname]
    if "server" == node_info['role'] and gluster_default_service_ip == "":
      gluster_default_service_ip = gluster_network_hostname2ip[hostname]
if gluster_service_ip == "":
  gluster_service_ip = gluster_default_service_ip

%>
% if need_mount == True:
${nova_mount_path}:
  mount.mounted:
    - device: ${gluster_service_ip}:/${nova_vol_name}
    - fstype: glusterfs
    - mkmnt: True
    - persist: False

  file.append:
    - name: "/etc/fstab"
    - text: "${gluster_service_ip}:/${nova_vol_name}    ${nova_mount_path}    glusterfs    _netdev,defaults    0 0"

chmod_${nova_mount_path}:
  file.directory:
    - name: ${nova_mount_path}
    - mode: 777
    - makedirs: True

${glance_mount_path}:
  mount.mounted:
    - device: ${gluster_service_ip}:/${nova_vol_name}
    - fstype: glusterfs
    - mkmnt: True
    - persist: False

  file.append:
    - name: "/etc/fstab"
    - text: "${gluster_service_ip}:/${nova_vol_name}    ${glance_mount_path}    glusterfs    _netdev,defaults    0 0"

chmod_${glance_mount_path}:
  file.directory:
    - name: ${glance_mount_path}
    - mode: 777
    - makedirs: True

chmod_cinder_path:
  file.directory:
    - name: /var/lib/cinder
    - mode: 777
    - makedirs: True

% endif
