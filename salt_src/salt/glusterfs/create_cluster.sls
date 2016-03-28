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

gluster_all_node = []
gluster_server_node = []
gluster_node = salt['pillar.get']('glusterfs:nodes')
for node_dic in gluster_node:
  for hostname, node_info in node_dic.items():
    gluster_all_node.append(gluster_network_hostname2ip[hostname])
    if not node_info:
      continue
    role = "server"
    if 'role' in node_info.keys() == False:
      continue
    if node_info['role'] == 'server':
      gluster_server_node.append(gluster_network_hostname2ip[hostname])

gluster_volume_list = salt['pillar.get']('glusterfs:volumes')

%>
peer-clusters:
  glusterfs.peered:
    - names:
% for host in gluster_all_node:
      - ${host}
% endfor

  cmd.run:
    - name: "sleep 5"

% for volume_dic in gluster_volume_list:
  % for volume, volume_info in volume_dic.items():
${volume}_volume.created:
  glusterfs.created:
    - name: ${volume_info['name']}
    - bricks: 
    % for host in gluster_server_node:
      - ${host}:${volume_info['brick']}
    % endfor
    - replica: ${pillar['glusterfs']['replica']}
    - stripe: False
    - start: False
    - require:
      - cmd : peer-clusters

  cmd.run:
    - names:
    % for optimized_value in pillar['glusterfs']['cluster_optimize_params']:
      - gluster volume set ${volume_info['name']} ${optimized_value}
    % endfor
    - require:
      - glusterfs: ${volume}_volume.created
  % endfor
% endfor

% for volume_dic in gluster_volume_list:
  % for volume, volume_info in volume_dic.items():
${volume}_volume.started:
  glusterfs.started:
    - name: ${volume_info['name']}
    - require:
      - cmd: ${volume}_volume.created
  % endfor
% endfor
