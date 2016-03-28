#!/bin/bash
function checkfile () {
    res=`glance image-list|grep ${1}`
    if [ -n "$res" ];then
        return 1
    else
        return 0
    fi
}
if [ -f /root/keystonerc_admin ]; then
    source /root/keystonerc_admin && /usr/bin/dd if=/dev/zero of=/tmp/vmware_legacy bs=1 count=1k
fi
checkfile "windows_legacy"
if [ $? -eq 0 ]; then
    glance image-create --name "windows_legacy" --is-public=True --container-format=bare --disk-format=vmdk --property hypervisor_type="vmware_legacy" --property os_type="windows" \
    --file "/tmp/vmware_legacy" --min-disk 0 --property vmware_adaptertype="lsiLogicsas" --property vmware_disktype="thin" 
elif [ $? -eq 1 ]; then
    echo "Image file already exists ... "
else
    echo "Can't upload images ..."
fi

checkfile "linux_legacy"
if [ $? -eq 0 ]; then
    glance image-create --name "linux_legacy" --is-public=True --container-format=bare --disk-format=vmdk --property hypervisor_type="vmware_legacy" --property os_type="linux" \
    --file /tmp/vmware_legacy --min-disk 0 --property vmware_adaptertype="lsiLogicsas" --property vmware_disktype="thin" 
elif [ $? -eq 1 ]; then
    echo "Image file already exists ... "
else
    echo "Can't upload images ..."
fi

checkfile "otherrOs_legacy"
if [ $? -eq 0 ]; then
    glance image-create --name "otherrOs_legacy" --is-public=True --container-format=bare --disk-format=vmdk --property hypervisor_type="vmware_legacy" --property os_type="otherOs" \
    --file /tmp/vmware_legacy --min-disk 0 --property vmware_adaptertype="lsiLogicsas" --property vmware_disktype="thin" 
elif [ $? -eq 1 ]; then
    echo "Image file already exists ... "
else
    echo "Can't upload images ..."
fi
