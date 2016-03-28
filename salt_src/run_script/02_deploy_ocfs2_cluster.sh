run_script_dir=$(dirname $0)

#### Main ####
source $run_script_dir/comm/salt_cmd.sh

salt-run ocfs2_formart_mount.run -l info
