#!/bin/bash
#
# FileName:    iptables.sh
# Functions:   Linux(CentOS)主机防火墙设置(服务于 web 服务器 )
# Description: 由 TypeCodes 整理自http://www.tudaxia.com/archives/784, 有所改动
#

##############
# 清空原有的iptables规则, 计数器置0
##############
iptables -F
iptables -X
iptables -Z

##############
# 对公网开放的服务端口, 10022是上文中设置的ssh端口, 80,443是web服务端口
# 由于 typecodes.com 关闭了主机ftp服务, 即不开放21端口
##############
SERVICE_TCP_PORTS="10022,80,443"
SERVICE_UDP_PORTS="53"

##############
# 设置默认规则
# 通常INPUT及FORWARD设为DROP,OUTPUT设置为ACCEPT就足够了
# 极端情况下，可以将OUTPUT也设置成默认DROP。然后针对OUTPUT逐条增加过滤规则
##############
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

##############
# 允许lo( 则允许通过127.0.0.1访问主机本地服务 ), PING
##############
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -p icmp -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED -j ACCEPT

##############
#客户端上添加zabbix的监控端口(10050,10051）
##############
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 10050 -j ACCEPT
iptables -A OUTPUT -m state --state NEW -m tcp -p tcp --dport 10051 -j ACCEPT

##############
# 关闭危险端口, 范围是 31337~31340
##############
iptables -A OUTPUT -p tcp --dport 31337:31340 -j DROP
iptables -A OUTPUT -p tcp --sport 31337:31340 -j DROP

##############
# 如果要添加内网ip信任（接受其所有TCP请求）
##############
iptables -A INPUT -p tcp -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -p tcp -s 172.16.0.0/12 -j ACCEPT

##############
# 拒绝某个IP( 例如111.111.111.111 )访问阿里云主机服务器, 即拉入黑名单
##############
iptables -I INPUT -s 111.111.111.111 -j DROP

##############
# 放开TCP及UDP服务端口
##############
iptables -A INPUT  -p tcp -j ACCEPT -m multiport --dport $SERVICE_TCP_PORTS
iptables -A INPUT  -p udp -j ACCEPT -m multiport --dport $SERVICE_UDP_PORTS

#######################
# 防止DDOS攻击：Ping of Death
#######################
iptables -N PING_OF_DEATH
iptables -A PING_OF_DEATH -p icmp --icmp-type echo-request \
         -m hashlimit \
         --hashlimit 1/s \
         --hashlimit-burst 10 \
         --hashlimit-htable-expire 300000 \
         --hashlimit-mode srcip \
         --hashlimit-name t_PING_OF_DEATH \
         -j RETURN
iptables -A PING_OF_DEATH -j LOG --log-prefix "ping_of_death_attack: "
iptables -A PING_OF_DEATH -j DROP
iptables -A INPUT -p icmp --icmp-type echo-request -j PING_OF_DEATH

#######################
# 防止DDOS攻击：SYN FLOOD
#######################
iptables -N SYN_FLOOD
iptables -A SYN_FLOOD -p tcp --syn \
         -m hashlimit \
         --hashlimit 200/s \
         --hashlimit-burst 3 \
         --hashlimit-htable-expire 300000 \
         --hashlimit-mode srcip \
         --hashlimit-name t_SYN_FLOOD \
         -j RETURN
iptables -A SYN_FLOOD -j LOG --log-prefix "syn_flood_attack: "
iptables -A SYN_FLOOD -j DROP
iptables -A INPUT -p tcp --syn -j SYN_FLOOD

#######################
# 防止DDOS攻击：stealth scan
#######################
iptables -N STEALTH_SCAN
iptables -A STEALTH_SCAN -j LOG --log-prefix "stealth_scan_attack: "
iptables -A STEALTH_SCAN -j DROP

iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j STEALTH_SCAN

iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN         -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST         -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j STEALTH_SCAN

iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,FIN FIN     -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,PSH PSH     -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,URG URG     -j STEALTH_SCAN

#######################
# 保存上述规则到文件 /etc/sysconfig/iptables 中
#######################
service iptables save

