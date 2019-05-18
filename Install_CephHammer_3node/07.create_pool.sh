#!/bin/bash -ex
source config.cfg

#Chuyen public key sang OpenStack
echo "############ Chuyen public key sang OpenStack ############"
sshpass -p $CON_PASS ssh-copy-id  root@$CON_LOCAL
sshpass -p $COM1_PASS ssh-copy-id  root@$COM1_LOCAL
sshpass -p $COM2_PASS ssh-copy-id  root@$COM2_LOCAL

iphost=/etc/hosts
cat << EOF >> $iphost
$CON_LOCAL            $CON
$COM1_LOCAL            $COM1
$COM2_LOCAL       	$COM2
EOF


#Tao cac pool cho OpenStack
echo "############ Tao cac pool cho OpenStack ############"
ceph osd pool create volumes 128 128
ceph osd pool create images 128 128
ceph osd pool create backups 128 128
ceph osd pool create vms 128 128

#Tao user cho cac dich vu cua OpenStack
echo "############ Tao user cho cac dich vu cua OpenStack ############"
ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images'
ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'
ceph auth get-or-create client.cinder-backup mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=backups'






