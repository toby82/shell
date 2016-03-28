#!mako|yaml
<%namespace name="util" file="salt://comm/util.mako" />
<%
util.get_pillar('mg_nw:hosts:present', "")
hostname2ip = util.get_pillar('mg_nw:hosts:present', "")
cc_node = util.get_pillar('iaas_role:cc', "")
dockerhost = util.get_pillar('iaas_role:vmw_agent', cc_node)
cc_ip = hostname2ip[cc_node]
docker_ip = hostname2ip[dockerhost]
rabbit_ip = cc_ip
rabbit_user = "guest"
rabbit_password = "guest"

db_nebula4j_name = util.get_pillar('nebula4j_info:db_name', "nebula4j")
db_nebula4j_user = util.get_pillar('nebula4j_info:db_user', "nebula4j")
db_nebula4j_pw = util.get_pillar('nebula4j_info:db_nebula4j_pw', "huacloudhuacloud")

glance_tmp_path = util.get_pillar("glance_tmp_path", "/datas/upload_files/")
tomcat_webapp_path = util.get_pillar("nebula4j_info:tomcat_webapp_path", "/opt/server/tomcat/webapps")
docbase = util.get_pillar("nebula4j_info:docbase_name", "pulsar")
docbase_path = tomcat_webapp_path + "/" + docbase

static_web = util.get_pillar("nebula4j_info:static_web", "/opt/server/nginx/html/")
nginx_upstream_servers_list = [cc_ip+":8080"]
%>

nebula4j.installed:
  pkg.installed:
    - pkgs:
      - jdk1.8.0_51
      - apache-tomcat
      - nginx

db.created:
  mysql_database.present:
    - host: ${cc_ip}
    - name: ${db_nebula4j_name}
    - character_set: "utf8"
    - collate: "utf8_general_ci"
    - connection_host: ${cc_ip}
    - connection_port: 3306
    - connection_user: ${util.get_pillar('db_info:db_manager_user', 'manager')}
    - connection_pass: ${util.get_pillar('db_info:db_manager_pw', '1234QWER')}
    - connection_charset: utf8

  mysql_user.present:
    - host: ${cc_ip}
    - name: ${db_nebula4j_user}
    - password: ${db_nebula4j_pw}
    - connection_host: ${cc_ip}
    - connection_port: 3306
    - connection_user: ${util.get_pillar('db_info:db_manager_user', 'manager')}
    - connection_pass: ${util.get_pillar('db_info:db_manager_pw', '1234QWER')}
    - connection_charset: utf8

  mysql_grants.present:
    - host: ${cc_ip}
    - grant: all privileges
    - database: ${db_nebula4j_name}.*
    - user: ${db_nebula4j_user}
    - connection_host: ${cc_ip}
    - connection_port: 3306
    - connection_user: ${util.get_pillar('db_info:db_manager_user', 'manager')}
    - connection_pass: ${util.get_pillar('db_info:db_manager_pw', '1234QWER')}
    - connection_charset: utf8

vmw2os_db:
  mysql_grants.present:
    - host: ${cc_ip}
    - grant: all privileges
    - database: "vmw2os.*"
    - user: ${db_nebula4j_user}
    - connection_host: ${cc_ip}
    - connection_port: 3306
    - connection_user: ${util.get_pillar('db_info:db_manager_user', 'manager')}
    - connection_pass: ${util.get_pillar('db_info:db_manager_pw', '1234QWER')}
    - connection_charset: utf8
    
db.imported:
  file.managed:
    - name: /tmp/schema.sql
    - source: salt://nebula4j/files/nebula4j-backend/schema.sql
  cmd.wait:
    - name: "mysql --default-character-set=utf8 -h${cc_ip} -unebula4j -p${db_nebula4j_pw} nebula4j < /tmp/schema.sql"
    - watch:
      - mysql_database: db.created
db_quartz.imported:
  file.managed:
    - name: /tmp/quartz.sql
    - source: salt://nebula4j/files/nebula4j-backend/quartz.sql
  cmd.wait:
    - name: "mysql --default-character-set=utf8 -h${cc_ip} -unebula4j -p${db_nebula4j_pw} nebula4j < /tmp/quartz.sql"
    - watch:
      - mysql_database: db.created
# For nebula4j-backend
/var/log/pulsar:
  file.directory:
    - user: tomcat
    - group: tomcat
    - mode: 750
    - makedirs: True
/datas/download:
  file.directory:
    - user: nginx
    - group: nginx
    - mode: 777
    - makedirs: True

${glance_tmp_path}:
  file.directory:
    - user: nginx
    - group: nginx
    - mode: 777
    - makedirs: True

