#!mako|yaml
<%namespace name="util" file="salt://comm/util.mako" />
<%
print ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
value = util.get_pillar('iaas_role:autodeploy', 'ssss')
print value


value = util.get_pillar('iaas_role:ironic_host', 'test')
print value


%>
