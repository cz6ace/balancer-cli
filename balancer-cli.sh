#!/bin/bash

tmpfile=/tmp/balancer-$$
protocol=http
host=localhost
port=80
path=balancer-manager
url=

# nonce - will be populated automatically
declare -A nonce
# load factor
lf=
# load balance set
ls=
# route
wr=
# route redirect
rr=
# status ignore
statusi=
# status disable
statusd=
# status standby
statush=
# status drain
statusn=
# if defined, debug messages can be emited
#DEBUG=1

#
# Print usage
#
help() {
  cat <<HELP
Usage: $0 [OPTION]... command [ARG]
Executes command in apache balancer manager.

Options:
  --host host       host of balancer manager  (default localhost)
  --port            port of the balancer manager (default 80)
  --path            path of the balancer manager (default balancer-manager)
  -h --help         show this help

Commands:
  balancers                   list all balancers
  enable <balancer> <worker>  enable the worker in the specified balancer, clears the drain flag
  disable <balancer> <worker> disable the worker in the specified balancer
  drain <balancer> <worker>   set the worker to drain mode in the specified balancer
HELP
}

#
# Read default parameters like host, port, etc.
#
readdefaults() {
  configfile=$(dirname $0)/.balancer-cli
  if [ -e $configfile ]; then
    source $configfile
  elif [ -e ~/.balancer-cli ]; then
    source ~/.balancer-cli
  fi
  return
}

#
# list balancers
#
balancers() {
  verbose=$1
  balancers=$(cat $tmpfile | grep "LoadBalancer Status for" | sed -e "s|.*balancer://||;s|</a>.*</h3>||")
  [ 1 -eq "$1" ] && echo balancers: $balancers
  for b in $balancers; do
    [ 1 -eq "$1" ] && echo reading balancer $b
    workers=$(cat $tmpfile | grep -e "b=$b" | grep -v "LoadBalancer Status" | sed -e "s/\(.*w=\)\([^\&\"]*\)\(.*\)/\2/")
    nonce[$b]=$(cat $tmpfile | grep -e "b=$b" | grep nonce | sed -e "s/\(.*nonce=\)\([0-9a-zA-Z\-]\+\)\(.*\)/\2/" | head -n 1)
    [ 1 -eq "$1" ] && echo workers: $workers
    [ 1 -eq "$1" ] && echo nonce  : ${nonce[$b]}
  done
}

#
# configureworker
#
configureworker() {
  # balancer
  balancer=$1
  # worker
  worker=$2
  # action
  action=$3
  case $action in
    "enable")
      statusd=0
      statusn=0
      ;;
    "disable")
      statusd=1
      ;;
    "drain")
      statusn=1
      ;;
    *)
      ;;
  esac
  echo configuring $worker @ $balancer with action $action
  # echo statusd=$statusd statusn=$statusn
  # if variables are empty, do not pass them,
  #- otherwise the values will be rewritten by default values and old settings will be lost
  if [ -n "$lf" ]; then uloadfactor="lf=${lf}&"; fi
  if [ -n "$ls" ]; then uloadset="ls=${ls}&"; fi
  if [ -n "$wr" ]; then uroute="wr=${wr}&"; fi
  if [ -n "$rr" ]; then uredirect="rr=${rr}&"; fi
  wget "${url}" --post-data "${uloadfactor}${uloadset}${uroute}${uredirect}w_status_I=${statusi}&w_status_D=${statusd}&w_status_H=${statush}&w_status_N=${statusn}&w=${worker}&b=${balancer}&nonce=${nonce[$balancer]}" -O - 1>/dev/null 2>&1
}

if [ $# -eq 0 ]; then
  help
  exit 0
fi

readdefaults

# read options first
while (( $# > 0 )); do
  case $1 in
    "--port")
      port=$2
      shift 2
      ;;
    "--host")
      host=$2
      shift 2
      ;;
    "--path")
      path=$2
      shift 2
      ;;
    "-h" | "--help")
      help
      shift
      ;;
    *)
      break
      ;;
  esac
done

# first read initial page with balancers, workers and also nonce
url=${protocol}://${host}:${port}/${path}
[ -n "$DEBUG" ] && echo wget $url -O $tmpfile
wget $url -O $tmpfile 2>/dev/null
trap "rm $tmpfile" EXIT

# now read commands
while (( $# > 0 )); do
  case $1 in
    "balancers" | "list")
      balancers 1
      ;;
    "enable" | "disable" | "drain")
      # configure <balancer> <worker>
      balancers 0
      configureworker $2 $3 $1
      shift 2
      ;;
    *)
      echo Unknown command $1
      exit 1
      ;;
  esac
  shift
done

echo done
#eof
