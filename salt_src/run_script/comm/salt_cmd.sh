function output_error_logfile(){
    logpath=$1
    showlines=$2
    key=$3

    [ -z $showlines ] && showlines=20
    echo -e "\n\n可查询错误日志: $logpath"
    echo "-----------------------------------------------"
    if [ -z $key ];then
        tail -n 20 $logpath
    else
        tail -n 20 $logpath | grep $key --color    
    fi
}
salt '*' saltutil.refresh_pillar > /dev/null 2>&1
