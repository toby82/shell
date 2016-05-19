#!/bin/bash

# ---------------------------------------------------------------------------
#   检测文件是否存在
# ---------------------------------------------------------------------------
function check_file_exist()
{
    file=$*
    if [ -f ${file} ];then
        return 0
    else
        return 1
    fi
}

# ---------------------------------------------------------------------------
#   初始化参数
# ---------------------------------------------------------------------------
function initenv()
{
    check_file_exist `pwd`/initenv.sh
    if [ $? -eq 1 ];then
        echo "`pwd`/initenv.sh: 文件或目录不存在."
        exit 1
    fi
    . `pwd`/initenv.sh
}

# ---------------------------------------------------------------------------
#   制作LINUX系统镜像
# ---------------------------------------------------------------------------
function create_linux_instance()
{
    /usr/bin/qemu-system-x86_64 -smp ${IMG_CPU} -m ${IMG_MEM} \
    -drive file=${IMG_FILE},if=virtio                   \
    -cdrom ${ISO_FILE}                                  \
    -net nic,model=virtio -net user -nographic          \
    -vnc :${VNC_LISTEN_PORT/59/}                        \
    -localtime                                          \
    --enable-kvm
}

# ---------------------------------------------------------------------------
#   制作Windows系统镜像
# ---------------------------------------------------------------------------
function create_windows_instance()
{
    /usr/bin/qemu-system-x86_64 -smp ${IMG_CPU} -m ${IMG_MEM} \
    -drive file=${IMG_FILE}                             \
    -cdrom ${ISO_FILE}                                  \
    -net nic,model=virtio -net user -nographic          \
    -vnc :${VNC_LISTEN_PORT/59/}                        \
    -localtime                                          \
    -usb -usbdevice tablet                              \
    --enable-kvm
}

# ---------------------------------------------------------------------------
#   安装Windows 2003系统镜像的Virtio驱动
# ---------------------------------------------------------------------------
function install_win2003_virtio()
{
    /usr/bin/qemu-system-x86_64 -smp ${IMG_CPU} -m ${IMG_MEM} \
    -drive file=${IMG_FILE},if=ide,boot=on              \
    -drive file=${TEMP_IMG_FILE},if=virtio              \
    -fda ${DRIVER_FILE}                                 \
    -net nic,model=virtio -net user -nographic          \
    -vnc :${VNC_LISTEN_PORT/59/}                        \
    -localtime                                          \
    -usb -usbdevice tablet                              \
    --enable-kvm
}

# ---------------------------------------------------------------------------
#   安装Windows 7/2008/2012系统镜像的Virtio驱动
# ---------------------------------------------------------------------------
function install_win7_2008_2012_virtio()
{
    /usr/bin/qemu-system-x86_64 -smp ${IMG_CPU} -m ${IMG_MEM} \
    -drive file=${IMG_FILE},if=ide,boot=on              \
    -drive file=${TEMP_IMG_FILE},if=virtio              \
    -cdrom ${DRIVER_FILE}                               \
    -net nic,model=virtio -net user -nographic          \
    -vnc :${VNC_LISTEN_PORT/59/}                        \
    -localtime                                          \
    -usb -usbdevice tablet                              \
    --enable-kvm
}

