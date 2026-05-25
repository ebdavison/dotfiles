#!/bin/bash

set -e

die() {
  echo "$1" >&2
  echo "Exiting" >&2
  exit 1
}

host=$1
[ -z "$host" ] && die "Usage: $0 <host>"

ssh "$host" mkdir -p bin Files

cd ~ || die "cd ~ failed"

#rsync --exclude .git -avHxz .atoprc .bash_logout .bashrc.interactive .bashrc.d .bashrc.local .gitconfig .inputrc .tmux.conf .vimrc.d .vimrc.bundles .vimrc bin "$host":

#rsync --exclude .git -avHxz .vim/bundle "$host":.vim/

ssh  -t "$host" mkdir -p .terminfo/x
rsync --rsh "ssh -T" --rsync-path 'rsync' /usr/share/terminfo/x/xterm-ghostty "$host":.terminfo/x/
ssh  -t "$host" chmod 444 .terminfo/x/xterm-ghostty

#ssh -t "$host" bin/fix-bashrc

#rsync --exclude .git /usr/share/terminfo/{s/screen,x/xterm,t/tmux,r/rxvt-unicode}-256color "$host":Files/
# for i in xterm-ghostty screen xterm rxvt-unicode
# do
#   ssh "$host" tic Files/${i}-256color.infocmp
# done
