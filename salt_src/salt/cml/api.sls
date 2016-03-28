#!mako|yaml
<%namespace name="util" file="salt://comm/util.mako" />
<%
cc_ip = util.get_pillar('iaas_role:cc', "")
db_host = util.get_pillar('cml_info:db_host', cc_ip)
cml_server = util.get_pillar('cml_info:cml_server', cc_ip)
cml_pw = util.get_pillar('cml_info:db_pw', "huacloudhuacloud")
cml = util.get_pillar('cml_info:db_user', "cml")
cml_name = util.get_pillar('cml_info:db_name', "cml")
print '*' * 50
print cc_ip
%>

api.installed:
  cmd.run:
    - name: fab deploy -f /opt/software/cml/fabfile -c /opt/server/cml/cml-api-config -H 127.0.0.1 -R cml-api > /opt/software/cml/deploy_cml_api.log
    - unless:
      - ls /opt/server/cml/cml_api/tomcat6.0/bin/startup.sh
    - env:
      - HOME: /root
      - LANG: en_US.UTF-8
      - LC_ALL: en_US.UTF-8
    - require:
      - file: api.installed
  file.managed:
    - name: /opt/server/cml/cml-api-config
    - source: salt://cml/template/cml-api-config.template
    - template: jinja
    - makedirs: True
    - defaults:
      GLOBAL_DB_IP:             ${db_host}
      DB_NAME_CML:              ${util.get_pillar('cml_info:db_name',"cml")}
      DB_USER_CML:              ${util.get_pillar('cml_info:db_user',"cml")}
      DB_PASSWD_CML:            ${util.get_pillar('cml_info:db_pw',"huacloudhuacloud")}
      GLOBAL_DB_PORT:           3306
      GLOBAL_IAAS_PORTAL_IP:    ${cc_ip}
      GLOBAL_IAAS_PORTAL_PORT:  80
      GLOBAL_CC_IP:             ${cc_ip}
      GLOBAL_CML_SERVER_IP:     ${cml_server}
  service.running:
    - name: cml_api
    - enable: True
    - require:
      - cmd: api.installed