# ---------------------------------------------------------------------------
#   制作虚拟机镜像系统
# ---------------------------------------------------------------------------
function create_instance()
{
    # 初始化参数
    initenv

    echo "开始制作虚拟机镜像...."
    echo "创建虚拟机镜像磁盘文件：${IMG_NAME}"
    check_file_exist ${IMG_FILE}
    if [ $? -eq 0 ];then
        echo "${IMG_FILE}: 文件已存在!!"
        read -p "是否需要重新创建该文件?（y/n） " answer
        if [[ "${anser}" =~ "y|yes" ]];then
            rm -rf ${IMG_FILE}
            echo "${IMG_FILE}: 文件已删除！"
            if `which qemu-img &>/dev/null`;then
                qemu-img create -f qcow2 ${IMG_FILE} ${IMG_SIZE}
            else
                echo "qemu-img 未安装, 无法制作虚拟机镜像."
                exit 1
            fi
        fi
    else
        if `which qemu-img &>/dev/null`;then
            qemu-img create -f qcow2 ${IMG_FILE} ${IMG_SIZE}
        else
            echo "qemu-img 未安装, 无法制作虚拟机镜像."
            exit 1
        fi
    fi
    echo "请使用 VNCviewer 工具连接 <`hostname -I | awk '{print $1}'` port: ${VNC_LISTEN_PORT}>."
    echo '10秒钟后可以进行VNC连接......' && sleep 10

    check_file_exist ${IMG_FILE}
    if [ $? -eq 1 ];then
        echo "${IMG_FILE}: 文件或目录不存在."
        exit 1
    fi
    check_file_exist "/usr/bin/qemu-system-x86_64"
    if [ $? -eq 1 ];then
        echo "/usr/bin/qemu-system-x86_64: 文件或目录不存在."
        exit 1
    fi

    echo "开始启动虚拟机镜像: ${IMG_NAME}"
    echo -e "\e[31m虚拟机运行时，请不要关闭当前的终端窗口 ！！！！\e[m"
    # -smp n  指定虚机的cpu核数
    # -m   n  指定虚机的内存大小(单位: 兆)
    # -localtime 指定虚机读取本地宿主机的时间
    # -net nic,model=virtio 指定虚机网卡加载驱动的类型
    os_type=$*
    case ${os_type} in
        linux)
            create_linux_instance;;
        windows)
            create_windows_instance;;
        *)
            echo "操作系统类型错误, 请检查配置文件initenv.sh 的参数配置."
            exit 1
    esac
}

# ---------------------------------------------------------------------------
#   安装虚拟机镜像系统的virtio驱动
# ---------------------------------------------------------------------------
function install_virtio()
{
    # 初始化参数
    initenv

    echo "开始启动虚拟机镜像...."
    echo "创建临时的虚拟机镜像virtio磁盘文件：${TEMP_IMG_FILE}"
    check_file_exist ${TEMP_IMG_FILE}
    if [ $? -eq 0 ];then
        echo "${TEMP_IMG_FILE}: 文件已存在!!"
        read -p "是否需要重新创建该文件?（y/n） " answer
        if [ "${anser}" =~ "y|yes" ];then
            rm -rf ${TEMP_IMG_FILE}
            echo "${TEMP_IMG_FILE}: 文件已删除！"
            if `which qemu-img &>/dev/null`;then
                qemu-img create -f qcow2 ${TEMP_IMG_FILE} ${TEMP_IMG_SIZE}
            else
                echo "qemu-img 未安装, 无法制作虚拟机镜像."
                exit 1
            fi
        fi
    else
        if `which qemu-img &>/dev/null`;then
            qemu-img create -f qcow2 ${TEMP_IMG_FILE} ${TEMP_IMG_SIZE}
        else
            echo "qemu-img 未安装, 无法制作虚拟机镜像."
            exit 1
        fi
    fi
    echo "请使用 VNCviewer 工具连接 <`hostname -I | awk '{print $1}'` port: ${VNC_LISTEN_PORT}>."
    echo '10秒钟后可以进行VNC连接......' && sleep 10

    check_file_exist ${TEMP_IMG_FILE}
    if [ $? -eq 1 ];then
        echo "${TEMP_IMG_FILE}: 文件或目录不存在."
        exit 1
    fi
    check_file_exist ${DRIVER_FILE}
    if [ $? -eq 1 ];then
        echo "${DRIVER_FILE}: 文件或目录不存在."
        exit 1
    fi
    check_file_exist "/usr/bin/qemu-system-x86_64"
    if [ $? -eq 1 ];then
        echo "/usr/bin/qemu-system-x86_64: 文件或目录不存在."
        exit 1
    fi

    echo "开始启动虚拟机镜像: ${IMG_NAME}"
    echo -e "\e[31m虚拟机运行时，请不要关闭当前的终端窗口 ！！！！\e[m"
    # -smp n  指定虚机的cpu核数
    # -m   n  指定虚机的内存大小(单位: 兆)
    # -localtime 指定虚机读取本地宿主机的时间
    # -net nic,model=virtio 指定虚机网卡加载驱动的类型
    os_type=$*
    case ${os_type} in
        windows2003)
            install_win2003_virtio;;
        windows7)
            install_win7_2008_2012_virtio;;
        *)
            rm -rf ${TEMP_IMG_FILE}
            echo "操作系统类型错误, 请检查配置文件initenv.sh 的参数配置."
            exit 1
    esac
    rm -rf ${TEMP_IMG_FILE}
}

