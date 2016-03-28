run_script_dir=$(dirname $0)

#### Main ####
source $run_script_dir/comm/salt_cmd.sh

salt 'cc*' state.sls glusterfs.create_cluster -l info
rtv=$?
if [ $rtv -ne 0 ];then
    output_error_logfile /var/log/salt/minion 20 ERROR
    exit 100
fi

salt '*'   state.sls glusterfs.mounted -l info
