#!/bin/bash
# 디스크 쿼터 설정 (10GB 디스크, /userHome)

# 1. 디스크 확인 및 파티션 생성
lsblk
fdisk /dev/sdb
mkfs.ext4 /dev/sdb1
mkdir /userHome
mount /dev/sdb1 /userHome

# 2. fstab에 쿼터 옵션 추가 후 재적용
# /dev/sdb1  /userHome  ext4  defaults,usrjquota=aquota.user,jqfmt=vfsv0  0 0
mount --options remount /userHome

# 3. 사용자 생성
useradd -d /userHome/aespa aespa
useradd -d /userHome/IVE IVE
useradd -d /userHome/NewJeans NewJeans
passwd aespa
passwd IVE
passwd NewJeans

# 4. 쿼터 DB 생성
cd /userHome
quotaoff -avug
quotacheck -augmn
rm -rf aquota.*
touch aquota.user aquota.group
chmod 600 aquota.*
quotacheck -augmn
quotaon -avug

# 5. 사용자별 쿼터 설정 (soft 700M, hard 1G)
edquota -u aespa
edquota -u IVE
edquota -u NewJeans

# 6. 쿼터 설정 복제 (aespa -> IVE -> NewJeans)
edquota -p aespa IVE
edquota -p IVE NewJeans

# 7. 검증
quota -u aespa
repquota /userHome
