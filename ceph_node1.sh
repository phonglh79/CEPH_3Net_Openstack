#!/bin/bash -ex
source config.cfg

echo "########## Khai bao Hostname ceph1 ##########"

hostname
echo "HOSTNAME = $HOST1" > /etc/sysconfig/network
hostname "$HOST1"

iphost=/etc/hosts
test -f $iphost.orig || cp $iphost $iphost.orig
rm $iphost
touch $iphost
cat << EOF >> $iphost
127.0.0.1               localhost
$CEPH1_LOCAL            $HOST1
$CEPH2_LOCAL            $HOST2
$CEPH3_LOCAL        $HOST3
EOF

#Cai dat keygen
########
echo "############ Cai dat keygen ############"
sleep 5
########
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

#Chuyen public key sang cac node khac
echo "StrictHostKeyChecking no" > /root/.ssh/config
echo "UserKnownHostsFile=/dev/null" >> /root/.ssh/config
sshpass -p $CEPH2_PASS ssh-copy-id  root@$CEPH2_LOCAL
sshpass -p $CEPH3_PASS ssh-copy-id  root@$CEPH3_LOCAL
#Doi hostname cho Ceph2 va Ceph3
echo "############ Doi hostname cho Ceph2 va Ceph3 ############"
ssh -t ceph2 sudo echo "HOSTNAME = $HOST2" > /etc/sysconfig/network
ssh -t ceph2 sudo hostname "$HOST2"
ssh -t ceph3 sudo echo "HOSTNAME = $HOST3" > /etc/sysconfig/network
ssh -t ceph3 sudo hostname "$HOST3"

#Cai dat EPEL repo
echo "############ Cai dat EPEL repo ############"
rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
ssh -t ceph2 sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
ssh -t ceph3 sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

#Cai dat cac goi ho tro
echo "############ Cai dat cac goi ho tro ############"
yum install -y snappy leveldb gdisk python-argparse gperftools-libs
ssh -t ceph2 sudo yum install -y snappy leveldb gdisk python-argparse gperftools-libs
ssh -t ceph2 sudo yum install -y snappy leveldb gdisk python-argparse gperftools-libs

#Add repo cho CEPH
echo "############ Add repo cho CEPH ############"
cat << EOF > /root/ceph_repo
[ceph]
name=Ceph packages for \$basearch
baseurl=http://ceph.com/rpm-firefly/el6/\$basearch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc
[ceph-noarch]
name=Ceph noarch packages
baseurl=http://ceph.com/rpm-firefly/el6/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc
[ceph-source]
name=Ceph source packages
baseurl=http://ceph.com/rpm-firefly/el6/SRPMS
enabled=0
gpgcheck=1
type=rpm-md
gpgkey=https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc
EOF
ceph_repo=/etc/yum.repos.d/ceph.repo
test -f $ceph_repo.orig || cp $ceph_repo $ceph_repo.orig
rm $ceph_repo
touch $ceph_repo
cat /root/ceph_repo >> $ceph_repo

#ssh -t ceph2 sudo test -f $ceph_repo.orig || cp $ceph_repo $ceph_repo.orig
#ssh -t ceph2 sudo rm $ceph_repo
#ssh -t ceph2 sudo touch $ceph_repo
#ssh -t ceph2 sudo cat /root/ceph_repo >> $ceph_repo

scp $ceph_repo $CEPH2_LOCAL:/etc/yum.repos.d
scp $ceph_repo $CEPH3_LOCAL:/etc/yum.repos.d

#Cai dat cac thanh phan cua Ceph
echo "############ Cai dat cac thanh phan cua Ceph ############"
yum install ceph -y --disablerepo=epel
ssh -t ceph2 sudo yum install ceph -y --disablerepo=epel
ssh -t ceph3 sudo yum install ceph -y --disablerepo=epel

#Kiem tra lai viec cai dat
echo "############ Kiem tra lai viec cai dat tren ceph1############"
rpm -qa | egrep -i "ceph|rados|rbd"
sleep 5
echo "############ Kiem tra lai viec cai dat tren ceph2############"
ssh -t ceph2 sudo rpm -qa | egrep -i "ceph|rados|rbd"
sleep 5
echo "############ Kiem tra lai viec cai dat tren ceph3############"
ssh -t ceph2 sudo rpm -qa | egrep -i "ceph|rados|rbd"
sleep 5
 
#Khoi dong lai cac node
echo "############ Khoi dong lai cac node ############"
ssh -t ceph2 sudo init 6
ssh -t ceph3 sudo init 6
init 6	
