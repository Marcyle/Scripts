#!/bin/bash
#-----------------------------------------------------------------
# 脚本名:  sysinit.sh
# 脚本用途:
# 其它功能:
# 脚本位置:    /.scripts
#-----------------------------------------------------------------
#

cat << EOF
+------------------------------------------------------------------------------+
|                        === 初始化 Centos-6.x 系统 ===                        |
+------------------------------------------------------------------------------+
EOF
echo ""

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo -e "\033[31m Error: 你需要使用root用户权限来执行此脚本! \033[0m"
    exit 1
fi
echo "#-------------------------------------"
echo ""


cat << EOF
+------------------------------------------------------------------------------+
|                  === 开始安装系统常用依赖库以及常用系统工具 ===                 |
+------------------------------------------------------------------------------+
EOF
echo ""
echo -e "\033[31m 开始安装系统常用依赖库以及常用系统工具...... \033[0m"
yum groupinstall -y "Desktop Platform Development" "Server Platform Development" "Development Tools" "SNMP Support"
yum install -y gcc gcc-c++ cmake make autoconf libtool-ltdl-devel gd-devel freetype-devel libxml2-devel libjpeg-devel libpng-devel \
openssl-devel curl-devel bison patch unzip libmcrypt-devel libmhash-devel libevent-devel ncurses-devel mlocate flex sysstat libaio-devel \
ntp openldap-devel openssl-devel libcurl-devel unzip perl-ExtUtils-CBuilder perl-ExtUtils-MakeMaker iotop bzip2* ntpdate
yum install -y wget unzip zip htop vim iftop nc nmap dstat iostat lrzsz screen lftp wget curl sysstat strace lsof telnet tree tcpdump
yum update -y openssh-server openssh openssh-clients
echo ""
echo -e "\033[31m 安装系统常用依赖库以及常用系统工具完成! \033[0m"
echo "#-------------------------------------"
echo ""

cat << EOF
+------------------------------------------------------------------------------+
|                               === 开始系统调优 ===                            |
+------------------------------------------------------------------------------+
EOF
echo ""

echo -e "\033[31m 删除系统默认存在但不用的用户和用户组...... \033[0m"
for i in lp sync shutdown halt uucp operator games gopher ftp
do
userdel $i > /dev/null 2>&1
done

for i in lp sync shutdown halt uucp operator games gopher ftp
do
groupdel $i > /dev/null 2>&1
done
echo -e "\033[31m 删除系统默认存在但不用的用户和用户组完成! \033[0m"
echo "#-------------------------------------"
echo ""

echo -e "\033[31m 设置密码长度大于8位...... \033[0m"
cp /etc/login.defs /etc/login.defs.bak_$date
sed  -i '/PASS_MIN_LEN/s/5/8/g' /etc/login.defs
echo -e "\033[31m 设置密码长度大于8位完成! \033[0m"
echo "#-------------------------------------"
echo ""


echo -e "\033[31m 设置一个用于系统管理的非ront用户和用户组（bqadm）......\033[0m"
groupadd -g 600 bqadm > /dev/null 2>&1
useradd -u 600 -g 600 -s /bin/bash bqadm > /dev/null 2>&1
bqadm_passwd=$(openssl rand -base64 10|tr '/' 'a-z')
echo "${bqadm_passwd}" |passwd --stdin bqadm > /dev/null 2>&1
echo "the host bqadm password is ${bqadm_passwd}">/tmp/bqadm_passwd.txt

echo -e "\033[31m 设置一个用于系统管理的非ront用户和用户组完成! \033[0m"
echo -e "\033[31m 设置此特定用户的sudo权限! \033[0m"
echo "bqadm	ALL=(ALL) 	NOPASSWD: ALL" >> /etc/sudoers && echo -e "\033[31m 设置此特定用户(bqadm)的sudo权限成功! \033[0m"
echo "#-------------------------------------"
echo ""

echo -e "\033[31m 设置仅允许特定用户(bqadm)的su到root......\033[0m"
usermod -G wheel bqadm
sed -i '/pam_wheel.so use_uid/s/^#//g' /etc/pam.d/su
echo "SU_WHEEL_ONLY yes" >> /etc/login.defs
echo -e "\033[31m 设置仅允许特定用户(bqadm)的su到root完成! \033[0m"
echo "#-------------------------------------"
echo ""

