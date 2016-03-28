#### Main ####
salt '*' saltutil.sync_all > /dev/null && salt-run deploy_iaas.deploy
