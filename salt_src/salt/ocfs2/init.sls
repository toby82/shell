{% for node_hostname in  salt['pillar.get']('ocfs2_cluster:nodes')  %}
{%   if node_hostname == grains['id'] %}
include:
  - iscsid
  - multipath

ipsan.login:
  cmd.run:
    - names:
      {% set lun_dic = salt['pillar.get']('lun_info:nodes').items() %}
      {% for ip, info in lun_dic %}
      # TODO delete echo
      - "iscsiadm -m discovery -t st -p {{ ip }}"
      - "iscsiadm -m node -T {{ info['iqn'] }} -p {{ ip }} -l"
      {% endfor  %}
    - require:
      - service: iscsid.installed
      - service: multipath.installed

ocfs2.cluster.conf:
  file.managed:
    - name: /etc/ocfs2/cluster.conf
    - makedirs: True
    - source: salt://ocfs2/etc/cluster.conf.template
    - template: mako

ocfs2.o2cb:
  file.managed:
    - name: /etc/sysconfig/o2cb
    - makedirs: True
    - source: salt://ocfs2/etc/o2cb.template
    - template: jinja

ocfs2.online:
  pkg.installed:
    - pkgs: 
      - ocfs2-tools
    - skip_verify: True
  cmd.run:
    - names: 
      - "systemctl start o2cb.service"
      - "service o2cb load"
      - "service o2cb online"
      - "systemctl enable ocfs2"
      - "systemctl enable o2cb"
    - enable: True
    - require: 
      - cmd: ipsan.login
      - pkg: ocfs2.online
      - file: ocfs2.cluster.conf
      - file: ocfs2.o2cb
{%   endif %}
{% endfor %}
