#!mako|yaml
<%namespace name="util" file="salt://comm/util.mako" />
<%
hostname2ip = util.get_pillar('mg_nw:hosts:present', "")
cc_node = util.get_pillar('iaas_role:cc', "")
cc_ip = hostname2ip[cc_node]
%>
db.created:
  mysql_database.present:
    - host: ${cc_ip}
    - name: ironic
    - character_set: "utf8"
    - collate: "utf8_general_ci"
    - connection_host: ${cc_ip}
    - connection_port: 3306
    - connection_user: ${util.get_pillar('db_info:db_manager_user', 'manager')}
    - connection_pass: ${util.get_pillar('db_info:db_manager_pw', '1234QWER')}
    - connection_charset: utf8

  mysql_user.present:
    - host: '%'
    - name: ironic
    - password: huacloudhuacloud
    - connection_host: ${cc_ip}
    - connection_port: 3306
    - connection_user: ${util.get_pillar('db_info:db_manager_user', 'manager')}
    - connection_pass: ${util.get_pillar('db_info:db_manager_pw', '1234QWER')}
    - connection_charset: utf8

  mysql_grants.present:
    - host: '%'
    - grant: all privileges
    - database: ironic.*
    - user: ironic
    - connection_host: ${cc_ip}
    - connection_port: 3306
    - connection_user: ${util.get_pillar('db_info:db_manager_user', 'manager')}
    - connection_pass: ${util.get_pillar('db_info:db_manager_pw', '1234QWER')}
    - connection_charset: utf8