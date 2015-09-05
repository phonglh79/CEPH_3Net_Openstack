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

#Tai trusted key và add repo
echo "############ Tai trusted key và add repo ############"
for i in $CON $COM1 $COM2
do ssh -t $i sudo wget -q -O- 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc' | sudo apt-key add - && \
sudo echo deb http://ceph.com/debian-firefly/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list && \
sudo apt-get update
done

#Cai dat Ceph packages tren OpenStack
echo "############ Cai dat Ceph packages tren OpenStack ############"
for i in $CON $COM1 $COM2
do ssh -t $i sudo apt-get update && sudo apt-get install ceph-common python-ceph glance python-glanceclient -y
done

#Tao cac pool cho OpenStack
echo "############ Tao cac pool cho OpenStack ############"
ceph osd pool create volumes 128
ceph osd pool create images 128
ceph osd pool create backups 128
ceph osd pool create vms 128

#Copy ceph.conf sang cac node OpenStack
echo "############ Copy ceph.conf sang cac node OpenStack ############"
for i in $CON $COM1 $COM2
do scp /etc/ceph/ceph.conf $i:/etc/ceph
done

#Tao user cho cac dich vu cua OpenStack
echo "############ Tao user cho cac dich vu cua OpenStack ############"
ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images'
ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'
ceph auth get-or-create client.cinder-backup mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=backups'

#Add keyring cho Cinder, Glance
echo "############ Add keyring cho Cinder, Glance ############"
ceph auth get-or-create client.glance | ssh $CON sudo tee /etc/ceph/ceph.client.glance.keyring
ssh $CON sudo chown glance:glance /etc/ceph/ceph.client.glance.keyring
ceph auth get-or-create client.cinder | ssh $CON sudo tee /etc/ceph/ceph.client.cinder.keyring
ssh $CON sudo chown cinder:cinder /etc/ceph/ceph.client.cinder.keyring
ceph auth get-or-create client.cinder-backup | ssh $CON sudo tee /etc/ceph/ceph.client.cinder-backup.keyring
ssh $CON sudo chown cinder:cinder /etc/ceph/ceph.client.cinder-backup.keyring

#Add keyring cho Nova
echo "############ Add keyring cho Nova ############"
for i in $COM1 $COM2
ceph auth get-or-create client.cinder | ssh $i sudo tee /etc/ceph/ceph.client.cinder.keyring
done

#Tao Client secret key
echo "############ Tao Client secret key ############"
for i in $COM1 $COM2
ceph auth get-key client.cinder | ssh $i tee client.cinder.key
done

#Add secret key vao libvirt
echo "############ Add secret key vao libvirt ############"
for i in $COM1 $COM2
do ssh -t $i sudo cat > secret.xml <<EOF
<secret ephemeral='no' private='no'>
  <uuid>$SECRET</uuid>
  <usage type='ceph'>
    <name>client.cinder secret</name>
  </usage>
</secret>
EOF
done

#Set key
echo "############ Set key ############"
for i in $COM1 $COM2
do ssh -t $i sudo virsh secret-define --file secret.xml && \
sudo virsh secret-set-value --secret $SECRET --base64 $(cat client.cinder.key) && rm client.cinder.key secret.xml
done

#Cau hinh Glance
echo "############ Cau hinh Glance ############"
glance=/etc/glance/glance-api.conf
test -f $glance.orig || cp $glance $glance.orig
ssh -t $CON sudo sed -e'/\[DEFAULT]/a default_store=rbd' -e '/^\[glance_store]$/,$d' $glance.orig > $glance.orig2
ssh -t $CON sudo sed -e  's/default_store = file/#default_store = file/' -e '$a\[glance_store]\ stores = rbd \
rbd_store_pool = images \
rbd_store_user = glance \
rbd_store_ceph_conf = /etc/ceph/ceph.conf \
rbd_store_chunk_size = 8' $glance.orig2 > $glance

#Cau hinh Cinder
echo "############ Cau hinh Glance ############"
cinder=/etc/cinder/cinder.conf
test -f $cinder.orig || cp $cinder $cinder.orig
ssh -t $CON sudo sed -e'/\[DEFAULT]/a volume_driver = cinder.volume.drivers.rbd.RBDDriver \
rbd_pool = volumes \
rbd_ceph_conf = /etc/ceph/ceph.conf \
rbd_flatten_volume_from_snapshot = false \
rbd_max_clone_depth = 5 \
rbd_store_chunk_size = 4 \
rados_connect_timeout = -1 \
glance_api_version = 2 \
rbd_user = cinder \
rbd_secret_uuid = $SECRET \
backup_driver = cinder.backup.drivers.ceph \
backup_ceph_conf = /etc/ceph/ceph.conf \
backup_ceph_user = cinder-backup \
backup_ceph_chunk_size = 134217728 \
backup_ceph_pool = backups \
backup_ceph_stripe_unit = 0 \
backup_ceph_stripe_count = 0 \
restore_discard_excess_bytes = true' $cinder.orig > $cinder

#Cau hinh Nova
echo "############ Cau hinh Nova ############"
nova=/etc/nova/nova.conf
test -f $nova.orig || cp $nova $nova.orig
for i in $COM1 $COM2
do ssh -t $i sudo sed -e '/\[DEFAULT]/a images_type = rbd \
images_rbd_pool = vms \
images_rbd_ceph_conf = /etc/ceph/ceph.conf \
rbd_user = cinder \
rbd_secret_uuid = $SECRET' -e '/\libvirt_inject_partition = -1/a libvirt_inject_password = false \
libvirt_inject_key = false \
libvirt_inject_partition = -2 \
libvirt_live_migration_flag=VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST,VIR_MIGRATE_TUNNELLED \
live_migration_retry_count=60 \
live_migration_uri=qemu+tcp://%s/system \
live_migration_bandwidth=0 ' $nova.orig > $nova.orig2
do ssh -t $i sudo sed -e 's/libvirt_inject_password = True/#libvirt_inject_password = True/' \
-e 's/enable_instance_password = True/#enable_instance_password = True/' \
-e 's/libvirt_inject_key = true/#libvirt_inject_key = true/' \
-e 's/libvirt_inject_partition = -1/#libvirt_inject_partition = -1/' $nova.orig2 > $nova
done

#Khoi dong lai dich vu
echo "############ Khoi dong lai dich vu ############"
ssh -t $COM1 sudo cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; cd;done
ssh -t $COM2 sudo cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; cd;done
ssh -t $CON sudo cd /etc/init.d/; for i in $( ls glance-* ); do sudo service $i restart; cd;done
ssh -t $CON sudo cd /etc/init.d/; for i in $( ls cinder-* ); do sudo service $i restart; cd;done

