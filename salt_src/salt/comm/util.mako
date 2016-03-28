<%def name="get_pillar(key, default_value)">\
<%
value = salt['pillar.get'](key, default_value)
if value is None:
    return default_value
else:
    return value
%>
</%def>

<%def name="split_to_array(split_str, separator, default_array)">
<%
if split_str is None:
    return default_array

if len(split_str) == 0:
    return default_array

return split_str.split(separator)
%>
</%def>
