#!/bin/sh

#REPOSITORY=borg@borgserver:/mnt/backup/repo1
REPOSITORY=edavison@10.211.1.5:/run/media/edavison/Data2000A/Backup/strider-repo

#Bail if borg is already running, maybe previous run didn't finish
if pidof -x borg >/dev/null; then
    echo "Backup already running"
    exit
fi

# Setting this, so you won't be asked for your repository passphrase:
export BORG_PASSPHRASE='The highlands of Scotland.'
# or this to ask an external program to supply the passphrase:
# export BORG_PASSCOMMAND='pass show backup'

# Backup all of /home and /var/www except a few
# excluded directories
borg create -v --stats                          \
    $REPOSITORY::'{hostname}-{now:%Y-%m-%d}'    \
    /home/edavison/Documents                                   \
    /home/edavison/.config                                   \
    /home/edavison/bin                                   \
    /home/edavison/Pictures                                   \

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machine's archives also.
borg prune -v --list $REPOSITORY --prefix '{hostname}-' \
    --keep-daily=7 --keep-weekly=4 --keep-monthly=6
