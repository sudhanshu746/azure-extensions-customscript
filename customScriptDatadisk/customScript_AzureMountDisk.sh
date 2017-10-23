#!/bin/bash -xv

#-----
MKDIR=/bin/mkdir
LSBLK=/bin/lsblk
CHMOD=/bin/chmod
MOUNT=/bin/mount
MKFS=/sbin/mkfs

ALL_DATA_DISKS=$($LSBLK --nodeps -n -o NAME,TYPE,MAJ:MIN|awk '{split($NF,a,":"); if(a[2] >= 32 && $2 == "disk") print $1;}')

CONF_FILE='/etc/init/mount-data-disk.conf'

INCR=0
if test -s ${CONF_FILE};then
echo "upstart config file already created"
exit;
else
cat <<EOF >> $CONF_FILE
# mount CIFS share

start on filesystem  and net-device-up IFACE!=lo
stop on runlevel [!2345]

pre-start script
EOF
fi

for disk in ${ALL_DATA_DISKS};do
if [ -z "$($MOUNT|grep ${disk})" ]; then
		MOUNT_DIR="/mnt/data0${INCR}"
		MOUNT_CMD="/bin/mount -t ext4 /dev/${disk} $MOUNT_DIR"
		MOUNT_DIR="/MNT/DATA0${INCR}"
		# Creating mount directory with permission
		$MKDIR ${MOUNT_DIR} && $CHMOD -R 755 ${MOUNT_DIR} ;
		# Format disk with EXT4 filesystem
		echo y | $MKFS -t ext4 /dev/${disk}
		## Mount
		$MOUNT_CMD
cat <<EOF >> $CONF_FILE
${MOUNT_CMD}
EOF
fi
INCR=$(expr $INCR + 1)
done
cat <<EOF >> $CONF_FILE
end script
EOF

#------

