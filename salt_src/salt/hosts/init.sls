{% if 'present' in pillar['mg_nw']['hosts']  %}
{% for hostname in pillar['mg_nw']['hosts']['present']  %}
{{ hostname }}:
  host:
    - present
    - ip: {{ pillar['mg_nw']['hosts']['present'][hostname] }}
{% endfor %}
{% endif %}

{% if 'absent' in pillar['mg_nw']['hosts']  %}
{% for hostname in pillar['mg_nw']['hosts']['absent']  %}
{{ hostname }}:
  host:
    - absent
    - ip: {{ pillar['mg_nw']['hosts']['absent'][hostname] }}
{% endfor %}
{% endif %}


