#!mako|yaml
<%
hostname2ip = salt['pillar.get']('mg_nw:hosts:present')
autodeploy_node = pillar['iaas_role']['autodeploy']
autodeploy_ip = hostname2ip[autodeploy_node]
%>

repo.cleaned:
  cmd.run:
    - names:
      - "mkdir -p /etc/yum.repos.d/useless"
      - "find /etc/yum.repos.d/ -maxdepth 1 -type f ! -name rdo-release.repo ! -name epel.repo | xargs -i mv -f {} /etc/yum.repos.d/useless"
    - require_in:
      - file: epel.repo.configured
      - file: rdo.repo.configured

epel.repo.configured:
  file.managed:
    - name: /etc/yum.repos.d/epel.repo
    - source: salt://yum_repos/template/epel.repo
    - makedirs: True
    - template: jinja
    - defaults:
      AUTODEPLOY_IP: ${autodeploy_ip}
      HTTP_PORT: ${pillar['yum_repo']['http_port']}
      VERSION: ${pillar['yum_repo']['version']}

rdo.repo.configured:
  file.managed:
    - name: /etc/yum.repos.d/rdo-release.repo
    - source: salt://yum_repos/template/rdo-release.repo
    - makedirs: True
    - template: jinja
    - defaults:
      AUTODEPLOY_IP: ${autodeploy_ip}
      HTTP_PORT: ${pillar['yum_repo']['http_port']}
      VERSION: ${pillar['yum_repo']['version']}
