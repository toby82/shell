#!mako|yaml
<%namespace name="util" file="salt://comm/util.mako" />
<%
dockerhost_hostname2ip = salt['pillar.get']('mg_nw:hosts:present')
cc_node = util.get_pillar('iaas_role:cc', "")
dockerhost = util.get_pillar('iaas_role:dockerhost', cc_node)
dockerhostip = dockerhost_hostname2ip[dockerhost]
%>
ironic:
  keystone.user_present:
    - password: 'ironic'
    - email: ironic@chinacloud.com
    - profile: ironic
    - tenant: services
    - roles:
        services:
          - admin
ironic_service:
  keystone.service_present:
    - name: ironic
    - profile: ironic
    - service_type: baremetal
    - description: Ironic bare metal provisioning service
ironic_endpoint:
  keystone.endpoint_present:
    - name: ironic
    - profile: ironic
    - publicurl: 'http://${dockerhostip}:6385'
    - internalurl: 'http://${dockerhostip}:6385'
    - adminurl: 'http://${dockerhostip}:6385'
    - region: RegionOne
    - require:
        - keystone: ironic_service