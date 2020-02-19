#!/bin/bash

DEVICE="/dev/sdb"

echo "Checking if userdata PV exist ..."

if [[ `pvs $DEVICE &> /dev/null; echo $?` -ne 0 ]]; then
	echo "==> user data PV does not exist"

	echo "==> Checking if userdata device exist ..."

	if [[ `lsblk $DEVICE &> /dev/null; echo $?` -ne 0 ]]; then
		echo "====> user data device does not exist"
	else
		echo "====> user data device exist"
		echo "====> Creating user data PV ..."
		pvcreate $DEVICE
		echo "====> Creating user data VG ..."
		vgcreate vg0 $DEVICE
		echo "====> Creating user data LV ..."
		lvcreate -n home -l 100%VG vg0
		echo "====> Creating user data volume ..."
		mkfs.ext4 /dev/vg0/home
		echo "====> Mounting user data volume on temporary location ..."
		if [[ -d /tmp/userdata ]]; then
			umount -f /tmp/userdata &> /dev/null
		else
			mkdir -p /tmp/userdata
		fi
		mount /dev/vg0/home /tmp/userdata
		echo "====> Copy ldevuser home to user data volume ..."
		cp -a /home/ldevuser /tmp/userdata
		echo "====> Unmounting user data volume on temporary location ..."
		if [[ `umount -f /tmp/userdata &> /dev/null` -ne 0 ]]; then
			echo "!!ERROR!!"
			exit 2
		else
			echo "====> Mounting user data volume on /home ..."
			umount -f /home &> /dev/null
			mount -t ext4 -o defaults,data=writeback,noatime,nodiratime /dev/vg0/home /home
		fi
	fi
else
	echo "==> user data PV exist"

	echo "==> Checking if user data VG exist"
	if [[ `vgs vg0 &> /dev/null; echo $?` -ne 0 ]]; then
		echo "!!ERROR!!"
		exit 2
	else
		echo "===> user data VG exist"

		echo "===> Checking if user data LV exist"
		if [[ `lvs vg0 | grep home &> /dev/null; echo $?` -ne 0 ]]; then
			echo "!!ERROR!!"
			exit 2
		else
			echo "====> user data VG exist"

			echo "====> Mounting user data volume on /home ..."
			umount -f /home &> /dev/null
			mount -t ext4 -o defaults,data=writeback,noatime,nodiratime /dev/vg0/home /home
		fi
	fi
fi

echo "===== DONE ====="
exit 0
