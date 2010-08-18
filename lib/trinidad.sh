#!/bin/bash -x
#

RAILS_APP=/home/voeis-demo/voeis/current
PIDFILE=/home/voeis-demo/voeis/shared/tmp/trinidad.pid

case "$1" in
  start)
    echo "Starting trinidad"
    cd $RAILS_APP
    trinidad --config
  ;;

  restart)
    $0 stop
    $0 start
  ;;

  stop)
    echo "Stopping trinidad"
    cd $RAILS_APP
    if [ -f $PIDFILE ]; then
      kill -2 `cat $PIDFILE`
    fi
  ;;

  *)
    echo ”usage: $0  start|stop|restart”
    exit 3
  ;;
esac
