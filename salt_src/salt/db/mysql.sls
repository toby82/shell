#!mako|yaml
<%namespace name="util" file="salt://comm/util.mako" />
db.installed:
  pkg.installed:
   - pkgs:
     - MySQL-python
     - mariadb
     - mariadb-devel
     - mariadb-galera-server
  service.running:
    - name: mariadb
    - enable: True
    - require:
      - pkg: db.installed

db.init:
  cmd.script:
    - shell: /bin/bash
    - source: salt://db/scripts/mysql.init.sh
    - args: "${util.get_pillar('db_info:db_manager_user', 'manager')} ${util.get_pillar('db_info:db_manager_pw', '1234QWER')}"
    - unless: "test -e /var/lib/mysql/inited"
    - require:
      - service: db.installed
