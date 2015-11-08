#!/bin/bash -ex
source config.cfg

echo "########## Dat IP cho NIC ##########"
ETH0=/etc/sysconfig/network-scripts/ifcfg-eth0
test -f ETH0.orig || cp ETH0 ETH0.orig
rm ETH0
touch ETH0
cat << EOF >  ETH0
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=yes
BOOTPROTO=static
IPADDR=$CEPH1_EXT
NETMASK=255.255.255.0
GATEWAY=$GATEWAY
DNS1=8.8.8.8
EOF

ETH1=/etc/sysconfig/network-scripts/ifcfg-eth1
test -f ETH1.orig || cp ETH1 ETH1.orig
rm ETH1
touch ETH1
cat << EOF >  ETH1
DEVICE=eth1
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=yes
BOOTPROTO=static
IPADDR=$CEPH1_LOCAL
NETMASK=255.255.255.0
EOF

ETH2=/etc/sysconfig/network-scripts/ifcfg-eth2
test -f ETH2.orig || cp ETH2 ETH2.orig
rm ETH2
touch ETH2
cat << EOF >  ETH2
DEVICE=eth2
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=yes
BOOTPROTO=static
IPADDR=$CEPH1_REPLICATE
NETMASK=255.255.255.0
EOF

echo "########## Khai bao Hostname ceph1 ##########"

hostname
echo "HOSTNAME = $HOST1" > /etc/sysconfig/network
hostname "$HOST1"

iphost=/etc/hosts
test -f $iphost.orig || cp $iphost $iphost.orig
rm $iphost
touch $iphost
cat << EOF > $iphost
127.0.0.1               localhost
$CEPH1_LOCAL            $HOST1
$CEPH2_LOCAL            $HOST2
$CEPH3_LOCAL        $HOST3
EOF

service network restart
yum update -y

init 6