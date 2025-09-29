#!/usr/bin/env bash
# git clone https://www.github.com/ebdavison/dotfiles.git
sudo snap refresh firefox
cd $HOME/Downloads/
sudo apt install -y i3 polybar rofi xsecurelock
sudo apt install -y lyx vim wget git p7zip-full screen tmux curl
sudo apt install -y arandr libreoffice
sudo apt install -y evolution evolution-data-server evolution-plugin-bogofilter
sudo apt install -y ./ghostty_1.2.0-0.ppa2_amd64_24.04.deb
sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# install system/conventince/bash utils
wget "https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.2.0-0-ppa2/ghostty_1.2.0-0.ppa2_amd64_24.04.deb"
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install
curl -s https://ohmyposh.dev/install.sh | bash -s

# install pyenv
curl https://pyenv.run | bash

# install docker
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo groupadd docker
sudo usermod -aG docker $USER
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
