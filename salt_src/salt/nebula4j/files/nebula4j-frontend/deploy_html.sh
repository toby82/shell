#!/bin/bash

tar_path=$1
dist_path=$2
#tar_path=/opt/server/nginx/html.tar.gz
#dist_path=/opt/server/nginx/html/

rootdir=$(dirname $dist_path )
[ ! -d $rootdir ] && exit 100
/bin/rm -rf $dist_path
mkdir -p $dist_path
tar -C $dist_path -zxvf $tar_path > /dev/null 2>&1
if [ $? -eq 0 ];then
    echo "Extracted Success."
else
    echo "Extracted Error!"
    exit 100
fi

chown -R nginx:nginx $dist_path
exit 0
