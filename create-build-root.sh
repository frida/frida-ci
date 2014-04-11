#! /bin/bash -e

unset LC_CTYPE LC_MESSAGES LC_ALL

function info {
        echo -e "\033[1;32m$*\033[0m"
}

function warn {
        echo -e "\033[1;33m$*\033[0m"
}

if [ $(whoami) != "root" ] ; then
  warn "must be root"
  exit 1
fi

CHROOT=`pwd`/buildroot
BASE_HOSTNAME=buildserver

export DEBIAN_FRONTEND=noninteractive

if [ -d "$CHROOT" ]; then
        warn "Deleting old directory $CHROOT"
        rm -Rf $CHROOT
fi


info "Creating new base directory $CHROOT"
mkdir $CHROOT

debootstrap squeeze $CHROOT http://ftp.debian.org/debian

echo $PXE_HOSTNAME > $CHROOT/etc/hostname

cat <<EOT > $CHROOT/etc/fstab
/proc	/proc		proc	defaults		0 0
/sys	/sys		sysfs	defaults		0 0
devpts	/dev/pts	devpts	gid=5,mode=620		0 0
none	/tmp		tmpfs	defaults		0 0
none	/var/lock	tmpfs	defaults		0 0
none	/var/tmp	tmpfs	defaults		0 0
none	/dev/shm	tmpfs	rw,nosuid,nodev,noexec	0 0
EOT

mount -o bind /proc $CHROOT/proc
mount -o bind /dev/pts $CHROOT/dev/pts

#sed "s|%sudo.*|%sudo ALL=(ALL:ALL) NOPASSWD: ALL|g" -i $CHROOT/etc/sudoers
echo iface eth0 inet manual >> $CHROOT/etc/network/interfaces

rm -f $CHROOT/etc/mtab
chroot $CHROOT ln -sf /proc/mounts /etc/mtab
chroot $CHROOT apt-get -o Dpkg::Options::="--force-confnew" --force-yes -fuy install build-essential gcc git sudo flex bison libglib2.0-dev
# FIXME: python3.3 is installed by hand
# FIXME: setuptools for 2.6, 2.7 and 3.3 is installed by hand
chroot $CHROOT useradd --create-home --user-group --groups adm,sudo -s /bin/bash --skel /etc/skel frida

umount $CHROOT/proc
umount $CHROOT/dev/pts
