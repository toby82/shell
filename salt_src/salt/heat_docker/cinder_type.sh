#!/bin/bash
set -e
if [ -f /root/keystonerc_admin ]; then
    source /root/keystonerc_admin
fi
if $(cinder extra-specs-list | egrep -q 'vmdk'); then
    :
else
    cinder type-create vmdk && \
    cinder type-key vmdk set volume_backend_name\=vmdk
fi
