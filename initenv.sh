#!/bin/bash

#===========================================================================
# 建议该脚本在控制节点上运行
# 制作操作系统的模板的配置项
#   以下配置参数需要根据实际情况进行配置
#===========================================================================

# 文件存放的位置
# 操作系统ISO光盘文件|Windows软盘驱动文件|Windows光盘驱动文件
THEPATH=/opt/os_iso

# 待制作镜像的系统类型(注意与制作的镜像系统匹配)
# 选项：linux|windows
IMG_OS_TYPE=linux

# 待制作镜像的名称
# 选项：
#     （Windows系统）
#         windows2003_x86-64|windows7_x86-64|windows2008_x86-64|windows2012_x86-64
#     （Linux系统）
#         centos5_x86-64|centos6_x86-64|ubuntu12_x86-64|rhel6u4_x86-64
IMG_NAME=windows2008_x86_64

# 操作系统ISO文件名称
OS_ISO=windows2008_CN_DVD.iso

# Windows VirtIO驱动文件名称
# -- Windows 2003 VirtIO驱动为 软盘驱动（virtio-win-1.5.2.vfd）
# -- Windows 7、2008、2012 VirtIO驱动为 光盘驱动（virtio-win-1.6.8.iso）
VirtIO_Windows_Driver=virtio-win-1.6.8.iso

# 待制作镜像的系统盘大小（单位：G）
# 系统盘的大小一旦设定后，以后用这个模板创建出的虚机系统盘大小，将和模板保持一致
IMG_SIZE=20G

# 待制作镜像的vCPU核数
# 该项仅仅作用于模板的制作。不会影响到使用该模板创建的虚机。
IMG_CPU=2

# 待制作镜像的内存大小（单位：M）
# 该项仅仅作用于模板的制作。不会影响到使用该模板创建的虚机。
IMG_MEM=2048



#===========================================================================
# 以下选项不可修改
#===========================================================================
# 镜像文件名称示例：windows2003_x86-64_50G.qcow2
IMG_FILE=${THEPATH}/${IMG_NAME}_${IMG_SIZE}.qcow2

# 临时镜像文件名称
TEMP_IMG_FILE=${THEPATH}/TEMP_VIRTIO_DISK.img

# 临时镜像文件大小
TEMP_IMG_SIZE=10M

# VNC监听显示端口
VNC_LISTEN_PORT=5910
ISO_FILE=${THEPATH}/${OS_ISO}
DRIVER_FILE=${THEPATH}/${VirtIO_Windows_Driver}


if [ ! -d ${THEPATH} ];then
    echo "${THEPATH}: No such file or directory"
    exit 1
fi

export IMG_OS_TYPE TEMP_IMG_FILE TEMP_IMG_SIZE VNC_LISTEN_PORT ISO_FILE ISO_FILE DRIVER_FILE IMG_NAME IMG_FILE IMG_CPU IMG_MEM
