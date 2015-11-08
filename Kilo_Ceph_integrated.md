# Hướng dẫn cài đặt CEPH làm backend cho OpenStack

### A. Mô hình LAB

![Alt text](http://i.imgur.com/recpCLC.jpg)

### B. Cài đặt OpenStack
Thực hiện theo hướng dẫn sau:
https://github.com/vietstacker/openstack-kilo-multinode-U14.04-v1


### C. Cài đặt Ceph
Chuẩn bị môi trường:
- 3 máy ảo chạy CentOS 6.5, kernel 2.6.32-504.23.4.el6.x86_64
- Disable iptables
- Các máy ảo có 3 card mạng tương ứng với các dải mạng Local, External và Replicate

####C.1. Truy cập bằng tài khoản root vào máy các máy chủ và tải các gói, script chuẩn bị cho quá trình cài đặt
	yum update
	yum install git -y
	git clone
	mv /root/https://github.com/longsube/CEPH_3Net_Openstack/Install_CephHammer_3node
	cd Install_CephHammer_3node/
	chmod +x *.sh

#### C.2. Cấu hình file config.cfg
Sửa các thông số sau:
- Hostname của các node
- IP các dải Local, External, Public của các node
- Password root của các node
- Các disk để sử dụng làm OSD của các node
- FSID: để sử dụng cho việc xác thực giữa các dịch vụ của Ceph
```
	#Hostname
	HOST1=ceph1
	HOST2=ceph2
	HOST3=ceph3
	#CON=controller
	#COM1=compute1
	#COM2=compute2

	#SUBNET
	LOCAL=192.168.20.0/24
	REPLICATE=192.168.10.0/24

	#IP EXTERNAL
	CEPH1_EXT=10.145.37.43
	CEPH2_EXT=10.145.37.45
	CEPH3_EXT=10.145.37.47

	#IP LOCAL
	CEPH1_LOCAL=192.168.20.43
	CEPH2_LOCAL=192.168.20.45
	CEPH3_LOCAL=192.168.20.47
	CON_LOCAL=192.168.20.44
	COM1_LOCAL=192.168.20.50
	COM2_LOCAL=192.168.20.62

	#IP REPLICATE
	CEPH1_REPLICATE=192.168.10.43
	CEPH2_REPLICATE=192.168.10.45 
	CEPH3_REPLICATE=192.168.10.47
```	
....

#### C.3. Cấu hình NIC, Hostname, update
Truy cập bằng quyền root vào các node 1, 2 ,3 và thực hiện tương ứng với từng node:
```
	cd /root/Install_CephHammer_3node/
    bash 01.prepare_node1.sh
    bash 01.prepare_node1.sh
    bash 01.prepare_node1.sh
```
Sau bước này, các node sẽ khởi động lại
	
#### C.4. Cài đặt các package của Ceph
Sau khi các node đã khởi động lên, truy cập vào node ceph1 với quyền root:
	cd /root/Install_CephHammer_3node/
	bash 04.install_Ceph_packages.sh
	
#### C.5. Cài đặt Ceph monitor trên các node
	bash 05.deploy_monitor.sh
    
#### C.6. Cài đặt Ceph OSD trên các node
    bash 06.deploy_OSD.sh

###D.Tích hợp Ceph với OpenStack
Các node OpenStack cho phép ssh với quyền root
####D.1 Thực hiện việc tải các package Ceph cho các node OpenStack và cấu hình
	bash 07.integrate_OpenStack.sh
	