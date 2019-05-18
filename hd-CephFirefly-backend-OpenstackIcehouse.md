﻿# Hướng dẫn cài đặt CEPH làm backend cho OpenStack

### A. Mô hình LAB

![Alt text](http://i.imgur.com/recpCLC.jpg)

### B. Cài đặt OpenStack
Thực hiện theo hướng dẫn sau:
https://github.com/vietstacker/icehouse-aio-ubuntu14.04


### C. Thực hiện trên tất cả các node CEPH
#### C.1. Truy cập bằng tài khoản root vào máy các máy chủ và tải các gói, script chuẩn bị cho quá trình cài đặt
```sh
apt-get update
```

#### C.2. Sửa file /etc/hosts
    127.0.0.1       localhost
    10.10.10.51    controller
    10.10.10.52      ceph1
    10.10.10.53      ceph2
    10.10.10.54      ceph3
	
#### C.3. Add thêm 2 HDD vào các node CEPH, ở đây giả sử là /dev/sdb và /dev/sdc

#### C.4. Đặt GPT table cho /dec/sdb
    parted /dev/sdb
    (parted)mklabel gpt
    (parted)quit
    
#### C.5. Đặt GPT table cho /dec/sdc
    parted /dev/sdc
    (parted)mklabel gpt
    (parted)mkpart primary 0 100%
	
Chọn Ignore nếu xuât hiện thông báo
```sh
    Warning: The resulting partition is not properly aligned for best performance.
    Ignore/Cancel? Ignore
	(parted)quit
```
	
#### C.6. Kiểm tra GPT table đã được set chưa
    parted -l
	
### D. Thực hiện trên CEPH 1
##### D.1. Tạo cặp khóa SSH
    ssh-keygen
    Enter file in which to save the key (/home/user_name/.ssh/id_rsa): [press enter]
    Enter passphrase (empty for no passphrase): [press enter]
    Enter same passphrase again: [press enter]
	
#### D.2. Chuyển khóa public sang các node CEPH khác
    ssh-copy-id root@ceph2
    ssh-copy-id root@ceph3
	
#### D.3. Tải trusted key và add repo	
    wget -q -O- 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc' | sudo apt-key add -
    echo deb http://ceph.com/debian-firefly/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
	apt-get update
	
#### D.4. Tạo thư mục chứa các file tạo ra trong quá trình cài đặt
    mkdir ceph-cluster
    cd ceph-cluster
	

#### D.5. Cài đặt 
	apt-get install ceph-deploy -y
    ceph-deploy new ceph1 ceph2 ceph3
    
	
#### D.6. Sửa lại /ceph-cluster/ceph.conf
    [global]
        ...
		public network = 10.10.10.0/24
        cluster network = 20.20.20.0/24
    [mon.0]
        host = ceph1
        mon addr = 10.10.10.52:6789
    [mon.1]
        host = ceph2
        mon addr = 10.10.10.53:6789
    [mon.2]
        host = ceph3
        mon addr = 10.10.10.54:6789
 
    [osd]
        osd journal = /dev/sdc1
        osd journal size = 2000
    [osd.0]
        host = ceph1
        public addr = 10.10.10.52
        cluster addr = 20.20.20.52

    [osd.1]
        host = ceph2
        public addr = 10.10.10.53
        cluster addr = 20.20.20.53
    [osd.2]
        host = ceph3
        public addr = 10.10.10.54
        cluster addr = 20.20.20.54
		
#### D.7. Cài đặt ceph lên các node
    ceph-deploy install ceph1 ceph2 ceph3

#### D.8. Khởi tạo  mon
    ceph-deploy mon create-initial
				
#### D.9. Format các phân vùng dành cho CEPH về định dạng xfs
    ceph-deploy disk zap --fs-type xfs ceph1:sdb ceph2:sdb ceph3:sdb
	
#### D.10. Khởi tạo các phân vùng trên thành các OSD cho CEPH
    ceph-deploy --verbose osd prepare ceph1:sdb:/dev/sdc1 ceph2:sdb:/dev/sdc1 ceph3:sdb:/dev/sdc1
    ceph-deploy --verbose osd activate ceph1:sdb1:/dev/sdc1 ceph2:sdb1:/dev/sdc1 ceph3:sdb1:/dev/sdc1
	
#### D.11. Copy admin key và file config sang các node CEPH khác
    ceph-deploy admin ceph1 ceph2 ceph3
    chmod +r /etc/ceph/ceph.client.admin.keyring
	
#### D.12. Kiểm tra trạng thái của CEPH
    ceph health
    ceph status
    ceph osd tree
	
#### D.13. Tạo các OSD
    ceph osd pool create volumes 100
    ceph osd pool create images 100
    ceph osd pool create vms 100
	
### E. Thực hiện trên CEPH 2 và CEPH3
    Thay đổi quyền cho admin key vừa lấy
    chmod +r /etc/ceph/ceph.client.admin.keyring
	
### F. Đặt CEPH làm backend cho OpenStack
#### F.1. Tạo thư mục /etc/ceph trên node OpenStack
    mkdir /etc/ceph
	
#### F.2. Trên CEPH1 chuyển file ceph.conf sang máy OpenStack
    ssh root@20.20.20.51 sudo tee /etc/ceph/ceph.conf </etc/ceph/ceph.conf
	
#### F.3. Trên CEPH1, tạo các user cho nova,cinder và glance
    ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images'
    ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'
	
#### F.4. Trên CEPH1, Add các keyring cho client.cinder, client.glance đến node OpenStack
    ceph auth get-or-create client.glance | ssh root@20.20.20.51 sudo tee /etc/ceph/ceph.client.glance.keyring
    ssh root@20.20.20.51 sudo chown glance:glance /etc/ceph/ceph.client.glance.keyring
    ceph auth get-or-create client.cinder | ssh root@20.20.20.51 sudo tee /etc/ceph/ceph.client.cinder.keyring
    ssh root@20.20.20.51 sudo chown cinder:cinder /etc/ceph/ceph.client.cinder.keyring

#### F.5. Trên CEPH1, Tạo client.key cho Cinder  
    ceph auth get-key client.cinder | ssh root@20.20.20.51 tee client.cinder.key
	
#### F.6. Trên node OpenStack, chạy lệnh
    apt-get update && sudo apt-get install ceph-common python-ceph glance python-glanceclient
    cd /root
    uuidgen
	
#### F.7. Lấy key sinh ra ở lệnh trên để thay vao [key_gen]
    cat > secret.xml <<EOF
    <secret ephemeral='no' private='no'>
      <uuid>[key_gen]</uuid>
      <usage type='ceph'>
        <name>client.cinder secret</name>
      </usage>
    </secret>
    EOF
#### F.8. Set key
    virsh secret-define --file secret.xml
	
#### F.9. Đặt giá trị cho key
    virsh secret-set-value --secret [key_gen] --base64 $(cat client.cinder.key)
	
#### F.10. Thêm vào file /etc/glance/glance-api.conf
    default_store=rbd
    rbd_store_user=glance
    rbd_store_pool=images
    show_image_direct_url=True
	
Bỏ dòng:
    default_store = file
	
#### F.11. Thêm vào file /etc/cinder/cinder.conf
    volume_driver=cinder.volume.drivers.rbd.RBDDriver
    rbd_pool=volumes
    rbd_ceph_conf=/etc/ceph/ceph.conf
    rbd_flatten_volume_from_snapshot=false
    rbd_max_clone_depth=5
    glance_api_version=2
    rbd_user=cinder
    rbd_secret_uuid=[key_gen]
	
#### F.12. Thêm vào file /etc/nova/nova.conf
    libvirt_images_type=rbd
    libvirt_images_rbd_pool=vms
    libvirt_images_rbd_ceph_conf=/etc/ceph/ceph.conf
    rbd_user=cinder
    rbd_secret_uuid=[key_gen]
  
#### F.13. Khởi động lại các dịch vụ
    cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; cd;done
    cd /etc/init.d/; for i in $( ls glance-* ); do sudo service $i restart; cd;done
    cd /etc/init.d/; for i in $( ls cinder-* ); do sudo service $i restart; cd;done
	
#### F.14. Thử up image lên glance và tạo volume trên cinder, sau đó kiểm tra trên CEPH1
    rbd -p volumes ls
    rbd -p images ls
	
#### F.15. Tắt 1 node CEPH bất kì và tạo volume lại
   