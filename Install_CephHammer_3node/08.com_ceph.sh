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

#Add secret key vao libvirt
echo "############ Add secret key vao libvirt ############"
cat > /root/secret.xml <<EOF
<secret ephemeral='no' private='no'>
  <uuid>$SECRET</uuid>
  <usage type='ceph'>
    <name>client.cinder secret</name>
  </usage>
</secret>
EOF


virsh secret-define --file /root/secret.xml
virsh secret-set-value --secret $SECRET --base64 $(cat /root/client.cinder.key) && rm /root/client.cinder.key /root/secret.xml

#Cau hinh Nova
echo "############ Cau hinh Nova ############"
nova=/etc/nova/nova.conf
test -f $nova.kilo || cp $nova $nova.kilo
cat >> $nova <<EOF
[libvirt]
inject_partition=-2
inject_password = false
live_migration_flag=VIR_MIGRATE_UNDEFINE_SOURCE,VIR_MIGRATE_PEER2PEER,VIR_MIGRATE_LIVE,VIR_MIGRATE_PERSIST_DEST
inject_key=False
images_type = rbd
images_rbd_pool = vms
images_rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_user = cinder
rbd_secret_uuid = $SECRET
disk_cachemodes="network=writeback"
hw_disk_discard = unmap 
EOF


sed -i 's/libvirt_inject_password = True/#libvirt_inject_password = True/' $nova
sed -i 's/enable_instance_password = True/#enable_instance_password = True/' $nova
sed -i 's/libvirt_inject_key = true/#libvirt_inject_key = true/' $nova
sed -i 's/libvirt_inject_partition = -1/#libvirt_inject_partition = -1/' $nova

#Khoi dong lai dich vu
echo "############ Khoi dong lai dich vu ############"
cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; cd;done