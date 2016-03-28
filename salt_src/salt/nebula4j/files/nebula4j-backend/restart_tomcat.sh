#!/bin/bash
check_process_name='/opt/server/tomcat/.*bootstrap.jar'
service_name='tomcatd'

function log(){
    level="$1"
    msg="$2"
    logger -p "cron.${level}" -t "action_service" "[$level] $msg"
}

function wait_for_start(){
    pname="$1"
    wait_time=$2
    loopmax=$3
    local pid=""
    local rtv=0
    for (( i=0 ; $i < $loopmax ; i++  ));do
        sleep $wait_time
        proc_info=$(ps -ef | grep "$pname" | grep -v grep )
        if [ -z "$proc_info" ];then
            continue;
        fi
        pid=$(echo $proc_info | awk '{print $2}')
        if [ -z "$pid" ];then
            continue;
        fi
        break
    done
    if [ -z "$pid" ];then
        rtv=100
    fi
    echo $pid
    return $rtv
}

function wait_for_stop(){
    pname="$1"
    wait_time=$2
    loopmax=$3
    local pid=""
    local rtv=100
    for (( i=0 ; $i < $loopmax ; i++  ));do
        sleep $wait_time
        proc_info=$(ps -ef | grep "$pname" | grep -v grep )
        if [ -n "$proc_info" ];then
            continue;
        fi
        rtv=0
        break
    done
    return $rtv
}


#### Main ####

systemctl stop $service_name
wait_for_stop "$check_process_name" 3 10
rtv=$?
if [ $rtv -ne 0 ];then
    # 使用 kill 停止
    pid=$(wait_for_start "$check_process_name" 1 1)
    if [ -n $pid ];then
        kill $pid
        wait_for_stop "$check_process_name" 3 10
        rtv=$?
        if [ $rtv -ne 0 ];then
            log err "${service_name}停止失败！"
            exit 100
        fi 
    fi
fi
log info "${service_name}停止成功。"

systemctl start $service_name
wait_for_start "$check_process_name" 3 20
if [ $rtv -ne 0 ];then
    log err "${service_name}启动失败！"
    exit 100
fi
log info "${service_name}启动成功。"
exit 0
