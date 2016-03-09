#/bin/bash
set -e
DIR=$(cd $(dirname "$0") && pwd)
if [ -f /root/keystonerc_admin ]; then
    source /root/keystonerc_admin
else
    echo "keystonerc_admin does not exist "
    exit 1
fi
if [ -f ${DIR}/cirros-0.3.2-x86_64-disk.img ]; then
    :
else
    echo "${DIR}/cirros-0.3.2-x86_64-disk.img does not exist "
    exit 1
fi

GET_IMAGE_ID(){
    glance image-list | awk '/cirros-test/ {print $2}'
}

GET_FLAVOR_ID(){
    nova flavor-list | awk '/m1.tiny/ {print $2}'
}

GET_NET_ID(){
    neutron net-list | awk '/test-net/ {print $2}'
}
GET_SUBNET_ID(){
    neutron subnet-list | awk '/test-subnet/ {print $2}'
}

CREATE_IMAGE(){
    local id=$(GET_IMAGE_ID)
    if [ -n "${id}" ]; then
        :
    else
        glance image-create --name cirros-test --is-public=True --container-format=bare \
        --disk-format=qcow2 --property os_type="linux" --min-disk 1 \
        --file ${DIR}/cirros-0.3.2-x86_64-disk.img
    fi
}
CREATE_NET(){
    local netid=$(GET_NET_ID)
    if [ -n "${netid}" ]; then
        :
    else
        neutron net-create test-net
    fi
}

CREATE_SUBNET(){
    local subnetid=$(GET_SUBNET_ID)
    if [ -n "${subnetid}" ]; then
        :
    else
        local gateway=$1
        local network_cidr=$2
        CREATE_NET > /dev/null 2>&1
        neutron subnet-create test-net --name test-subnet \
        --gateway ${gateway} ${network_cidr}
    fi
}

CREATE_VM(){
    local vmname="testvm${RANDOM}"
    nova boot --image $(GET_IMAGE_ID) --flavor $(GET_FLAVOR_ID)  \
    --nic net-id=$(GET_NET_ID)  ${vmname}
}
CREATE_IMAGE
CREATE_SUBNET "10.10.11.1" "10.10.11.0/24"
CREATE_VM


