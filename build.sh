#!/bin/bash

VERSION=0.8
DISTRO="ubuntu"
RELEASE="focal"
MIRROR=""
IMGSIZE="16"
IMGVER="`date '+%Y%m%d'`-$DISTRO-$RELEASE"
BUILDDIR="./build"
IMGSTOR="${BUILDDIR}/image"
TMPDIR="${BUILDDIR}/tmp"
BOXIMG="box.img"
BOXFMT="raw"
PUSH=NO
CLEAN=NO
SECONDS=0

trap KillScript SIGHUP SIGINT SIGTERM

Usage() {
	echo
	echo -e "D3nver Root Base Image builder ${IMGVER}"
	echo -e "Author: Walid Moghrabi <walid.moghrabi@lezard-visuel.com>"
	echo
	echo -e "This script ease the creation of D3nver RBI"
	echo
	echo -e "Usage: \e[1m$1 [OPTION]\e[0m"
	echo
	echo -e "\e[1mOptions\e[0m"
	echo -e " -h, --help                        Show this help"
	echo -e " -c, --create <DISTRO>:<RELEASE>   Create a new image (default: $DISTRO:$RELEASE)"
	echo -e " -s, --size <SIZE>                 Size of the image in GB (default: $IMGSIZE)"
	echo -e " -m, --mirror <MIRROR URL>         Mirror URL"
	echo -e " -p, --push <beta|stable>          Automatically push to beta/stable channel when done"
	echo -e " -x, --clean                       Clean build data once image is pushed"
}

ChrootMount() {
	mount --bind /proc ${TMPDIR}/rootfs/proc
	mount --bind /dev ${TMPDIR}/rootfs/dev
	mount --bind /sys ${TMPDIR}/rootfs/sys
}

ChrootUmount() {
	umount -f ${TMPDIR}/rootfs/sys
	umount -f ${TMPDIR}/rootfs/dev
	umount -f ${TMPDIR}/rootfs/proc
	umount -f ${TMPDIR}/rootfs
}

KillScript() {
	sleep 5
	ChrootUmount
	sleep 5
	exit 2
}

CheckDeps() {
	local TOOLS=(
		ansible-playbook
		aws
		debootstrap
		lbzip2
		mount
		modprobe
		qemu-img
		qemu-nbd
		rsync
		sfdisk
		tune2fs
	)

	for tool in ${TOOLS[@]}; do
		command -v $tool >/dev/null 2>&1 || { echo >&2 "$tool not installed.  Aborting."; exit 2; }
	done
}

###############################################################################
# Various checks                                                              #
###############################################################################
# Check for run as zimbra user
ID=`id -u -n`
if [ x$ID != "xroot" ]; then
	echo "Please use sudo or run as ROOT user"
	echo "Exiting..."
	exit $ERROR_INCORRECT_PARAM
fi


# no arguments, leave
if [[ $# -lt 1 ]]; then
	Usage $0
	exit $ERROR_INCORRECT_PARAM
fi

###############################################################################
# Main loop                                                                   #
###############################################################################
# Execute getopt on the arguments passed to this program, identified by the special character $@
PARSED_OPTIONS=$(getopt -n "$0"  -o hc:s:m:p:x --long "help,create:,size:,mirror:,push:,clean"  -- "$@")

#Bad arguments, something has gone wrong with the getopt command.
if [ $? -ne 0 ] ; then
	Usage $0
	exit $ERROR_INCORRECT_PARAM
fi

# A little magic, necessary when using getopt.
eval set -- "$PARSED_OPTIONS"

# Now goes through all the options with a case and using shift to analyse 1 argument at a time.
while true ; do
	case "$1" in

		-h|--help)
			Usage $0
			exit 0
			shift;;

		-c|--create)
			DISTRO=`echo $2 | awk -F ":" '{print $1}'`
			RELEASE=`echo $2 | awk -F ":" '{print $2}'`
			IMGVER="`date '+%Y%m%d'`-$DISTRO-$RELEASE"
			shift 2;;

		-s|--size)
			IMGSIZE=$2
			shift 2;;

		-m|--mirror)
			MIRROR=$2
			shift 2;;

		-p|--push)
			PUSH=YES
			CHANNEL=$2
			shift 2;;

		-x|--clean)
			CLEAN=YES
			shift;;

		--)
			shift
			break;;
	esac
done

# Check that all the required tools are installed
CheckDeps

[[ ! -d ${TMPDIR} ]] && mkdir -p ${TMPDIR}
if [[ -d ${TMPDIR}/rootfs} ]]; then
	ChrootUmount
	rm -rf ${TMPDIR}/rootfs
fi

[[ ! -d ${TMPDIR}/rootfs ]] && mkdir -p ${TMPDIR}/rootfs
[[ -d ${IMGSTOR}/${IMGVER} ]] && rm -rf ${IMGSTOR}/${IMGVER}
mkdir -p ${IMGSTOR}/${IMGVER}

modprobe nbd max_part=4
qemu-img create -f ${BOXFMT} ${IMGSTOR}/${IMGVER}/${BOXIMG} ${IMGSIZE}G
qemu-nbd -c /dev/nbd0 -f ${BOXFMT} ${IMGSTOR}/${IMGVER}/${BOXIMG}
sleep 2
sfdisk /dev/nbd0 <<EOF
,1024000,82
;
EOF

