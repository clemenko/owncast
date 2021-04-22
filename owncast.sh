#!/bin/bash
# https://docs.docker.com/engine/install/ubuntu/

###################################
# edit vars
###################################
set -e
password=Pa22word
zone=nyc3
size=s-4vcpu-8gb-amd
key=30:98:4f:c5:47:c2:88:28:fe:3c:23:cd:52:49:51:01
domain=ieacro.com

image=ubuntu-20-04-x64

######  NO MOAR EDITS #######
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)
BLUE=$(tput setaf 4)

#better error checking
command -v doctl >/dev/null 2>&1 || { echo "$RED" " ** Doctl was not found. Please install. ** " "$NORMAL" >&2; exit 1; }

################################# up ################################
function up () {

#build VMS
echo -n " building stream.ieacro.com"
doctl compute droplet create stream.ieacro.com --region $zone --image $image --size $size --ssh-keys $key --wait > /dev/null 2>&1
export ip=$(doctl compute droplet list --no-header|grep stream|awk '{print $3}')
echo "$GREEN" "ok" "$NORMAL"

#check for SSH
echo -n " checking for ssh"
until [ $(ssh -o ConnectTimeout=1 root@$ip 'exit' 2>&1 | grep 'timed out\|refused' | wc -l) = 0 ]; do echo -n "." ; sleep 5; done
echo "$GREEN" "ok" "$NORMAL"

#update DNS
echo -n " updating dns"
doctl compute domain records create $domain --record-type A --record-name stream --record-ttl 300 --record-data $ip > /dev/null 2>&1
doctl compute domain records create $domain --record-type CNAME --record-name "traefik" --record-ttl 150 --record-data stream.$domain. > /dev/null 2>&1
echo "$GREEN" "ok" "$NORMAL"

#host modifications and Docker install
# curl -fsSL https://get.docker.com | bash
echo -n " adding os packages"
ssh root@$ip 'export DEBIAN_FRONTEND=noninteractive && apt update && \
curl -fsSL https://get.docker.com | bash && #apt upgrade -y; #apt autoremove -y && \
cat << EOF >> /etc/sysctl.conf
# SWAP settings
vm.swappiness=0
vm.overcommit_memory=1

# Have a larger connection range available
net.ipv4.ip_local_port_range=1024 65000

# Increase max connection
net.core.somaxconn = 10000

# Reuse closed sockets faster
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=15

# The maximum number of "backlogged sockets".  Default is 128.
net.core.somaxconn=4096
net.core.netdev_max_backlog=4096

# 16MB per socket - which sounds like a lot,
# but will virtually never consume that much.
net.core.rmem_max=16777216
net.core.wmem_max=16777216

# Various network tunables
net.ipv4.tcp_max_syn_backlog=20480
net.ipv4.tcp_max_tw_buckets=400000
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_syn_retries=2
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_wmem=4096 65536 16777216

# ARP cache settings for a highly loaded docker swarm
net.ipv4.neigh.default.gc_thresh1=8096
net.ipv4.neigh.default.gc_thresh2=12288
net.ipv4.neigh.default.gc_thresh3=16384

# ip_forward and tcp keepalive for iptables
net.ipv4.tcp_keepalive_time=600
net.ipv4.ip_forward=1

# monitor file system events
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
EOF
sysctl -p && \
systemctl enable docker && systemctl start docker && mkdir -p /opt/{owncast,traefik}' > /dev/null 2>&1
echo "$GREEN" "ok" "$NORMAL"

echo -n " - deploying owncast & traefik "
rsync -avP docker-compose.yml root@"$ip":/opt/ > /dev/null 2>&1
rsync -avP files_owncast/* root@"$ip":/opt/owncast > /dev/null 2>&1
ssh root@$ip 'curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod 755 /usr/local/bin/docker-compose && \
cd /opt && docker-compose up -d' > /dev/null 2>&1
echo "$GREEN" "ok" "$NORMAL"
}


############################## kill ################################
#remove the vms
function kill () {

export ip=$(doctl compute droplet list --no-header|grep stream|awk '{print $3}')

echo -n " killing it all "
doctl compute droplet delete --force stream.$domain
doctl compute domain records delete -f $domain $(doctl compute domain records list $domain|grep 'stream'|awk '{print $1}')
echo "$GREEN" "ok" "$NORMAL"
}

############################# usage ################################
function usage () {
  echo ""
  echo "-------------------------------------------------"
  echo ""
  echo " Usage: $0 {up|kill}"
  echo ""
  echo " ./$0 up # build the vms "
  echo " ./$0 kill # kill the vms"
  echo ""
  echo "-------------------------------------------------"
  echo ""
  exit 1
}

case "$1" in
        up) up;;
        kill) kill;;
        *) usage;;
esac
