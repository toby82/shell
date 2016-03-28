#!mako|yaml
<%namespace name="util" file="salt://comm/util.mako" />
<%
hostname2ip = util.get_pillar('mg_nw:hosts:present', "")
cc_node = util.get_pillar('iaas_role:cc', "")
cc_ip = hostname2ip[cc_node]
autodeploy = util.get_pillar('iaas_role:autodeploy', cc_node)
%>
% if autodeploy != cc_node:
software_sync:
  cmd.run:
    - names: 
      - rsync -av /opt/software ${cc_ip}:/opt/
      - rsync -av /srv/* ${cc_ip}:/srv/
docker_images_unzip:
  cmd.run:
    - name: tar -xvf /opt/software/docker_images/centos-nova-compute.tar.gz -C /srv/salt/heat_docker/
    - unless: ls /srv/salt/heat_docker/centos-nova-compute.tar
% endif