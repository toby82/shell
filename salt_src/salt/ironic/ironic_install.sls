ironic_install:
  pkg.installed:
    - pkgs:
      - openstack-ironic-api
      - openstack-ironic-conductor
      - python-ironicclient
      - openstack-nova-compute
      - openstack-neutron-openvswitch    
tftp_install:
  pkg.installed:
    - pkgs:
      - tftp-server
      - syslinux-tftpboot
xinetd_install:
  pkg.installed:
    - pkgs:
      - xinetd
ironic_log_dir:
  file.directory:
    - name: /var/log/ironic
    - mode: 777
    - makedirs: True
/datas/ironic:
  file.directory:
    - mode: 777
    - makedirs: True
/tftpboot:
  file.directory:
    - mode: 777
    - makedirs: True
/tftpboot/chain.c32:
  file.managed:
    - source: salt://ironic/template/chain.c32
/tftpboot/pxelinux.0:
  file.managed:
    - source: salt://ironic/template/pxelinux.0
/tftpboot/map-file:
  file.managed:
    - source: salt://ironic/template/map-file
/etc/xinetd.d/tftp:
  file.managed:
    - source: salt://ironic/template/tftp
    - require:
      - pkg: xinetd_install
#neutron_conf:
#  file.managed:      
#    - name: /etc/neutron/neutron.conf
#    - source: salt://ironic/template/neutron.conf
plugins_conf:
  file.managed:
    - name: /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini
    - source: salt://ironic/template/ovs_neutron_plugin.ini
    - require:
      - pkg: ironic_install

ironic_conf:
  file.managed:
    - name: /etc/ironic/ironic.conf
    - source: salt://ironic/template/ironic.conf
nova_conf:
  file.managed:
    - name: /etc/nova/nova.conf
    - source: salt://ironic/template/nova.conf
    
xinetd_run:
  service.running:
    - name: xinetd
    - enable: True
    - require:
      - file: /etc/xinetd.d/tftp
    
ironic_api:
  service.running: 
    - name: openstack-ironic-api
    - enable: True
    - watch:
      - file: /etc/ironic/ironic.conf
    - require:
      - file: ironic_conf
      - pkg: ironic_install
ironic_dbsync:
  cmd.run:
    - name: ironic-dbsync --config-file /etc/ironic/ironic.conf
    - require:
      - file: ironic_conf
ironic_conductor:
  service.running:
    - name: openstack-ironic-conductor
    - enable: True
    - watch: 
      - file: /etc/ironic/ironic.conf
    - require:
      - file: ironic_conf
      - pkg: ironic_install  
      - cmd: ironic_dbsync      
neutron-openvswitch-agent:
  service.running:
    - name: neutron-openvswitch-agent
    - enable: True
    - watch: 
      - file: /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini
    - require:
      - file: plugins_conf
      #- file: neutron_conf
ironic_compute:
  service.running:
    - name: openstack-nova-compute
    - enable: True
    - watch: 
      - file: /etc/nova/nova.conf
    - require:
      - file: nova_conf
      - pkg: ironic_install
  
      
      