mkswap /dev/nbd0p1
mkfs.ext4 /dev/nbd0p2
tune2fs -o journal_data_writeback /dev/nbd0p2
e2fsck -fy -E discard /dev/nbd0p2
sleep 2
mount -t ext4 /dev/nbd0p2 ${TMPDIR}/rootfs

debootstrap --arch amd64 --variant=minbase --include=python3,python3-apt,sudo ${RELEASE} ${TMPDIR}/rootfs $MIRROR

ChrootMount

ansible-playbook -c chroot -i "${TMPDIR}/rootfs," ansible/playbook.yml

ANSIBLE_STATUS=$?
echo "Ansible status : $ANSIBLE_STATUS"

ChrootUmount

e2fsck -fy -E discard /dev/nbd0p2
sleep 2
qemu-nbd --disconnect /dev/nbd0
sleep 2
rmmod nbd

if [[ $ANSIBLE_STATUS -gt 0 ]]; then
	echo
	echo -e "\e[1m#####\e[0m D3nver RBI build process failed ! \e[1m#####\e[0m"
	exit 2
fi

############ VIRTUALBOX SUPPORT #########################################
echo
echo -ne "Converting image to VirtualBox format ..."
mkdir -p ${IMGSTOR}/${IMGVER}/virtualbox
qemu-img convert -O vdi ${IMGSTOR}/${IMGVER}/${BOXIMG} ${IMGSTOR}/${IMGVER}/virtualbox/box.vdi
CONVERTEDSIZE=`wc -c < ${IMGSTOR}/${IMGVER}/virtualbox/box.vdi`
echo " [DONE]"

echo -ne "Compressing image ..."
lbzip2 ${IMGSTOR}/${IMGVER}/virtualbox/box.vdi
COMPRESSEDSIZE=`wc -c < ${IMGSTOR}/${IMGVER}/virtualbox/box.vdi.bz2`
echo " [DONE]"

echo -ne "Writing manifest file ..."
echo "{
  \"version\": \"${IMGVER}\",
  \"sha256sum\": \"`sha256sum -b ${IMGSTOR}/${IMGVER}/virtualbox/box.vdi.bz2 | awk '{print $1}'`\",
  \"imagesize\": ${IMGSIZE},
  \"filesize\": ${CONVERTEDSIZE},
  \"compressedsize\": ${COMPRESSEDSIZE}
}" > ${IMGSTOR}/${IMGVER}/virtualbox/manifest.json
echo " [DONE]"


############ KVM SUPPORT #########################################
#echo
#echo -ne "Converting image to KVM/QCOW2 format ..."
#mkdir -p ${IMGSTOR}/${IMGVER}/kvm
#qemu-img convert -O qcow2 ${IMGSTOR}/${IMGVER}/${BOXIMG} ${IMGSTOR}/${IMGVER}/kvm/box.qcow2
#CONVERTEDSIZE=`wc -c < ${IMGSTOR}/${IMGVER}/kvm/box.qcow2`
#echo " [DONE]"

#echo -ne "Compressing image ..."
#lbzip2 ${IMGSTOR}/${IMGVER}/kvm/box.qcow2
#COMPRESSEDSIZE=`wc -c < ${IMGSTOR}/${IMGVER}/kvm/box.qcow2.bz2`
#echo " [DONE]"

#echo -ne "Writing manifest file ..."
#echo "{
#  \"version\": \"${IMGVER}\",
#  \"sha256sum\": \"`sha256sum -b ${IMGSTOR}/${IMGVER}/kvm/box.qcow2.bz2 | awk '{print $1}'`\",
#  \"imagesize\": ${IMGSIZE},
#  \"filesize\": ${CONVERTEDSIZE},
#""  \"compressedsize\": ${COMPRESSEDSIZE}
#}" > ${IMGSTOR}/${IMGVER}/kvm/manifest.json
#echo " [DONE]"

echo
echo "========== CLEANUP =============="
rm -f ${IMGSTOR}/${IMGVER}/${BOXIMG}

if [[ -n $SUDO_USER ]]; then
	chown -R $SUDO_UID:$SUDO_GID ${BUILDDIR}
else
	chown -R $UID:$GID ${BUILDDIR}
fi

duration=$SECONDS
processtime=`echo "$(($duration / 60))m $(($duration % 60))s"`
echo -e "Build done !\nSTART: ${START}\n  END: `date`"
echo -e "\e[1m#####\e[0m D3nver image processed in ${processtime}\e[1m#####\e[0m"

if [[ "$PUSH" == "NO" ]]; then
	echo
	read -p "Do you want to publish this image to BETA channel now ? y/N " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		echo -e "New image not published and available at ${IMGSTOR}/${IMGVER}\n"
		exit 0
	fi

	./push.sh ${IMGSTOR}/${IMGVER} beta

	echo
	echo -e "\e[1m#####\e[0m D3nver image ${IMGSTOR}/${IMGVER} has been published to the BETA channel\e[1m#####\e[0m"
else
	./push.sh ${IMGSTOR}/${IMGVER} $CHANNEL
fi

if [[ "$CLEAN" == "YES" ]]; then
	rm -rf build
	echo
	echo -e "\e[1m#####\e[0m [CLEAN] : Temporary files removed\e[1m#####\e[0m"
fi
