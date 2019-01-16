#!/bin/bash

IMAGE_URL="https://downloads.raspberrypi.org/raspbian_lite_latest"
DOWNLOAD_DIR="/home/$USER/Downloads"
if [ ! -d "$DOWNLOAD_DIR" ]; then
   DOWNLOAD_DIR=$(pwd)
fi

while getopts ":a:d:e:s" opt; do
   case ${opt} in
      a )
	 SSH_KEY=$OPTARG
	 ;;
      d )
	 DEVICE=$OPTARG
	 ;;
      e)
	 ESSID=$OPTARG
	 ;;
      s)
	 DRYRUN=1
	 ;;
      \?)
	 echo "Invalid option: -$OPTARG" 1>&2
	 exit
	 ;;
      : )
	 echo "Invalid option: -$OPTARG requires an argument" 1>&2
	 exit
	 ;;
   esac
done

shift $((OPTIND-1))
HOSTS=("$@")

if [ -z "${HOSTS[0]}" ] || [ -z "$DEVICE" ]; then
   echo "Usage: $0 -d usb_device -e essid hostname(s)"
   exit
fi

echo
echo "Preparing Raspbian image..."
echo
echo "wget -q --server-response --trust-server-names -P $DOWNLOAD_DIR -N $IMAGE_URL"
WGET_OUTPUT=$(wget -q --server-response --trust-server-names -P "$DOWNLOAD_DIR" -N "$IMAGE_URL" 2>&1)
ZIP_FILE=$(echo "$WGET_OUTPUT" | grep -m1 Location | sed s/.*\\///g)
IMG_FILE=${ZIP_FILE/\.zip/\.img}
if [ -z "$DRYRUN" ]
then
   unzip "$DOWNLOAD_DIR/$ZIP_FILE" -d "$DOWNLOAD_DIR"
fi

echo
echo "Finding image partition offsets..."
echo
UNITS=$(sudo fdisk -l "$DOWNLOAD_DIR/$IMG_FILE" | awk 'NR==2 {print $8}')
BOOT_OFFSET=$(sudo fdisk -l "$DOWNLOAD_DIR/$IMG_FILE" | awk 'NR==9 {print $2}')
ROOTFS_OFFSET=$(sudo fdisk -l "$DOWNLOAD_DIR/$IMG_FILE" | awk 'NR==10 {print $2}')

TMP_DIR=$(mktemp -d)

echo "Preparing boot/ partition..."
BOOT_DIR=$TMP_DIR/boot
mkdir "$BOOT_DIR"
echo "sudo mount -o loop,offset=$(( UNITS * BOOT_OFFSET )) $DOWNLOAD_DIR/$IMG_FILE $BOOT_DIR"
sudo mount -o loop,offset=$(( UNITS * BOOT_OFFSET )) "$DOWNLOAD_DIR/$IMG_FILE" "$BOOT_DIR"

echo "Enabling SSH..."
echo "sudo touch $BOOT_DIR/ssh"
sudo touch "$BOOT_DIR/ssh"

if [ -n "$ESSID" ]
then
   if [ -z "$PASSWORD" ]
   then
      echo
      echo "Creating $BOOT_DIR/wpa_supplicant.conf..."
      echo
      read -r -p "Enter wireless password: " -s PASSWORD
      echo
   fi
   cat << EOF | sudo tee "$BOOT_DIR/wpa_supplicant.conf" > /dev/null
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="$ESSID"
    scan_ssid=1
    psk="$PASSWORD"
    key_mgmt=WPA-PSK
 }
EOF
else
   echo "No ESSID provided -- not setting up wifi."
fi

echo
echo "sudo umount $BOOT_DIR"
sudo umount "$BOOT_DIR"
echo "sudo rmdir $BOOT_DIR"
sudo rmdir "$BOOT_DIR"

ROOTFS_DIR=$TMP_DIR/rootfs
mkdir "$ROOTFS_DIR"

for HOST in "${HOSTS[@]}"; do
   echo
   echo "($HOST): Preparing rootfs/ partition..."
   echo "($HOST): sudo mount -o loop,offset=$(( UNITS * ROOTFS_OFFSET )) $DOWNLOAD_DIR/$IMG_FILE $ROOTFS_DIR"
   sudo mount -o loop,offset=$(( UNITS * ROOTFS_OFFSET )) "$DOWNLOAD_DIR/$IMG_FILE" "$ROOTFS_DIR"
   echo "($HOST): Setting hostname"
   echo "$HOST" | sudo tee "$ROOTFS_DIR/etc/hostname" > /dev/null
   if [ -n "$SSH_KEY" ]; then
      echo "($HOST): sudo mkdir $ROOTFS_DIR/home/pi/.ssh"
      sudo mkdir "$ROOTFS_DIR/home/pi/.ssh"
      echo "($HOST): sudo cp $SSH_KEY $ROOTFS_DIR/home/pi/.ssh/authorized_keys"
      sudo cp "$SSH_KEY" "$ROOTFS_DIR/home/pi/.ssh/authorized_keys"
   fi
   echo "($HOST): sudo umount $ROOTFS_DIR"
   sudo umount "$ROOTFS_DIR"

   read -p "($HOST): Write $DOWNLOAD_DIR/$IMG_FILE to $DEVICE? " -n 1 -r
   echo
   if [[ $REPLY =~ ^[Yy]$ ]]
   then
      echo "($HOST): Making sure all sdcard partitions are unmounted..."
      for p in "${DEVICE}"* ; do sudo umount "$p" ; done
      echo "($HOST): Writing image to sdcard -- this could take a few minutes..."
      echo "($HOST): sudo dd if=$DOWNLOAD_DIR/$IMG_FILE of=$DEVICE bs=4M conv=fdatasync"
      if [[ -z "$DRYRUN" ]]
      then
	 sudo dd if="$DOWNLOAD_DIR/$IMG_FILE" of="$DEVICE" bs=4M conv=fdatasync
      fi
      echo "($HOST): done."
   else
      echo "sudo rmdir $ROOTFS_DIR"
      sudo rmdir "$ROOTFS_DIR"
      echo "sudo rmdir $TMP_DIR"
      sudo rmdir "$TMP_DIR"
      exit
   fi

done

echo
echo "sudo rmdir $ROOTFS_DIR"
sudo rmdir "$ROOTFS_DIR"
echo "sudo rmdir $TMP_DIR"
sudo rmdir "$TMP_DIR"
echo
