#!mako|yaml
<%
cc_node  = pillar['iaas_role']['cc']
%>
ntpdate.installed:
  pkg.installed:
    - name: ntpdate

ntpdate.sync:
  cron.present:
    - name: /usr/sbin/ntpdate ${cc_node} && /sbin/hwclock -w
    - user: root
    - minute: '*/10'
    - require:
      - pkg: ntpdate.installed
