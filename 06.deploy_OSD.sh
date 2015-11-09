#!/bin/bash -ex
source config.cfg

scp /var/lib/ceph/bootstrap-osd/ceph.keyring ceph2:/var/lib/ceph/bootstrap-osd
scp /var/lib/ceph/bootstrap-osd/ceph.keyring ceph3:/var/lib/ceph/bootstrap-osd


#Dat GPT Table cho cac HDD
echo "############ Dat GPT Table cho cac HDD ############"
parted /dev/$OSD0 mklabel GPT
parted /dev/$OSD1 mklabel GPT
ssh -t ceph2 sudo parted /dev/$OSD2 mklabel GPT
ssh -t ceph2 sudo parted /dev/$OSD3 mklabel GPT
ssh -t ceph3 sudo parted /dev/$OSD4 mklabel GPT
ssh -t ceph3 sudo parted /dev/$OSD5 mklabel GPT


#Khoi tao OSD
echo "############ Khoi tao OSD ############"
ceph-disk prepare --cluster ceph --cluster-uuid $FSID --fs-type xfs /dev/$OSD0
ceph-disk prepare --cluster ceph --cluster-uuid $FSID --fs-type xfs /dev/$OSD1
ssh -t ceph2 sudo ceph-disk prepare --cluster ceph --cluster-uuid $FSID --fs-type xfs /dev/$OSD2
ssh -t ceph2 sudo ceph-disk prepare --cluster ceph --cluster-uuid $FSID --fs-type xfs /dev/$OSD3
ssh -t ceph3 sudo ceph-disk prepare --cluster ceph --cluster-uuid $FSID --fs-type xfs /dev/$OSD4
ssh -t ceph3 sudo ceph-disk prepare --cluster ceph --cluster-uuid $FSID --fs-type xfs /dev/$OSD5

 
#Chay OSD
echo "############ Chay OSD ############"
ceph-disk activate /dev/${OSD0}1
ceph-disk activate /dev/${OSD1}1
ssh -t ceph2 sudo ceph-disk activate /dev/${OSD2}1
ssh -t ceph2 sudo ceph-disk activate /dev/${OSD3}1
ssh -t ceph3 sudo ceph-disk activate /dev/${OSD4}1
ssh -t ceph3 sudo ceph-disk activate /dev/${OSD5}1




