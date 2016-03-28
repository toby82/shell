run_script_dir=$(dirname $0)

#### Main ####
source $run_script_dir/comm/salt_cmd.sh

salt "cc*" state.sls nebula4j -l info
rtv=$?
if [ $rtv -eq 0 ];then
    cc_ip=$(cat /etc/hosts | grep cc | awk '{print $1}')
    cat <<EOF


----------------------------------------
门户安装成功。
  访问地址：http://${cc_ip}/
  管理员: root
  密码：admin
----------------------------------------
EOF
fi
