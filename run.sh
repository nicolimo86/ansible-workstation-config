#!/usr/bin/env bash

venv_dir=/tmp/venv
vault_key_file=/tmp/ansvault.key

# Detect package manager
if command -v apt-get &>/dev/null; then
    PKG_MANAGER="apt-get"
    PYTHON_VENV_PACKAGE="python3-venv"
elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
    PYTHON_VENV_PACKAGE="python3"
else
    echo "Unsupported package manager. Exiting."
    exit 1
fi

function private:venv:prepare {
    if ! command -v ansible &>/dev/null; then
        if ! dpkg -s "$PYTHON_VENV_PACKAGE" &>/dev/null && ! rpm -q "$PYTHON_VENV_PACKAGE" &>/dev/null; then
            sudo $PKG_MANAGER update -y
            sudo $PKG_MANAGER install -y "$PYTHON_VENV_PACKAGE" python3-pip
        fi
        python3 -m venv "$venv_dir"
        source "$venv_dir"/bin/activate
        pip install --upgrade pip
        pip install ansible
    fi
}

function private:ansible:play {
    tags="$1"
    private:venv:prepare
    source "$venv_dir"/bin/activate
    
    if [ -f "$vault_key_file" ]; then
        echo "File $vault_key_file exists."
        ansible-playbook playbook.yml \
        --tags "$tags" \
        --extra-vars "@vars.yml" \
        --ask-become-pass \
        --vault-password-file "$vault_key_file"
    else
        echo "File $vault_key_file does not exist. Asking for vault password:"
        ansible-playbook playbook.yml \
            --tags "$tags" \
            --extra-vars "@vars.yml" \
            --ask-vault-password \
            --ask-become-pass
    fi
}

function editvars {
    private:venv:prepare
    source "$venv_dir"/bin/activate
    
    if [ -f "$vault_key_file" ]; then
        echo "File $vault_key_file exists."
        ansible-vault edit vars.yml --vault-password-file "$vault_key_file"
    else
        echo "File $vault_key_file does not exist. Asking for vault password:"
        ansible-vault edit vars.yml --ask-become-pass
    fi
}

# curl -fSsL https://raw.githubusercontent.com/nicolimo86/ansible-workstation-config/master/run.sh | bash -s -- bootstrap
function bootstrap {
    # Use the first argument, or default to "work" if not provided.
    local param="${1:-work}"

    if [ ! -d ~/workspace ]; then
        mkdir -p ~/workspace
    fi
    cd ~/workspace || exit

    git clone https://github.com/nicolimo86/ansible-workstation-config.git
    cd ansible-workstation-config || exit
    ./run.sh "$param"

    cd ~/dotfiles || exit
    ./install.sh all
}

function work {
    tags="common,ssh,work"
    private:ansible:play "$tags"
}

function personal {
    tags="common,ssh,personal"
    private:ansible:play "$tags"
}

function test {
    ansible_tag="${1:-'ssh,common'}"
    docker build --build-arg TAGS="$ansible_tag" -t ansible .
    docker run -it ansible
}

function exec {
    ansible_tag="${1:-'ssh,common'}"
    docker build --build-arg TAGS="$ansible_tag" -t ansible .
    docker run --rm -u user1 -it -v $(pwd):/home/user1/workingdir ansible bash
}

function private:default {
    help
}

function help {
    echo "$0 <task> <args>"
    echo "Tasks:"
    compgen -A function | sed -En '/private:(.*)/d;s/(.*)/\1/p' | cat -n
}

"${@:-private:default}"

