#!jinja|mako|yaml
<%namespace name="util" file="salt://comm/util.mako" />
<%
import os
import commands
cc_name = util.get_pillar('iaas_role:cc', "")
mg_nw_hostname_dict = salt['pillar.get']('mg_nw:hosts:present')
for hostname,host_ip in mg_nw_hostname_dict.iteritems():
    if hostname == cc_name:
        cc_ip = host_ip       
vmware_vcenter_ip = util.get_pillar('vmware_vcenter_info:vmware_host', "")
vmware_vcenter_user = util.get_pillar('vmware_vcenter_info:vmware_user', "")
vmware_vcenter_pw = util.get_pillar('vmware_vcenter_info:vmware_password', "")
if os.path.isfile('/root/keystonerc_admin'):
    for line in open('/root/keystonerc_admin').readlines():
        line_list = line[7:].strip('\n').split('=')
        if line_list[0] == "OS_USERNAME":
            os_username = line_list[1]
        elif line_list[0] == "OS_TENANT_NAME":
            os_tenant_name = line_list[1]
        elif line_list[0] == "OS_PASSWORD":
            os_password = line_list[1]
        elif line_list[0] == "OS_AUTH_URL":
            os_auth_url = line_list[1]
else:
    print "file no exist"
    os_username = "admin"
    os_tenant_name = "admin"
    os_password = "admin"
tenant_id = commands.getoutput("bash /srv/salt/vmw2os/get_tenant_id.sh")   
%>

unzip_vmw2os:
  cmd.run:
    - name: tar -xvf /opt/software/other/vmw2os.tar.gz -C /opt/software/ 
    - unless: test -f /opt/software/vmw2os/vmw2os/init.sh
init_vmw2os:
  cmd.run:
    - name: bash /opt/software/vmw2os/vmw2os/init.sh
    - unless: cd /usr/local/vmw2os && vmw2os -l

vmw2os_conf:
  file.managed:
    - name: /usr/local/vmw2os/etc/vmw2os/vmw2os.conf
    - source: /srv/salt/vmw2os/template/vmw2os.conf
    - template: jinja
    - makedirs: True
    - defaults:
        CC_IP:                  ${cc_ip}
        USERNAME:               ${os_username}
        PASSWORD:               ${os_password}
        TENANT_NAME:            ${os_tenant_name}
        TENANT_ID:              ${tenant_id}
        VMWARE_VCENTER_IP:      ${vmware_vcenter_ip}
        VMWARE_VCENTER_USER:    ${vmware_vcenter_user}
        VMWARE_VCENTER_PW:      ${vmware_vcenter_pw}
        
vmw2os_db_create:
  cmd.run:
    - name: cd /usr/local/vmw2os && vmw2os db.db_create
    - require: 
        - cmd: init_vmw2os
vmw2os_table_create:
  cmd.run:
    - name: cd /usr/local/vmw2os && vmw2os db.table_create
    - require:
        - cmd: vmw2os_db_create
        
images_upload:
  cmd.run:
    - name: bash /srv/salt/vmw2os/images_upload.sh
