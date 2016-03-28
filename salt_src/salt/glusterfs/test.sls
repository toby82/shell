#!mako|yaml
<%
num_cpus = salt['grains.get']('num_cpus')
mem_total = salt['grains.get']('mem_total')
cpuset_cpus = num_cpus / 2
if mem_total > 30000:
    memory_limit = "16G"
else:
    memory_limit = str(mem_total / 2) + 'M'
%>  
