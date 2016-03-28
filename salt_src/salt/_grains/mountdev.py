#!/usr/bin/env python
import logging
import commands
log = logging.getLogger(__name__)
def get_mountdev():
    grains = {}
    try: 
        dev = commands.getoutput("blkid | awk -F: {'if ($1 ~ /-lvdata/) print $1'}")
        grains['mountdev'] = dev
    except:
        log.warning(dev)
    return grains
