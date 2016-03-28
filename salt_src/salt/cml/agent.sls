#!mako|yaml
<%namespace name="util" file="salt://comm/util.mako" />
<%
cc_ip = util.get_pillar('iaas_role:cc', "")
db_host = util.get_pillar('cml_info:db_host', cc_ip)
cml_server = util.get_pillar('cml_info:cml_server', cc_ip)
%>  

agentcomm.installed:
  pkg.installed:
    - names: 
      - fabric
      - gcc
      - MySQL-python
      - mariadb
      - mariadb-devel

agent.installed:
  cmd.run:
    - names:
      - fab deploy -f /opt/software/cml/fabfile -c /opt/server/cml/cml-agent-config -H 127.0.0.1 -R cml-a > /opt/software/cml/deploy_cml_agent.log 
    - unless:
      - ls /opt/server/cml/cml_agent/sbin/zabbix_agentd
    - env:
      - HOME: /root
      - LANG: en_US.UTF-8
      - LC_ALL: en_US.UTF-8
    - require:
      - pkg: agentcomm.installed
      - file: agent.installed
  file.managed:
    - name: /opt/server/cml/cml-agent-config
    - source: salt://cml/template/cml-agent-config.template
    - template: jinja
    - makedirs: True
    - defaults:
      GLOBAL_DB_IP:             ${db_host}
      DB_NAME_CML:              ${util.get_pillar('cml_info:db_name', "cml")}
      DB_USER_CML:              ${util.get_pillar('cml_info:db_user', "cml")}
      DB_PASSWD_CML:            ${util.get_pillar('cml_info:db_pw', "huacloudhuacloud")}
      GLOBAL_DB_PORT:           3306
      GLOBAL_CML_SERVER_IP:     ${cml_server}    
  service.running:
    - name: zabbix_agentd
    - enable: True
    - require:
      - cmd: agent.installed

