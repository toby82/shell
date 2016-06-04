#!/bin/bash
tag='2.0.1'
for r in `docker images|grep kolla | awk '{print $1}'`
    do
	filename=${r##*/}
        echo saving $r:$tag
	docker save $r:$tag | gzip -9 - > ${filename}.tar.gz
	sleep 1
    done
exit

