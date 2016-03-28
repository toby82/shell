ntp.installed:
  pkg.installed:
    - name: ntp
  cmd.run:
    - name: /usr/sbin/ntpdate {{ pillar['iaas_role']['autodeploy'] }} && /sbin/hwclock -w || echo "sync datetime ..."
    - unless: systemctl status ntpd
  service.running:
    - name: ntpd
    - enable: True
    - watch:
      - file: /etc/ntp.conf
    - require:
      - pkg: ntp.installed
  file.managed:
    - name: /etc/ntp.conf
    - source: salt://ntp/etc/ntp.conf
    - template: jinja
    - makedirs: True
    - defaults:
      AUTODEPLOY_HOST: server {{ pillar['iaas_role']['autodeploy'] }}
    - require:
      - pkg: ntp.installed
