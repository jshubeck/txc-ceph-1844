#!/bin/bash

# Expand the cluster
echo "Expanding the Ceph cluster from one (1) to four (4) nodes . . . "
for i in {2..4}; do
ssh -q ceph-node1 sudo ceph orch host add `grep node${i} /etc/hosts | awk '$2 ~ /^ceph-node/ {print $2, $1}'`
done

# Label the RGW nodes
echo "Labeling Ceph Node 3 and Node 4 for RGW services . . . "
ssh -q ceph-node1 sudo ceph orch host label add `grep node3 /etc/hosts | awk '$2 ~ /^ceph-node/ {print $2}'` rgw
ssh -q ceph-node1 sudo ceph orch host label add `grep node4 /etc/hosts | awk '$2 ~ /^ceph-node/ {print $2}'` rgw


echo "Creating RCLONE configuration profile for IBM Cloud . . ."
export AKEY=3275e5e91ce34e6db76c3e6b80615a44
export SKEY=f4d6d85d1a5b8b259029b25bf7e5ca449f63deeaf885b997
rclone config create ibmcloud s3 provider IBMCOS \
endpoint=s3.us.cloud-object-storage.appdomain.cloud \
access_key_id=$AKEY secret_access_key=$SKEY \
acl=private > /dev/null 2>&1

echo "Copying lab files from IBM Cloud to the local workstation . .  ."
rclone copy ibmcloud:txc-lab1844-files/Pictures  Pictures -q
rclone copy ibmcloud:txc-lab1844-files/Documents Documents -q

echo "Creating binary test files in the 'Binaries' directory now . . ."
mkdir -p Binaries
for i in {1..5}; 
do
	dd if=/dev/random of=Binaries/${i}MB-file.bin bs=1M count=$i status=none
done

#
# USE THIS ONE!!!
#
for i in {2..4}; do
echo ceph orch host add `grep node${i} /etc/hosts | awk '$2 ~ /^ceph-node/ {print $2, $1}'`
done

#
# ADD THE OSDS
#
cephadm shell -- ceph orch apply osd --all-available-devices

#
# START THE RGW SERVICE
#
ceph orch host label add `grep node3 /etc/hosts | awk '$2 ~ /^ceph-node/ {print $2}'` rgw
ceph orch apply rgw s3service --placement "label:rgw"

