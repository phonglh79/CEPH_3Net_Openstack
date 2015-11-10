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

#Copy ceph.conf sang cac node OpenStack
echo "############ Copy ceph.conf sang cac node OpenStack ############"
for i in $CON $COM1 $COM2
do ssh -t $i sudo tee /etc/ceph/ceph.conf < /etc/ceph/ceph.conf 
done

#Tao user cho cac dich vu cua OpenStack
echo "############ Tao user cho cac dich vu cua OpenStack ############"
ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images'
ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'
ceph auth get-or-create client.cinder-backup mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=backups'

#Add keyring cho Cinder, Glance
echo "############ Add keyring cho Cinder, Glance ############"
ceph auth get-or-create client.glance | ssh -t $CON sudo tee /etc/ceph/ceph.client.glance.keyring
ssh -t $CON sudo chown glance:glance /etc/ceph/ceph.client.glance.keyring
ceph auth get-or-create client.cinder | ssh -t $CON sudo tee /etc/ceph/ceph.client.cinder.keyring
ssh -t $CON sudo chown cinder:cinder /etc/ceph/ceph.client.cinder.keyring
ceph auth get-or-create client.cinder-backup | ssh -t $CON sudo tee /etc/ceph/ceph.client.cinder-backup.keyring
ssh -t $CON sudo chown cinder:cinder /etc/ceph/ceph.client.cinder-backup.keyring

#Add keyring cho Nova
echo "############ Add keyring cho Nova ############"
for i in $COM1 $COM2
do ceph auth get-or-create client.cinder | ssh -t $i sudo tee /etc/ceph/ceph.client.cinder.keyring
done

#Tao secret key tren cac node compute
echo "############ Tao secret key tren cac node compute ############"
for i in $COM1 $COM2
do ceph auth get-key client.cinder | ssh -t $i sudo tee client.cinder.key
done




