#!/bin/bash
set -e
if [ -f /root/keystonerc_admin ]; then
    source /root/keystonerc_admin
fi

GET_ADMIN_TENANT(){
    local id=$(keystone tenant-list | awk '{if($4 ~ /admin/)print $2}')
    echo $id
}
SET_QUOTA(){
    nova quota-update --instances -1 --cores -1 --ram -1 --floating_ips 250 \
    --injected_files 1000 --metadata_items 1000 $(GET_ADMIN_TENANT)
}
SET_QUOTA
