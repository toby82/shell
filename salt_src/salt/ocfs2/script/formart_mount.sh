ip_port=$1
iqn=$2
lun_number=$3
target_mnt=$4
need_formart=$5

[ -z $ip_port ] || [ -z $iqn ] || [ -z $lun_number ] || [ -z $target_mnt ] || [ -z $need_formart ] && exit 100

cluster_num=12
tmp_mnt=/tmp/test_mnt

echo "开始检查挂载路径并挂载 [$target_mnt]"
iqn_lun="'ip*${ip_port}'*${iqn}*lun*${lun_number}"
dev_name=$(ls -al /dev/disk/by-path/ip-${ip_port}*lun*${lun_number})
echo $dev_name
if [ $? -ne 0 ];then
    echo -e "\nError:没有找到IP&Lun的在by-path的地址。"
    echo "$dev_name"
    exit 100
fi

dev_name="${dev_name##*/}"
dev_path="/dev/${dev_name}"
mutipath_id=$(multipath -ll $dev_path |head -n 1 |awk '{print $1}')
if [ -z $mutipath_id ];then
    echo -e "\nError:没有找到mutipath id。"
    exit 100
fi

mutipath="/dev/mapper/${mutipath_id}"
echo $mutipath

#检查是否已经挂载
mount | grep -e "$mutipath.*$target_mnt.*ocfs2"
if [ $? -eq 0 ];then
    echo "$mutipath 已被 $target_mnt 挂载。"
    exit 30
fi

mkdir -p $tmp_mnt
mkdir -p $target_mnt
mount $mutipath $tmp_mnt > /dev/null 2>&1
ocfs_flag=`df -T $tmp_mnt |grep ocfs2`
umount $tmp_mnt > /dev/null 2>&1
if [ -n "$ocfs_flag" ]; then
    echo "挂载磁盘已为ocfs格式"
else
    if [ "$need_formart" == "True" ];then
        echo "挂载磁盘为非ocfs格式，需重新格式化"
	mkfs.ocfs2 -b 4k -C 32K -L "ocfs2" -N $cluster_num $mutipath --fs-feature-level=max-compat
    else
	# 通常第一个node节点会主动格式化为ocfs，余下的节点就直接挂载使用。
	# 如果余下的节点认为该磁盘为非ocfs格式，则说明部署流程或其他方面出错。
	echo -e "\nError:需要挂载的磁盘非ocfs格式。"
	exit 100
    fi
fi

/etc/init.d/o2cb online ocfs2
rtv=$?
if [ $rtv -ne 0 ];then
    echo -e "\nError: o2cb online 执行结果有错误。" 
    exit $rtv
fi
mount $mutipath $target_mnt > /dev/null 2>&1
mount | grep $target_mnt
rtv=$?
if [ $rtv -ne 0 ];then
    echo -e "\nError: 挂载 $mutipath $target_mnt 失败。" 
    exit $rtv
else
    sed -i "\|$target_mnt|d" /etc/fstab
    echo "$mutipath $target_mnt ocfs2   _netdev,defaults  0 0" >> /etc/fstab 
fi
chmod 777 $target_mnt
cd $target_mnt
umask 000

echo -e "\n执行成功！"
exit 0
