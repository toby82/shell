#!/bin/bash
egrep 'Listen +80' /etc/httpd/conf/ports.conf  > /dev/null 2>&1
[ $? -ne 0 ] && exit 0
sed -r -i '/Listen +80/d' /etc/httpd/conf/ports.conf > /dev/null 2>&1
systemctl restart httpd
sleep 3
