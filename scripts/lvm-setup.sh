#!/bin/bash
# 디스크 추가 후 LVM 구성

# 1. 디스크 확인
lsblk
fdisk -l | grep sd

# 2. 파티션 할당 (sdb 20G, sdc 30G, sdd 50G, 타입 8e)
fdisk /dev/sdb
fdisk /dev/sdc
fdisk /dev/sdd

# 3. PV 구성
pvcreate /dev/sdb1
pvcreate /dev/sdc1
pvcreate /dev/sdd1
pvscan

# 4. VG 구성
vgcreate DATA /dev/sdb1 /dev/sdc1 /dev/sdd1
vgdisplay

# 5. LV 구성
lvcreate --size 40G --name VIDEO DATA
lvcreate --extents 100%FREE --name AUDIO DATA
lvscan

# 6. 파일시스템 생성
mkfs.ext4 /dev/DATA/VIDEO
mkfs.ext4 /dev/DATA/AUDIO

# 7. 마운트
mkdir /lvm1 /lvm2
mount /dev/DATA/VIDEO /lvm1
mount /dev/DATA/AUDIO /lvm2

# 8. fstab 등록 (영구 마운트)
echo "/dev/DATA/VIDEO /lvm1 ext4 defaults 0 0" >> /etc/fstab
echo "/dev/DATA/AUDIO /lvm2 ext4 defaults 0 0" >> /etc/fstab
