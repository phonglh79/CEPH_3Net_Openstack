#!/bin/bash -ex
source config.cfg

#Tao thu muc chua file cau hinh
echo "############ Tao thu muc chua file cau hinh ############"
mkdir /etc/ceph
CONF=/etc/ceph/ceph.conf
test -f $CONF.orig || cp $CONF $CONF.orig
rm $CONF
touch $CONF
cat << EOF >  $CONF
[global]
public network = $LOCAL
cluster network = $REPLICATE
fsid = $FSID

osd pool default min size = 1
osd pool default pg num = 128
osd pool default pgp num = 128
osd journal size = 1024

[mon]
mon host = $HOST1,$HOST2,$HOST3
mon addr = $CEPH1_LOCAL,$CEPH2_LOCAL,$CEPH3_LOCAL
mon initial members = $HOST1

[mon.$HOST1]
host = $HOST1
mon addr = $CEPH1_LOCAL

[mon.$HOST2]
host = $HOST2
mon addr = $CEPH2_LOCAL

[mon.$HOST3]
host = $HOST3
mon addr = $CEPH3_LOCAL
EOF

#Tao keyring cho Cluster
echo "############ Tao keyring cho Cluster ############"
KEYRING=/tmp/ceph.mon.keyring
if [ -f "$KEYRING" ]
then
ceph-authtool --create-keyring $KEYRING --gen-key -n mon. --cap mon 'allow *'
fi

#Tao client.admin user
echo "############ Tao client.admin user ############"
ADMIN_KEYRING=/etc/ceph/ceph.client.admin.keyring
if [ -f "$ADMIN_KEYRING" ]
then
ceph-authtool --create-keyring $ADMIN_KEYRING --gen-key -n client.admin --set-uid=0 --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow'
ceph-authtool /tmp/ceph.mon.keyring --import-keyring $ADMIN_KEYRING
fi

#Tao monitor map
MONMAP=/tmp/monmap
if [ -f "$MONMAP" ]
then
monmaptool --create --add $HOST1 $CEPH1_LOCAL --fsid $FSID MONMAP
fi

#Tao thu muc cho Monitor
test -f /var/lib/ceph/mon/ceph-$HOST1 || mkdir /var/lib/ceph/mon/ceph-$HOST1

#Tao Monitor daemon
ceph-mon --mkfs -i $HOST1 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring

#Khoi chay CEPH
service ceph start

#Kiem tra trang thai Ceph
echo "############ Kiem tra trang thai Ceph ############"
ceph status
sleep 5

#Copy ceph.conf va ceph.client.admin.keyring sang 2 node con lai
echo "############ Copy ceph.conf va ceph.client.admin.keyring sang 2 node con lai ############"
scp /etc/ceph/ceph.* $HOST2:/etc/ceph
scp /etc/ceph/ceph.* $HOST3:/etc/ceph

#Tao thu muc cho Monitor
echo "############ Tao thu muc cho Monitor ############"
ssh -t $HOST2 sudo mkdir -p /var/lib/ceph/mon/ceph-$HOST2 /tmp/$HOST2
ssh -t $HOST3 sudo mkdir -p /var/lib/ceph/mon/ceph-$HOST3 /tmp/$HOST3

#Tao keyring cho Ceph Cluster
echo "############ Tao keyring cho Ceph Cluster ############"
ssh -t $HOST2 sudo ceph auth get mon. -o /tmp/$HOST2/monkeyring
ssh -t $HOST3 sudo ceph auth get mon. -o /tmp/$HOST3/monkeyring

#Lay Monitor map
echo "############ Lay Monitor map ############"
ssh -t $HOST2 sudo ceph mon getmap -o /tmp/$HOST2/monmap
ssh -t $HOST3 sudo ceph mon getmap -o /tmp/$HOST3/monmap

#Tao Monitor daemon
echo "############ Tao Monitor daemon ############"
ssh -t $HOST2 sudo ceph-mon -i $HOST2 --mkfs --monmap /tmp/$HOST2/monmap --keyring /tmp/$HOST2/monkeyring
ssh -t $HOST3 sudo ceph-mon -i $HOST3 --mkfs --monmap /tmp/$HOST3/monmap --keyring /tmp/$HOST3/monkeyring

#Add monitor moi vao cluster
echo "############ Add monitor moi vao cluster ############"
ssh -t $HOST2 sudo touch /var/lib/ceph/mon/ceph-$HOST2/sysvinit
ssh -t $HOST2 sudo /etc/init.d/ceph start mon.$HOST2
ssh -t $HOST3 sudo touch /var/lib/ceph/mon/ceph-$HOST3/sysvinit
ssh -t $HOST3 sudo /etc/init.d/ceph start mon.$HOST3

#Kiem tra trang thai CEPH
echo "############ Kiem tra trang thai Ceph ############"
ceph status
sleep 5




