#!/bin/bash
source /root/keystonerc_admin
#echo "Create user[root] in keystone:"
#keystone user-create --name root --pass admin --enabled true
#
#adminTenant=`keystone tenant-list |awk '{if($4=="admin"){print $2}}'`
#echo "Add user[root] in role[admin] in AdminTenant[$adminTenant]"
#keystone user-role-add --user=root --role=admin --tenant-id=$adminTenant


function add_user_and_role(){
    local username=$1
    local password=$2
    local add_to_role=$3

    keystone user-get $username > /dev/null 2>&1
    [ $? -eq 0 ] && return
    echo "Create user[$username] in keystone:"
    keystone user-create --name $username --pass $password --enabled true

    adminTenant=`keystone tenant-list |awk '{if($4=="admin"){print $2}}'`
    echo "Add user[$username] in role[$add_to_role] in AdminTenant[$adminTenant]"
    keystone user-role-add --user=$username --role=$add_to_role --tenant-id=$adminTenant
}

add_user_and_role 'root' 'admin' 'admin'
