#!mako|yaml
<%namespace name="util" file="salt://comm/util.mako" />
<%
hostname2ip = util.get_pillar('mg_nw:hosts:present', "")
cc_node = util.get_pillar('iaas_role:cc', "")
cc_ip = hostname2ip[cc_node]
db_host = util.get_pillar('cml_info:db_host', cc_ip)
cml_server = util.get_pillar('cml_info:cml_server', cc_ip)
cml_pw = util.get_pillar('cml_info:db_pw', "huacloudhuacloud")
cml = util.get_pillar('cml_info:db_user', "cml")
cml_name = util.get_pillar('cml_info:db_name', "cml")
print '*' * 50
print cc_ip
%>
  
cml.installed:
  pkg.installed:
    - pkgs:
      - fabric
      - gcc
      - MySQL-python
      - mariadb
      - mariadb-devel
      - mariadb-galera-server
  service.running:
    - name: mariadb
    - enable: True
    - require:
      - pkg: cml.installed

      
db.created:
  mysql_database.present:
    - host: ${cc_ip}
    - name: ${cml_name}
    - character_set: "utf8"
    - collate: "utf8_general_ci"
    - connection_host: ${cc_ip}
    - connection_user: ${util.get_pillar('db_info:db_manager_user', 'manager')}
    - connection_pass: ${util.get_pillar('db_info:db_manager_pw', '1234QWER')}
    - connection_port: 3306
    - connection_charset: utf8

  mysql_user.present:
    - host: ${cc_ip}
    - name: ${cml}
    - password: ${cml_pw}
    - connection_host: ${cc_ip}
    - connection_user: ${util.get_pillar('db_info:db_manager_user', 'manager')}
    - connection_pass: ${util.get_pillar('db_info:db_manager_pw', '1234QWER')}
    - connection_port: 3306
    - connection_charset: utf8

  mysql_grants.present:
    - host: ${cc_ip}
    - grant: all privileges
    - database: "*.*"
    - user: ${cml}
    - connection_host: ${cc_ip}
    - connection_user: ${util.get_pillar('db_info:db_manager_user', 'manager')}
    - connection_pass: ${util.get_pillar('db_info:db_manager_pw', '1234QWER')}
    - connection_port: 3306
    - connection_charset: utf8      
      
            
server.installed:
  cmd.run:
    - name: fab deploy  -f /opt/software/cml/fabfile -c /opt/server/cml/cml-server-config -H 127.0.0.1 -R cml-s > /opt/software/cml/deploy_cml_server.log
    - unless:
      - ls /opt/server/cml/cml_server/sbin/zabbix_server
    - env:
      - HOME: /root
      - LANG: en_US.UTF-8
      - LC_ALL: en_US.UTF-8
    - require:
      - pkg: cml.installed
      - file: server.installed
      - mysql_database: db.created
  file.managed:
    - name: /opt/server/cml/cml-server-config
    - source: salt://cml/template/cml-server-config.template
    - template: jinja
    - makedirs: True
    - defaults:
      GLOBAL_DB_IP:             ${db_host}
      DB_NAME_CML:              ${util.get_pillar('cml_info:db_name',"cml")}
      DB_USER_CML:              ${util.get_pillar('cml_info:db_user',"cml")}
      DB_PASSWD_CML:            ${util.get_pillar('cml_info:db_pw',"huacloudhuacloud")}
      GLOBAL_DB_PORT:           3306
  service.running:
    - name: zabbix_server
    - enable: True
    - require:
      - cmd: server.installed 