# ---------------------------------------------------------------------------
#   检测虚拟机镜像系统的配置
# ---------------------------------------------------------------------------
function check_instace_system()
{
    # 初始化参数
    initenv

    echo "开始启动虚拟机镜像...."
    echo "请使用 VNCviewer 工具连接 <`hostname -I | awk '{print $1}'` port: ${VNC_LISTEN_PORT}>."
    echo '10秒钟后可以进行VNC连接......' && sleep 10

    check_file_exist ${IMG_FILE}
    if [ $? -eq 1 ];then
        echo "${IMG_FILE}: 文件或目录不存在."
        exit 1
    fi
    check_file_exist "/usr/bin/qemu-system-x86_64"
    if [ $? -eq 1 ];then
        echo "/usr/bin/qemu-system-x86_64: 文件或目录不存在."
        exit 1
    fi

    echo "开始启动虚拟机镜像: ${IMG_NAME}"
    echo -e "\e[31m虚拟机运行时，请不要关闭当前的终端窗口 ！！！！\e[m"
    # -smp n  指定虚机的cpu核数
    # -m   n  指定虚机的内存大小(单位: 兆)
    # -localtime 指定虚机读取本地宿主机的时间
    # -net nic,model=virtio 指定虚机网卡加载驱动的类型
    /usr/bin/qemu-system-x86_64 -smp ${IMG_CPU} -m ${IMG_MEM} \
    -drive file=${IMG_FILE},if=virtio,boot=on           \
    -net nic,model=virtio -net user -nographic          \
    -vnc :${VNC_LISTEN_PORT/59/}                        \
    -localtime                                          \
    -usb -usbdevice tablet                              \
    --enable-kvm
}

# ---------------------------------------------------------------------------
#   Main
# ---------------------------------------------------------------------------

echo "========================================================="
echo "            使用Qemu-kvm制作KVM虚拟机镜像"
echo "========================================================="
echo "请选择你要执行的操作; 输入 \"quit\" 退出,"
# echo "或者键入 \"help\" 查看帮助信息. 敲回车显示你可以做的操作."
echo
oPS3=${PS3}
PS3="
请选择你要执行的操作："
select COMMANDS in \
    "制作RHEL/CentOS 6.x 镜像" \
    "制作RHEL/CentOS 5.x 镜像" \
    "制作Windows 7 镜像" \
    "    安装Windows 7 的 virtio驱动" \
    "制作Windows Server 2003/2008/2012 镜像" \
    "    安装Windows Server 2003 的 virtio驱动" \
    "    安装Windows Server 2008/2012 的 virtio驱动" \
    "检测虚拟机镜像系统的配置"
do
    if [ "${REPLY}" == "quit" ]; then
        echo "你输入了 \"quit\", 程序退出!"
        break
    fi
#   if [ "${REPLY}" == "help" ]; then
#       echo "请选择你要执行的操作; 输入 \"quit\ 退出,"
#       echo "或者键入 \"help\" 查看帮助信息. 敲回车显示你可以做的操作."
#       echo 
#       continue
#   fi
    if [ ! -z "${COMMANDS}" ]; then
        echo "你选择了选项 [${REPLY}], 下面将执行 \"${COMMANDS}\" 的操作:"
        case ${REPLY} in
            1)	create_instance linux;;
            2)	create_instance linux;;
            3)	create_instance windows;;
            4)	install_virtio windows7;;
            5)	create_instance windows;;
            6)	install_virtio windows2003;;
            7)	install_virtio windows7;;
            8)	check_instace_system;;
            *) 	echo "[${REPLY}] 是无效的选项!!"
                continue
                ;;
        esac
    else
        echo "[${REPLY}]是无效的选项!!"
        continue
    fi
done
PS3=${oPS3}
