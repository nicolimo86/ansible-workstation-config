#!/usr/bin/env bash

venv_dir=/tmp/venv
vault_key_file=/tmp/ansvault.key

function private:venv:prepare {
    if ! command -v ansible &> /dev/null; then
        if ! dpkg -s python3-venv &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y python3-venv
        fi
        python3 -m venv "$venv_dir"
        source "$venv_dir"/bin/activate
        pip install ansible
    fi
}

function private:ansible:play {
    tags="$1"

    private:venv:prepare
    source "$venv_dir"/bin/activate

    if [ -f "$vault_key_file" ]; then
        echo "File $vault_key_file exists."
        ansible-playbook local_ubuntu.yml \
        --tags "$tags" \
        --extra-vars "@vars.yml" \
        --ask-become-pass \
        --vault-password-file "$vault_key_file"
    else
        echo "File $vault_key_file does not exist. Asking for vault password:"
        ansible-playbook local_ubuntu.yml \
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
