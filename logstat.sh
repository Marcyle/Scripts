#!/bin/bash

# 此脚本仅用于分析nginx access log
# 此脚本只适用于格式为"access.log-20180523"的日志
# set -e

# time
timesort(){
        for i in `seq -f "%02g" 0 23`
        do
                query=`grep "${logdateformat}:$i" ${logfile}|wc -l`
                qps=`expr ${query} / 3600`
                echo -e "$i\t${query}\t${qps}" >>/tmp/logstat_time.txt 2>&1
        done
        max=`awk '{print $2}' /tmp/logstat_time.txt|sort -rn|head -1`
        time=`grep ${max} /tmp/logstat_time.txt |awk '{print $1}'`
        mqps=`grep ${max} /tmp/logstat_time.txt |awk '{print $3}'`
        echo -e "${font_green} The maximum amount of ACCESS is ${font_red}${max} ${font_green}at TIME ${font_red}${time} ${font_green}QPS is ${font_red}${mqps}${font_end}"
        head_time=`sort -rn -k 3 /tmp/logstat_time.txt|head`
        echo -e "${font_green} Head of access time ${font_end}\ntime\tviews\tqps\n${head_time}"
        rm -f /tmp/logstat_time.txt
}

# pv,uv
pvuv(){
        pv=`awk 'BEGIN{PV=0}{PV++}END{print PV}' ${logfile}`
        uv=`awk '{print $1}' ${logfile}|sort -u|wc -l`
        ip_pv=`awk '{ip[$1]++}END{for (k in ip){print ip[k],k}}' ${logfile} | sort -rn | head -10`
        echo -e "${font_green} The access log in ${font_red}${logdateformat} ${font_green}pv is ${font_red}${pv} ${font_green}and uv is ${font_red}${uv}${font_end}"
        echo -e "${font_green} Head of access ip addr ${font_end}\n${ip_pv}"
}

main(){
        font_red="\033[31m"
        font_green="\033[32m"
        font_end="\033[0m"
        [[ $UID != 0 ]] && echo -e "${font_red} Must be root to running... ${font_end}" && exit 1
        [[ $# != 1 ]] && echo -e "${font_green} USAGE:$0 logpath ${font_end}" && exit 1
        clear
        logfile=$1
        logdate=`echo ${logfile} |cut -c 12-`
        logdateformat=`date +%d/%b/%G -d ${logdate}`
        echo -e "Analysising... ..."
        pvuv
        timesort
}
main $1