echo -e "\033[31m 创建常用普通用户，用于系统管理...... \033[0m"
if [ $(id weblogic|wc -l) -ne 1 ];then
groupadd -g 500 weblogic  > /dev/null 2>&1
useradd -u 500 -g 500 weblogic  > /dev/null 2>&1
fi
for name in www tomcat beehive zabbix mysql apache
do
	for ((num=501;num<507;num++))
	do
		groupadd -g $num $name > /dev/null 2>&1
		useradd -u $num -g $num -s /sbin/nologin $name > /dev/null 2>&1
	done
done
echo -e "\033[31m 创建常用普通用户完成! \033[0m"
echo "#-------------------------------------"
echo ""


echo -e "\033[31m 修改sshd配置，禁止root用户直接登录，优化sshd服务...... \033[0m"
sed -i "s/#Port 22/Port 10022/" /etc/ssh/sshd_config
sed -i "s/#PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
sed -i "s/#PermitEmptyPasswords no/PermitEmptyPasswords no/" /etc/ssh/sshd_config
echo "AllowUsers bqadm" >> /etc/ssh/sshd_config
chkconfig sshd on >/dev/null 2>&1
service sshd restart >/dev/null 2>&1
echo -e "\033[31m 修改sshd配置，禁止root用户直接登录，优化sshd服务完成! \033[0m"
echo "#-------------------------------------"
echo ""


echo -e "\033[31m 关闭ctrl+alt+del热键功能...... \033[0m"
sed  -i 's/^[^#]/#&/g' /etc/init/control-alt-delete.conf
echo -e "\033[31m 关闭ctrl+alt+del热键完成! \033[0m"
echo "#-------------------------------------"
echo ""


echo -e "\033[31m 禁用IPV6...... \033[0m"
cat << EOF >>/etc/modprobe.d/dist.conf
alias net-pf-10 off
alias ipv6 off
EOF


echo -e "\033[31m 设置登录超时自动退出...... \033[0m"
cp /etc/profile /etc/profile_`date +%F-%H`
echo "export TMOUT=3600" >> /etc/profile
echo -e "\033[31m 设置登录超时自动退出完成! \033[0m"
echo "#-------------------------------------"
echo ""

echo -e "\033[31m 设置系统history历史操作记录条目和格式...... \033[0m"
cat << EOF > /etc/profile.d/history.sh
USER_IP=$(who -u am i 2>/dev/null|awk '{print $NF}'|sed -e 's/[()]//g')
HISTFILESIZE=4000
HISTSIZE=4000
HISTTIMEFORMAT="%F %T \${USER_IP} \`whoami\` "
export HISTTIMEFORMAT
EOF
source /etc/profile.d/history.sh
echo -e "\033[31m 设置系统history历史操作记录条目和格式完成! \033[0m"
echo "#-------------------------------------"
echo ""

echo -e "\033[31m 禁用系统不必要的默认服务...... \033[0m"
CURSRV=$(chkconfig --list |grep 3:on|awk '{print $1}')
for i in ${CURSRV[@]}
do
	case $i in
	crond | irqbalance | sysstat | iptables | network | sshd | snmpd | syslog | rsyslog | udev-post)
	    ;;
	*)
	    chkconfig $i off
	    service $i stop
	    ;;
	esac
done
echo -e "\033[31m 禁用系统不必要的默认服务完成! \033[0m"
echo "#-------------------------------------"
echo ""



echo -e "\033[31m 内核参数调优...... \033[0m"
mv /etc/sysctl.conf /etc/sysctl.conf.bak
cat << EOF > /etc/sysctl.conf
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 20000
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.core.wmem_default = 8388608
net.core.wmem_max = 16777216
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.somaxconn = 32768
kernel.sysrq = 0
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967297
EOF
echo -e "\033[31m 内核参数调优完成! \033[0m"
echo "#-------------------------------------"
echo ""

echo -e "\033[31m iptables默认规则配置...... \033[0m"
iptables -F
iptables -X
iptables -Z
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m state --state NEW -m tcp -p tcp -m multiport --dports 10022 -j ACCEPT
iptables -A INPUT -m state --state NEW -m udp -p udp -m multiport --dports 161 -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
/etc/init.d/iptables save >/dev/null 2>&1
echo -e "\033[31m iptables默认规则配置完成! \033[0m"
echo "#-------------------------------------"
echo ""

