#!/usr/bin/env bash
# git clone https://www.github.com/ebdavison/dotfiles.git
sudo snap refresh firefox
cd $HOME/Downloads/
sudo apt install i3 polybar
sudo apt install lyx vim wget git p7zip-full screen tmux curl
wget "https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.2.0-0-ppa2/ghostty_1.2.0-0.ppa2_amd64_24.04.deb"
sudo apt install ./ghostty_1.2.0-0.ppa2_amd64_24.04.deb 
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install
curl -s https://ohmyposh.dev/install.sh | bash -s
sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
curl https://pyenv.run | bash
