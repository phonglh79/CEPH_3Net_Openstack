#!/bin/bash -ex
source config.cfg

#Tai trusted key va add repo
echo "############ Tai trusted key va add repo ############"
wget -q -O- 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc' | sudo apt-key add - 
echo deb http://ceph.com/debian-$ceph_ver/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list 
apt-get update

#Cai dat Ceph packages tren OpenStack
echo "############ Cai dat Ceph packages tren OpenStack ############"
apt-get install ceph-common python-rbd  -y

#Cau hinh Glance
echo "############ Cau hinh Glance ############"
glance=/etc/glance/glance-api.conf
test -f $glance.kilo || cp $glance $glance.kilo
sed -e '/DEFAULT/a show_image_direct_url = True' -e '/glance_store/,${/glance_store/!d;}' $glance.kilo > $glance.kilo2
sed  -e '/glance_store/a stores = rbd \
rbd_store_pool = images \
rbd_store_user = glance \
rbd_store_ceph_conf = /etc/ceph/ceph.conf \
rbd_store_chunk_size = 8 \
default_store=rbd\ ' $glance.kilo2 > $glance


#Cau hinh Cinder
echo "############ Cau hinh Cinder ############"
cinder=/etc/cinder/cinder.conf
test -f $cinder.kilo || cp $cinder $cinder.kilo
sed -e "/DEFAULT/a volume_driver = cinder.volume.drivers.rbd.RBDDriver \
rbd_pool = volumes \
rbd_ceph_conf = /etc/ceph/ceph.conf \
rbd_flatten_volume_from_snapshot = false \
rbd_max_clone_depth = 5 \
rbd_store_chunk_size = 4 \
rados_connect_timeout = -1 \
glance_api_version = 2 \
rbd_user = cinder \
rbd_secret_uuid = '"$SECRET"'' \
backup_driver = cinder.backup.drivers.ceph \
backup_ceph_conf = /etc/ceph/ceph.conf \
backup_ceph_user = cinder-backup \
backup_ceph_chunk_size = 134217728 \
backup_ceph_pool = backups \
backup_ceph_stripe_unit = 0 \
backup_ceph_stripe_count = 0 \
restore_discard_excess_bytes = true" -e 's/volume_name_template = volume-%s/#volume_name_template = volume-%s/' \
 -e 's/volume_group = cinder-volumes/#volume_group = cinder-volumes/' $cinder.kilo > $cinder


#Khoi dong lai dich vu
echo "############ Khoi dong lai dich vu ############"
cd /etc/init.d/; for i in $( ls glance-* ); do sudo service $i restart; cd;done
cd /etc/init.d/; for i in $( ls cinder-* ); do sudo service $i restart; cd;done