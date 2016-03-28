#!/bin/bash
function get_tenant_id () {
    if [ -f /root/keystonerc_admin ]; then
        source /root/keystonerc_admin 
    fi
    tenant_id=$(keystone tenant-list | awk '{if ($4 == "admin") print $2}')
    echo $tenant_id
}
get_tenant_id
