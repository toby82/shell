#!mako|yaml
<%
import re
hostname2ip = salt['pillar.get']('mg_nw:hosts:present')
cc_node = pillar['iaas_role']['cc']
nc_node_re = pillar['iaas_role']['nc']
nc_node_list = []
pattern = re.compile(nc_node_re)
print "========================================"
for hostname, ip in hostname2ip.items():
  match = pattern.match(hostname)
  if match:
    nc_node_list.append(hostname)
    print hostname
nn_node_list = pillar['iaas_role']['nn'].split(",")
autodeploy_node = pillar['iaas_role']['autodeploy']
%>

base:
  '*':
    - hosts
    - os
    - network
% if autodeploy_node == grains['id']:
    - file_sync.file_sync 
% endif
% if cc_node == grains['id'] or autodeploy_node == grains['id']:
    - ntp.service
% endif
    - ntp.client
    - yum_repos
% if cc_node == grains['id']:
    - db.mysql
    - cml.server
    - cml.api
% endif
    - cml.agent
% if pillar['lun_info']['enable']      == True:
    - iscsid
    - multipath
% endif
% if pillar['ocfs2_cluster']['enable'] == True:
    - ocfs2
% endif
% if pillar['glusterfs']['enable']     == True:
    - glusterfs
% endif
% if autodeploy_node == grains['id']:
    - packstack.installed
% endif