${static_web}:
  file.directory:
    - user: nginx
    - group: nginx
    - file_mode: 774
    - dir_mode: 775
    - makedirs: True

/etc/logrotate.d/tomcat:
  file.managed:
    - source: salt://nebula4j/files/nebula4j-backend/tomcat.logrotate

/opt/server/tomcat/bin/setenv.sh:
  file.managed:
    - source: salt://nebula4j/files/nebula4j-backend/tomcat_setenv.sh

/opt/server/tomcat/conf/server.xml:
  file.managed:
    - source: salt://nebula4j/files/nebula4j-backend/server.xml

keystone_user.created:
  cmd.script:
    - shell: /bin/bash
    - source: "salt://nebula4j/files/nebula4j-backend/create_keystone_user.sh"

nebula4j_web.deployed:
  file.managed:
    - name: ${tomcat_webapp_path}/${docbase}.war
    - source: salt://nebula4j/files/nebula4j-backend/nebula4j-web.war
  cmd.wait_script:
    - shell: /bin/bash
    - source: "salt://nebula4j/files/nebula4j-backend/deploy_war.sh"
    - args: "${tomcat_webapp_path}/${docbase}.war ${docbase_path}"
    - watch:
      - file: nebula4j_web.deployed

logback.xml:
  file.managed:
    - name: ${docbase_path}/WEB-INF/classes/logback.xml
    - source: salt://nebula4j/files/nebula4j-backend/logback.xml
    - require:
      - cmd: nebula4j_web.deployed

application.development.properties:
  file.managed:
    - name: ${docbase_path}/WEB-INF/classes/application.development.properties
    - source: salt://nebula4j/files/nebula4j-backend/application.development.properties
    - template: mako
    - defaults:
        db_ip: ${cc_ip}
        db_name: ${db_nebula4j_name}
        db_user: ${db_nebula4j_user}
        db_password: ${db_nebula4j_pw}
        docker_host: ${docker_ip}
        cc_ip: ${cc_ip}
        nginx_ip: ${util.get_pillar("nebula4j_info:nginx_ip", cc_ip)}
        glance_tmp_path:  ${glance_tmp_path}
        rabbit_ip: ${rabbit_ip}
        rabbit_user: ${rabbit_user}
        rabbit_password: ${rabbit_password}

    - require:
      - cmd: nebula4j_web.deployed
quartz.properties:
  file.managed:
    - name: ${docbase_path}/WEB-INF/classes/quartz.properties
    - source: salt://nebula4j/files/nebula4j-backend/quartz.properties
    - template: mako
    - defaults:
        db_ip: ${cc_ip}
        db_name: ${db_nebula4j_name}
        db_user: ${db_nebula4j_user}
        db_password: ${db_nebula4j_pw}
    - require:
      - cmd: nebula4j_web.deployed
      
tomcat-service:
  service.running:
    - name: tomcatd
    - enable: True
    - watch:
      - file: application.development.properties
      - file: /opt/server/tomcat/bin/setenv.sh
      - file: /opt/server/tomcat/conf/server.xml

# 暂时取消cron重启
tomcat-cron-restart:
  file.managed:
    - source: salt://nebula4j/files/nebula4j-backend/restart_tomcat.sh
    - name: /opt/server/tomcat/bin/restart_tomcat.sh
#   cron.present:
#     - name: "bash /opt/server/tomcat/bin/restart_tomcat.sh"
#     - user: root
#     - hour: 5
#     - comment: "Tomcatd service is restarted by cron periodically."
#     - require:
#       - file: tomcat-cron-restart

# For nebula4j-frontend
nginx_nebula4j_config:
  file.managed:
    - name: /etc/nginx/conf.d/nginx_nebula.conf
    - source: salt://nebula4j/files/nebula4j-frontend/nginx_nebula.conf
    - template: mako
    - defaults:
        servers: ${nginx_upstream_servers_list}
        upload_path: ${glance_tmp_path}
        location_root: ${static_web}

nginx_html.deployed:
  file.managed:
    - name: ${static_web}/../html.tar.gz
    - source: salt://nebula4j/files/nebula4j-frontend/html.tar.gz
  cmd.wait_script:
    - shell: /bin/bash
    - source: "salt://nebula4j/files/nebula4j-frontend/deploy_html.sh"
    - args: "${static_web}/../html.tar.gz ${static_web}"
    - watch:
      - file: nginx_html.deployed

http_80_port.closed:
  cmd.script:
    - shell: /bin/bash
    - source: salt://nebula4j/files/nebula4j-frontend/close_httpd_80_port.sh

nginx-service:
  service.running:
    - name: nginx
    - enable: True
    - require:
      - cmd: http_80_port.closed
    - watch:
      - file: nginx_nebula4j_config
