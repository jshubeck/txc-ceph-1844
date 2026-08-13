#!/bin/bash

echo "Running lab-start-1844.sh now . . ."

# Expand the cluster
echo "Expanding the Ceph cluster from one (1) to four (4) nodes . . . "
for i in {2..4}; do
ssh -q ceph-node1 sudo ceph orch host add `grep node${i} /etc/hosts | awk '$2 ~ /^ceph-node/ {print $2, $1}'`
done

# Label the RGW nodes
echo "Labeling Ceph Node 3 and Node 4 for RGW services . . . "
ssh -q ceph-node1 sudo ceph orch host label add `grep node3 /etc/hosts | awk '$2 ~ /^ceph-node/ {print $2}'` rgw
ssh -q ceph-node1 sudo ceph orch host label add `grep node4 /etc/hosts | awk '$2 ~ /^ceph-node/ {print $2}'` rgw

# Add the OSDs
echo "Expanding the cluster capacity with OSD devices . . . "
ssh -q ceph-node1 sudo ceph orch apply osd --all-available-devices
until ssh -q ceph-node1 sudo ceph osd stat -f json | jq -e '.num_up_osds == 16 and .num_in_osds == 16' > /dev/null; do
  echo "Waiting for 16 OSDs to be up and in..."
  sleep 15
  ssh -q ceph-node1 sudo ceph osd stat
done
echo "All 16 OSDs are up and in."

# Setting placement for three Ceph MON daemons
# echo "Setting the Ceph MON daemon count to 3 . . ."
ssh -q ceph-node1 sudo ceph orch apply mon --placement "3"

# Launch the RGW services
echo "Waiting 30 seconds for OSDs to start . . ."
sleep 30
echo "Starting the RADOS Gateway (RGW) daemon on Node 3 and Node 4 . . . "
ssh -q ceph-node1 sudo ceph orch apply rgw s3service --placement "label:rgw"

echo "Done."
