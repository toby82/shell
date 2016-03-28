run_script_dir=$(dirname $0)

#### Main ####
source $run_script_dir/comm/salt_cmd.sh
python $run_script_dir/comm/config.py
if [ $? -eq 0 ]; then
    salt '*' state.highstate -l debug
    salt '*' state.sls cml.agent_register
fi
