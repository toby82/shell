#!mako|yaml
<%
gluster_volume_list = salt['pillar.get']('glusterfs:volumes')
gluster_node = salt['pillar.get']('glusterfs:nodes')
gluster_server_node_hostnames=set()
for node_dic in gluster_node:
  for hostname, node_info in node_dic.items():
    if not node_info:
      continue
    if 'role' in node_info.keys() and node_info['role'] == 'server':
      gluster_server_node_hostnames.add(hostname)
%>
<%
num_cpus = salt['grains.get']('num_cpus')
mem_total = salt['grains.get']('mem_total')
cpuset_cpus = int(num_cpus / 2)
if mem_total > 30000:
    memory_limit = "16G"
else:
    memory_limit = str(mem_total / 2) + 'M'
print cpuset_cpus
print memory_limit
%>
% if grains['id'] in  gluster_server_node_hostnames:
  % for volume_dic in gluster_volume_list:
    % for volume, volume_info in volume_dic.items():
${volume_info['name']}_brick.created:
  file.directory:
    - name: ${volume_info['brick']}
    - makedirs: True
    % endfor
  % endfor 
% endif

vm.dirty_background_ratio:
  sysctl.present:
    - value: 1
    
vm.dirty_ratio:
  sysctl.present:
    - value: 1

vm.swappiness:
  sysctl.present:
    - value: 10

cgroup.installed:
  pkg.installed:
    - pkgs:
      - libcgroup-tools
  file.managed:
    - name: /etc/cgconfig.conf
    - source: salt://glusterfs/template/cgconfig.conf
    - template: jinja
    - defaults:
      memory_limit: ${memory_limit}
      cpuset_cpus: 0-${cpuset_cpus}
      cpuset_mems: 0
  service.running: 
    - name: cgconfig
    - enable: True
    - watch:
      - file: /etc/cgconfig.conf
    - require:
      - file: cgroup.installed
      - pkg: cgroup.installed

cgred.service:
  file.managed:
    - name: /etc/cgrules.conf
    - source: salt://glusterfs/template/cgrules.conf
  service.running:
    - name: cgred
    - enable: True
    - watch:
      - file: /etc/cgrules.conf
    - require:
      - file: cgred.service

glusterd.logrotate:
  file.managed:
    - name: /etc/logrotate.d/glusterd
    - source: salt://glusterfs/template/logrotate.d/glusterd

glusterfsd.logrotate:
  file.managed:
    - name: /etc/logrotate.d/glusterfsd
    - source: salt://glusterfs/template/logrotate.d/glusterfsd

glusterfs-fuse.logrotate:
  file.managed:
    - name: /etc/logrotate.d/glusterfs-fuse
    - source: salt://glusterfs/template/logrotate.d/glusterfs-fuse

glusterfs.installed:
  pkg.installed:
    - pkgs:
      - glusterfs: 3.6.4-1.el7
      - glusterfs-server: 3.6.4-1.el7
    - skip_verify: True

glusterfs.service:
  service.running:
    - name: glusterd
    - enable: True
    - require:
      - pkg: glusterfs.installed
      - service: cgroup.installed
      - service: cgred.service
      - file: glusterd.logrotate
      - file: glusterfsd.logrotate
      - file: glusterfs-fuse.logrotate
