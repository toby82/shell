#!mako|yaml
<%namespace name="util" file="salt://comm/util.mako" />
<%
device = salt['grains.get']('mountdev')
hostname2ip = util.get_pillar('mg_nw:hosts:present', "")
cc_node = util.get_pillar('iaas_role:cc', "")
dockerhost = util.get_pillar('iaas_role:vmw_agent', cc_node)
%>
% if dockerhost != grains['id'] or dockerhost == cc_node:
docker_install:
  pkg.installed:
    - pkgs:
      - docker
docker_cfg:
  file.managed:
    - name: /etc/sysconfig/docker
    - source: salt://heat_docker/docker
docker:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - pkg: docker_install
      - file: docker_cfg
docker_load:
  docker.loaded:
    - name: centos:nova-compute
    - source: salt://heat_docker/centos-nova-compute.tar
    - require:
        - service: docker

% else:        

umount_datas:
  mount.unmounted:
    - name: /datas
    - device: ${device}
    - persist: True
docker_install:
  pkg.installed:
    - pkgs:
      - docker
docker_storage_conf:
  file.append:
    - name: /etc/sysconfig/docker-storage-setup
    - text: 
      - SETUP_LVM_THIN_POOL=yes
      - DATA_SIZE=80%FREE      
    - require:
      - pkg: docker_install      
del_lvdata_vol:
  cmd.script:
    - shell: /bin/bash
    - source: "salt://heat_docker/del_lvdata_vol.sh"
    - require:
      - mount: umount_datas
docker-storage-setup:
  cmd.run:
    - name: /usr/bin/docker-storage-setup
    - unless: lvs | egrep -q docker
    - require:
      - file: docker_storage_conf
      - cmd: del_lvdata_vol
docker_cfg:
  file.managed:
    - name: /etc/sysconfig/docker
    - source: salt://heat_docker/docker
docker:
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: docker_cfg
      - cmd: docker-storage-setup
docker_load:
  docker.loaded:
    - name: centos:nova-compute
    - source: salt://heat_docker/centos-nova-compute.tar
    - require:
        - service: docker
% endif

 
