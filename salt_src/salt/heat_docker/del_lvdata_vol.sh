#!/bin/bash
GET_LVDATA_VG() {
    lvdata_vg=$(lvs | awk '{if ($1 == "lvdata") printf("%s\n",$2)}')
    echo $lvdata_vg
}
LV_EXISTS() {
    lvname=$1
    for lv_name in $(lvs --noheadings -o lv_name);do
        if [ "$lv_name" == "$lvname" ]; then
            return 1
        fi
    done
}
LV_EXISTS lvdata
if [ $? -eq 1 ]; then
    echo "deleting lvdata"
    #lvdata_vg=$(GET_LVDATA_VG)
    lvremove -y $(lvs | awk '{if ($1 == "lvdata") printf("%s/%s\n",$2,$1)}')
fi
#LV_EXISTS dockerpool
#if [ $? -ne 1 ]; then
#    lvcreate -l 90%FREE --thinpool dockerpool ${lvdata_vg}
#fi


