#!/bin/bash -ex
source config.cfg

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