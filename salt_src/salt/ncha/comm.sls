#!jinja|mako|yaml
<%namespace name="util" file="salt://comm/util.mako" />
<%
service_ip_seg = util.get_pillar('ncha_info:serviceipseg', "169.254.254.0")
service_gateway = util.get_pillar('ncha_info:servicegateway', "169.254.254.1")
interval = util.get_pillar('ncha_info:interval', "120")
nova_backend = util.get_pillar('nova_info:backend',"glusterfs")
rbd_image_pool = util.get_pillar('nova_info:rbd_image_pool',"")
ram_alloc_ratio=util.get_pillar('nova_info:ram_alloc_ratio',"1.5")
cpu_alloc_ratio=util.get_pillar('nova_info:cpu_alloc_ratio',"16")
glusterfsreplica  = salt['pillar.get']('glusterfs:replica')
gluster_node = salt['pillar.get']('glusterfs:nodes')
gluster_server_node_hostnames=[]
for node_dic in gluster_node:
  for hostname, node_info in node_dic.items():
    if not node_info:
      continue
    if 'role' in node_info.keys() and node_info['role'] == 'server':
      gluster_server_node_hostnames.append(hostname)
gluster_server_hostnames = ','.join(gluster_server_node_hostnames)
if nova_backend == 'rbd':
    novapoolname = 'NOVAPOOLNAME=' + rbd_image_pool
    storagemode = nova_backend
else:
    storagemode = 'glusterfs'
    novapoolname = 'NOVAPOOLNAME='
%>
<%
import commands
id = salt['grains.get']('id')
mg_nw_hostname_ip = salt['pillar.get']('mg_nw:hosts:present')
for hostname,ip in mg_nw_hostname_ip.iteritems():
    if hostname == id:
        cmd = 'ip -o addr show | grep ' + ip + ' | awk \'{print $2}\''
        ifcfg = 'ifcfg-' + commands.getoutput(cmd)
        break
%>
ncha_conf:
  file.managed:
    - name: /etc/nova/ncha/ncha.conf
    - source: salt://ncha/template/ncha.conf
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - makedirs: True
    - defaults:
        SERVICEIPSEG:         ${service_ip_seg}
        SERVICEGETEWAY:       ${service_gateway}
        INTERVAL:             ${interval}
        GLUSTERFSREPLICA:     ${glusterfsreplica}
        GLUSTERFSIP:          ${gluster_server_hostnames}       
        RAM_ALLOC_RATIO:      ${ram_alloc_ratio}
        CPU_ALLOC_RATIO:      ${cpu_alloc_ratio}
        NOVAPOOLNAME:         ${novapoolname}
        STORAGEMODE:          ${storagemode}
/etc/nova/ncha/netconfig.conf:
  file.symlink:
    - target: /etc/sysconfig/network-scripts/${ifcfg}
    - force: True
rc.local:
  file.managed:
    - name: /etc/rc.d/rc.local
    - mode: 755 
/etc/rc.d/rc.local:
  file.append:
    - text:
consul:
  file.copy:
    - name: /usr/bin/consul
    - source: /opt/software/ncha/consul
    - force: True
run_consul:
  cmd.run: 
    - name:
nchacephtool:
  file.copy:
    - name: /usr/bin/nchacephtool
    - source: /opt/software/ncha/nchacephtool
    - force: True
