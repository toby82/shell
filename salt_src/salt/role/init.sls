{% set role_cc="" %}
{% set role_nn="" %}
{% set role_nw="" %}
{% if pillar['role']['cc'] == grains['id']%}
{% set role_cc='  - printcc'  %}
{% endif  %}

{% if pillar['role']['nn'] == grains['id']%}
{% set role_nn='  - printnn'  %}
{% endif  %}

{% if pillar['role']['nw'] == grains['id']%}
{% set role_nw='  - printnw'  %}
{% endif  %}  

{% if role_cc|length != 0 or role_nn|length != 0 or role_nw|length != 0  %}
include:
{{ role_cc }}
{{ role_nn }}
{{ role_nw }}
{% endif %}
