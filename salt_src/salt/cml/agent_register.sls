#!mako|yaml
<%namespace name="util" file="salt://comm/util.mako" />
<%
hostname2ip = util.get_pillar('mg_nw:hosts:present', "")
cc_hostname = util.get_pillar('iaas_role:cc', "")
cml_api_ip = hostname2ip[cc_hostname]

agent_hostname = grains['id']
agent_ip = hostname2ip[agent_hostname]
%>  
agent.register:
  cmd.run:
    - names:
      - fab register:http://${cml_api_ip}:8484/v1/host -f /opt/software/cml/fabfile -c /opt/server/cml/cml-agent-config -H  ${agent_ip} -R cml-a
    - onlyif:
      - ls /opt/server/cml/cml-agent-config
    - env:
      - HOME: /root
      - LANG: en_US.UTF-8
      - LC_ALL: en_US.UTF-8
