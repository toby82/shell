#!/bin/bash

war_path=$1
dist_path=$2
#war_path=/opt/server/tomcat/webapps/nebula4j-web.war
#dist_path=/opt/server/tomcat/webapps/pulsar

[ ! -d /opt/server/tomcat/webapps ] && exit 100
/bin/rm -rf $dist_path
mkdir -p $dist_path
unzip $war_path -d $dist_path > /dev/null 2>&1
if [ $? -eq 0 ];then
    echo "Extracted Success."
else
    echo "Extracted Error!"
    exit 100
fi

chown -R tomcat:tomcat $dist_path
exit 0
