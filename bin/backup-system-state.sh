#!/bin/bash

# location of bash script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# read "local" settings
# contains:
#BACKUP_DEST="$HOME/Documents/Backup/$HOST"
#NEXTCLOUD_DEST="/opt/user/Nextcloud/Documents/IT/Backup/$HOST"
source $SCRIPT_DIR/$HOSTNAME.conf

OSNAME=$(grep ^NAME /etc/os-release | cut -d= -f 2)
HOST=$(hostname)

# backup system info and state
echo "Performing system state backup of $HOST to $BACKUP_DEST"
if [ ! -e $BACKUP_DEST ]; then
	mkdir -p $BACKUP_DEST
fi

if [ $OSNAME = "Fedora" ]
then
	echo "  + Fedora"
	echo "  - etc"
	rpm -qa > $BACKUP_DEST/fedora-packages
	cp -r /etc/yum.repos.d $BACKUP_DEST
fi

if [ $OSNAME = "Ubuntu" ]
then
	echo "  + Ubuntu"
	echo "  - etc"
	cp /etc/apt/sources.list $BACKUP_DEST/source.list.backup
	cp -r /etc/apt/sources.list.d $BACKUP_DEST
	apt-key exportall > $BACKUP_DEST/repositories.key
	dpkg --get-selections > $BACKUP_DEST/ubuntu-packages
	# can restore with: sudo dpkg --set-selections < $BACKUP_DEST/ubuntu-packages && sudo apt-get dselect-upgrade
fi

echo "  - hardware info"
sudo lshw -html > $BACKUP_DEST/hardware_info.html
udevadm info --export-db > $BACKUP_DEST/udevadm-info.txt
sudo dmidecode > $BACKUP_DEST/bios.txt

echo "  - cron"
crontab -l > $BACKUP_DEST/crontab.backup

echo "  - etc"
sudo tar czf $BACKUP_DEST/etc.tgz /etc
sudo chown edavison:edavison $BACKUP_DEST/etc.tgz

echo "  - ~/bin"
tar czf $BACKUP_DEST/bin.tgz $HOME/bin

echo "  - pip3"
pip3 freeze > $BACKUP_DEST/requirements.txt

echo "  - thunderbird"
if [ -d $HOME/.thunderbird ]
then
	tar czf $BACKUP_DEST/thunderbird.tgz $HOME/.thunderbird
fi

echo "  - sync to nextcloud"
rsync -pav $BACKUP_DEST $NEXTCLOUD_DEST

