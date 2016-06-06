#!/bin/bash
tag='2.0.0'
img_name=`docker images | awk '/2.0.0/{print $3}'`
for i in $img_name
    do
	echo "deleting $i"
	docker rmi $i
	sleep 1
    done
