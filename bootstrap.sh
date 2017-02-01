#!/bin/bash
export JIP=$(wget -qO- 169.254.169.254/latest/meta-data/local-ipv4)
export JNODE=$(wget -qO- 169.254.169.254/latest/meta-data/local-hostname)
EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
REGION="`echo \"$EC2_AVAIL_ZONE\" | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"

mkdir -p /opt/consul/ssl
credstash -r $REGION get $ENVIRON.consul.global_server_key env=$ENVIRON -n > /opt/consul/ssl/server.key
credstash -r $REGION get $ENVIRON.consul.global_server_conf env=$ENVIRON > /config/server.json
credstash -r $REGION get $ENVIRON.consul.global_server_cert env=$ENVIRON -n > /opt/consul/ssl/server.cer
credstash -r $REGION get $ENVIRON.consul.global_root_cert env=$ENVIRON -n > /opt/consul/ssl/demo-root.cer
until consul join -wan $CONSUL_WAN_NODES; do echo "Failed to establish WAN gossip pool. Reattempting..."; sleep 10; done  &
until consul-replicate -consul 127.0.0.1:8500 $CONSUL_REPLICATION_DC_PREFIXES; do echo "Failed to run consul replicate. Retrying..."; sleep 10; done  &
consul agent -client=0.0.0.0 -node=$JNODE $CONSUL_PARAMS -server -data-dir=/data -advertise=$JIP -config-dir=/config -advertise-wan=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4) -datacenter=$CONSUL_DC_NAME