cat << EOF
+------------------------------------------------------------------------------+
|                        === 开始创建系统常用的目录 ===                          |
+------------------------------------------------------------------------------+
EOF
echo -e "\033[31m 开始创建系统常用的目录...... \033[0m"
mkdir -p /{confs,logs,data,mnt,software,.scripts}
echo -e "\033[31m 创建系统常用的目录完成! \033[0m"
echo "#-------------------------------------"
echo ""

cat << EOF
+------------------------------------------------------------------------------+
|                        === 开始升级系统默认Python版本 ===                       |
+------------------------------------------------------------------------------+
EOF
echo -e "\033[31m 开始升级系统默认Python版本...... \033[0m"
cd /software
wget ftp://bqjrftp:Pass123$%^@10.83.20.27:9020/software/python/Python-2.7.12.tgz
if [ $? -eq 0 ]
then
    tar -xf Python-2.7.12.tgz
    cd Python-2.7.12
    ./configure --prefix=/usr/local/python2.7.12
    make && make install
    mv /usr/bin/python /usr/bin/python_old
    ln -s /usr/local/python2.7.12/bin/python /usr/bin/
    echo -e "\033[31m python版本升级完成! \033[0m"
    sed -i 's@#!/usr/bin/python@#!/usr/bin/python_old@' /usr/bin/yum
    echo -e "\033[31m 调整yum程序的python版本完成! \033[0m"
else
    echo -e "\033[31m 获取JDK软件包失败，请手动检查! \033[0m"
fi

cat << EOF
+------------------------------------------------------------------------------+
|                        === 开始安装JDK和配置JDK环境 ===                       |
+------------------------------------------------------------------------------+
EOF
if [ $(ls /usr/local/|grep jdk1.7.0_79|wc -l) -ne 1 ];then
echo -e "\033[31m 开始安装JDK和配置JDK环境...... \033[0m"
cd /software
wget ftp://bqjrftp:Pass123$%^@10.83.20.27:9020/software/jdk/jdk-7u79-linux-x64.tar.gz
if [ $? -eq 0 ]
then
    tar -xf jdk-7u79-linux-x64.tar.gz -C /usr/local
else
    echo -e "\033[31m 获取JDK软件包失败，请手动检查! \033[0m"
fi

cat << EOF > /etc/profile.d/java.sh
JAVA_HOME=/usr/local/jdk1.7.0_79
JRE_HOME=/usr/local/jdk1.7.0_79/jre
CLASS_PATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar:\$JRE_HOME/lib
PATH=\$PATH:\$JAVA_HOME/bin:\$JRE_HOME/bin
export JAVA_HOME JRE_HOME CLASS_PATH PATH
EOF
source /etc/profile.d/java.sh
echo -e "\033[31m 安装JDK和配置JDK环境完成! \033[0m"
echo "#-------------------------------------"
echo""
fi


echo -e "\033[31m 回收系统关键文件权限...... \033[0m"
chmod 644 /etc/passwd && chattr +i /etc/passwd
chmod 644 /etc/shadow && chattr +i /etc/shadow
chmod 644 /etc/group && chattr +i /etc/group
chmod 644 /etc/gshadow && chattr +i /etc/gshadow
chmod 644 /etc/inittab && chattr +i /etc/inittab
echo -e "\033[31m 回收关键系统文件权限完成! \033[0m"
echo "#-------------------------------------"
echo""

cat << EOF
+------------------------------------------------------------------------------+
|                    === 恭喜！系统初始化完毕，准备重载系统! ===                 |
+------------------------------------------------------------------------------+
EOF
sync
echo -e "\033[31m 系统重启10秒钟倒计时(ctrl+c可取消系统重启!)...... \033[0m"
Seconds_left=10
while [ ${Seconds_left} -gt 0 ];do
    echo -ne "\033[33m 倒计时: ${Seconds_left} 秒 \033[0m"
    sleep 1
    Seconds_left=$(($Seconds_left - 1))
    echo -ne "\r     \r" #清除本行文字
done
init 6
