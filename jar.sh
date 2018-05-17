#!/bin/sh
. /etc/profile

USER='www'
APP_NAME='qzd.jar'
APP_HOME='/app/app/'
APP_PID() {
    echo $(ps -ef | grep ${APP_HOME}${APP_NAME} | grep -v grep | awk '{print $2}')
}

USAGE="Usage: $0 {\e[00;32mstart\e[00m|\e[00;31mstop\e[00m|\e[00;32mstatus\e[00m|\e[00;31mrestart\e[00m}"

start() {
  pid=$(APP_PID)
  if [ -n "$pid" ]; then
    echo -e "\e[00;31m${APP_NAME} is already running (pid: $pid)\e[00m"
  else
    echo -e "\e[00;32mStarting ${APP_NAME}\e[00m"
    if [[ $(whoami) != ${USER} ]]; then
      cd ${APP_HOME}
      su ${USER} -c "setsid java -jar ${APP_HOME}${APP_NAME} &> /dev/null &"
    else
      cd ${APP_HOME}
      setsid java -jar ${APP_HOME}${APP_NAME} &> /dev/null &
    fi
    sleep 1
    status
  fi
  return 0
}

status() {
  pid=$(APP_PID)
  if [ -n "$pid" ]; then
    echo -e "\e[00;32m${APP_NAME} is running with pid: $pid\e[00m"
  else
    echo -e "\e[00;31m${APP_NAME} is not running\e[00m"
  fi
}

stop() {
  pid=$(APP_PID)
  if [ -n "$pid" ]; then
    echo -e "\e[00;31mStoping ${APP_NAME}\e[00m"
    kill -9 $pid
  else
    echo -e "\e[00;31m${APP_NAME} is not running\e[00m"
  fi

  return 0
}

case $1 in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  status)
    status
    ;;
  *)
    echo -e $USAGE
    ;;
esac
exit 0
