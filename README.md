# Rocky Linux LVM & Disk Quota Project

4인 팀 Linux 실습에서 디스크 추가 후 LVM 구성, 디스크 쿼터 설정 파트를 담당했습니다.

---

## 담당 범위

- 물리 디스크 추가 및 파티션 할당 (fdisk)
- LVM 구성 (PV → VG → LV)
- 파일시스템 생성 및 마운트, fstab 등록
- 사용자별 디스크 쿼터(quota) 설정 및 검증

---

## 1. LVM 구성

### 구성 개요

20GB, 30GB, 50GB 물리 디스크 3개를 하나의 Volume Group(DATA)으로 묶고, 그 안에 VIDEO(40G)와 AUDIO(나머지 전체) 두 개의 Logical Volume으로 분리했습니다.

    DATA (Volume Group, ~100GiB)
    ├── VIDEO (Logical Volume, 40G)
    └── AUDIO (Logical Volume, 나머지 전체)
         ↑
    PV: /dev/sdb1(20G) + /dev/sdc1(30G) + /dev/sdd1(50G)

### 절차

[lvm-setup.sh](scripts/lvm-setup.sh) 참고

1. `fdisk`로 sdb, sdc, sdd 각각 파티션 생성 (타입 `8e` Linux LVM)
2. `pvcreate`로 Physical Volume 3개 생성
3. `vgcreate`로 Volume Group `DATA` 생성 (3개 PV 통합, 총 용량 약 99.99GiB)
4. `lvcreate`로 Logical Volume `VIDEO`(40G), `AUDIO`(나머지 전체) 생성
5. `mkfs.ext4`로 파일시스템 생성 후 `/lvm1`, `/lvm2`에 마운트
6. `/etc/fstab`에 등록해 재부팅 후에도 유지되도록 설정

### 검증 결과

**VG 구성 확인 (vgdisplay)**

    VG Name               DATA
    Format                lvm2
    VG Access             read/write
    Cur PV                3
    Act PV                3
    VG Size                <99.99 GiB

**LV 생성 및 활성화 확인 (lvscan)**

    ACTIVE            '/dev/DATA/VIDEO' [40.00 GiB] inherit
    ACTIVE            '/dev/DATA/AUDIO' [<59.99 GiB] inherit

**마운트 확인 (df)**

    Filesystem               1K-blocks   Used Available Use% Mounted on
    /dev/mapper/DATA-VIDEO    40973536     24  38859976   1% /lvm1
    /dev/mapper/DATA-AUDIO    61599532     24  58438012   1% /lvm2

---

## 2. 디스크 쿼터 설정

### 구성 개요

10GB 디스크를 `/userHome`에 마운트하고, aespa·IVE·NewJeans 3개 사용자 계정에 각각 soft 700M / hard 1G 쿼터를 설정했습니다.

### 절차

[quota-setup.sh](scripts/quota-setup.sh) 참고

1. 10GB 디스크 파티션 생성 후 `/userHome`에 마운트
2. `/etc/fstab`에 `usrjquota=aquota.user,jqfmt=vfsv0` 옵션 추가 후 remount
3. `useradd`로 3개 사용자 계정 생성
4. `quotacheck`, `quotaon`으로 쿼터 DB 초기화
5. `edquota -u`로 사용자별 soft 700M / hard 1G 쿼터 설정
6. `edquota -p`로 설정된 쿼터를 다른 사용자에게 그대로 복제 적용

### 검증 결과

**쿼터 설정 확인 (quota 명령)**

    Disk quotas for user aespa (uid 1009):
         Filesystem  blocks   quota   limit   grace
         /dev/sdb1     1000*    700    1000   6days

**쿼터 초과 시 실제 차단 동작 확인**

    sdb1: warning, user block quota exceeded.
    sdb1: write failed, user block limit reached.
    cp: 'test1'에 쓰는 도중 오류 발생: 디스크 할당량이 초과됨
    cp: error copying 'test1' to 'test2': 디스크 할당량이 초과됨

hard limit(1G)을 초과하는 파일 복사 시도 시 실제로 쓰기가 차단되는 것까지 확인했습니다.

**전체 사용자 쿼터 현황 확인 (repquota)**

    User            used    soft    hard   grace
    aespa    +-      1000     700    1000  6days
    IVE      +-      1000     700    1000  6days
    NewJeans +-      1000     700    1000  6days

---

