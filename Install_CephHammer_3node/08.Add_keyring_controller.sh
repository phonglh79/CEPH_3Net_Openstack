#!/bin/bash -ex
source config.cfg

#Copy ceph.conf sang cac node OpenStack
echo "############ Copy ceph.conf sang cac node OpenStack ############"
for i in $CON $COM1 $COM2 
do 
ssh -t $i sudo mkdir /etc/ceph
ssh -t $i sudo tee /etc/ceph/ceph.conf < /etc/ceph/ceph.conf 
done

#Add keyring cho Cinder, Glance
echo "############ Add keyring cho Cinder, Glance ############"
ceph auth get-or-create client.glance | ssh -t $CON sudo tee /etc/ceph/ceph.client.glance.keyring
ssh -t $CON sudo chown glance:glance /etc/ceph/ceph.client.glance.keyring
ceph auth get-or-create client.cinder | ssh -t $CON sudo tee /etc/ceph/ceph.client.cinder.keyring
ssh -t $CON sudo chown cinder:cinder /etc/ceph/ceph.client.cinder.keyring
ceph auth get-or-create client.cinder-backup | ssh -t $CON sudo tee /etc/ceph/ceph.client.cinder-backup.keyring
ssh -t $CON sudo chown cinder:cinder /etc/ceph/ceph.client.cinder-backup.keyring

