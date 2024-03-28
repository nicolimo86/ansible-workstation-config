#!/bin/bash
# curl -fSsL https://raw.githubusercontent.com/nicolimo86/ansible-workstation-config/master/utils/install.sh | bash

if [ ! -d ~/workspace ]; then
    mkdir -p ~/workspace
fi
cd ~/workspace

git clone https://github.com/nicolimo86/ansible-workstation-config.git
cd ansible-workstation-config
./taskfile.sh work

cd ~/dotfiles
./install.sh all
