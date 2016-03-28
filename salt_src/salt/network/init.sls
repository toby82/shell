{% if salt['pillar.get']('st_nw')  %}
{%   set host_dic = salt['pillar.get']('st_nw').items() %}
{%   for hostname, info in host_dic %}
{%     if grains['id'] == hostname %}
{{ info['dev'] }}:
  network.managed:
    - enabled: True
    - type: eth
    - proto: none
    - ipaddr: {{ info['ip'] }}
    - netmask: {{ info['mask'] }}
{%     endif %}
{%   endfor %}
{% endif %}

