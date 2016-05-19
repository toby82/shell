#!/bin/bash
#!/bin/bash
clear
#1.修改主机名
cat << EOF > /etc/sysconfig/network
NETWORKING=yes
HOSTNAME=template
EOF
#2.配置hosts文件
sed -i "1 s/$/\t${hostname}/" /etc/hosts
#3.添加adminuser账户
useradd osmaster
echo password | passwd --stdin osmaster
#4.配置sudo
chmod u+w /etc/sudoers
sed -i "/root\tALL=(ALL)/ a\${adminuser}\tALL=(ALL)\tALL" /etc/sudoers
chmod u-w /etc/sudoers
#5.添加pubuser组,将adminuser添加到pubuser组
groupadd -g 200 staff
usermod -G staff osmaster
#6.编辑selinux(重启生效)
sed -i '/^SELINUX=/ s/=.*/=disabled/' /etc/selinux/config
sed -i '/^SELINUX=/ s/=.*/=disabled/' /etc/sysconfig/selinux
#7.关闭防火墙
service iptables stop
chkconfig iptables off
#8.编辑无响应注销
sed -i '$ a\export TMOUT=600' /etc/profile
#9.编辑history时间戳
sed -i '$ a\export HISTTIMEFORMAT="%F %T"' /etc/bashrc
#10.删除网络rules文件
rm -rf /etc/udev/rules.d/70-persistent-net.rules
#11.编辑访问控制
sed -i '$ a\umask 027' /etc/bashrc
#12.编辑登录失败用户锁定策略
sed -i '/auth required pam_deny.so/ i\auth required pam_tally2.so onerr=fail deny=10 unlock_time=180 root_unlock_time=1' /etc/pam.d/system-auth
#13.编辑口令策略
sed -i '/password requisite/ c\password requisite pam_cracklib.so dcredit=-1 ucredit=-1 ocredit=-1 lcredit=0 minlen=8 retry=3' /etc/pam.d/system-auth
#14.编辑口令规则
sed -i '/PASS_MAX_DAYS/ s/99999/90/' /etc/login.defs
sed -i '/PASS_MIN_DAYS/ s/0/2/' /etc/login.defs
#15.编辑SSH登录
# 1. 将 root 账户仅限制为控制台访问
# 2. 不要支持闲置会话，并配置 Idle Log Out Timeout 间隔(Set to 600 seconds = 10 minutes)
# 3. 禁用用户的 .rhosts 文件
# 4. 禁用空密码
# 5. 使用RSA算法的基于rhosts的安全验证
# 6. 禁用基于主机的身份验证
# 7. 禁用GSSAPI认证
# 8. 禁止UseDNS
# 9. 设置不显示Banner
sed -i '/[^$]/ {
/PermitRootLogin yes/ { s@#@@; s@yes@no@ } 
/ClientAliveInterval 0/ { s@#@@; s@0@600@ }
/ClientAliveCountMax 0/ { s@#@@ }
/IgnoreRhosts yes/ { s@#@@ }
/PermitEmptyPasswords no/ { s@#@@ }
/RhostsRSAAuthentication no/ { s@#@@ }
/HostbasedAuthentication no/ { s@#@@ }
/GSSAPIAuthentication yes/ { s@yes@no@ }
/GSSAPICleanupCredentials yes/ { s@yes@no@ }
/UseDNS no/ { s@#@@ }
/Banner none/ { s@#@@ }
}' /etc/ssh/sshd_config
#16.配置关键目录权限控制
chmod 644 /etc/passwd
chmod 600 /etc/shadow
chmod 644 /etc/group
#17.关闭ctrl+alt+del
sed -i '/start\|exec/ s@^@#@' /etc/init/control-alt-delete.conf
#18.初始化网卡信息
cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
NAME="System eth0"
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=dhcp
DEFROUTE=yes
IPV4_FAILURE_FATAL=yes
IPV6INIT=no
EOF
#19.调整系统启动等待时间
sed -i 's/\(timeout\)=.*/\1=1/' /boot/grub/grub.conf
#20.允许系统通过ttyS0登入
cat <<-EOF >> /etc/init/ttyS0.conf
stop on runlevel[016]
start on runlevel[345]
respawn
instance /dev/ttyS0
exec /sbin/mingetty /dev/ttyS0
EOF
sed -i 's/ rhgb//' /boot/grub/grub.conf
sed -i 's/ quiet//' /boot/grub/grub.conf
sed -i 's/kernel.*/& console=tty0 console=ttyS0,9600n8 /' /boot/grub/grub.conf
echo "ttyS0" >> /etc/securetty
#19.清空历史操作记录
history -c
#20.关机
shutdown -h now

