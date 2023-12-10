#!/bin/bash
VERSION=3.3

NC='\033[0m'
BLUE='\033[0;34m'
GREEN='\033[0;31m'
UGREEN='\033[4;32m'
BGREEN='\033[1;32m'
BRED='\033[1;31m'

create_activate_file() {
    cat >${VINTGO_USER_HOME}/activate.sh <<EOF
#!/bin/bash

[[ "\${BASH_SOURCE[0]}" != "\$0" ]] || { echo -e "${BRED}ERROR:${NC} script needs to be sourced !\n\$ source \${BASH_SOURCE[0]}"; exit 1; }

source $VIRTUALENVWRAPPER_SCRIPT

export WORKON_HOME=$WORKON_HOME
export VIRTUALENVWRAPPER_PYTHON=$VIRTUALENVWRAPPER_PYTHON
export VINTGO_USER_HOME=\$(cd -- "\$(dirname -- "\${BASH_SOURCE[0]}")" &> /dev/null && pwd)

workon $1
vintgo --version

EOF

    if [ ! "$wslpass" ] 
    then
        sudo chmod -R 777 ${VINTGO_USER_HOME}
    else
       echo $wslpass | sudo -S chmod -R 777 ${VINTGO_USER_HOME}
    fi
}

fix_forgenet_wsl() {
    if [ ! "$wslpass" ] 
    then
        log "LOG" "Adding forge.vnet.valeo to hosts ..."
        if ! grep -q "10.110.9.123 forge.vnet.valeo.com" /etc/hosts ; then
            echo "10.110.9.123 forge.vnet.valeo.com" | sudo tee -a /etc/hosts
        else
            log "LOG" "Already Exist"
        fi

        log "LOG" "Adding forge-nexus.vnet.valeo to hosts ..."
        if ! grep -q "10.110.9.29 forge-nexus.vnet.valeo.com" /etc/hosts ; then
            echo "10.110.9.29 forge-nexus.vnet.valeo.com" | sudo tee -a /etc/hosts
        else
            log "LOG" "Already Exist"   
        fi
    else  
        log "LOG" "Adding forge.vnet.valeo to hosts ..."
        if ! grep -q "10.110.9.123 forge.vnet.valeo.com" /etc/hosts ; then
            { echo $wslpass; echo "10.110.9.123 forge.vnet.valeo.com"; } | sudo -k -S tee -a /etc/hosts
        else
            log "LOG" "Already Exist"
        fi
        log "LOG" "Adding forge-nexus.vnet.valeo to hosts ..."
        if ! grep -q "10.110.9.29 forge-nexus.vnet.valeo.com" /etc/hosts ; then
            { echo $wslpass; echo "10.110.9.29 forge-nexus.vnet.valeo.com"; } | sudo -k -S tee -a /etc/hosts
        else
            log "LOG" "Already Exist"   
        fi
    fi
    echo "======================== /etc/hosts ==========================="
    cat /etc/hosts
    echo "==============================================================="
    
}

do_prerequisite() {
    if [ ! "$wslpass" ] 
    then
        sudo apt-get update -y

        # install python3.8
        log "LOG" "Check python3.8"
        if ! command -v python3.8 &> /dev/null; then
            log "LOG" "Install python3.8"
            sudo apt-get install python3.8 -y
        else
            log "LOG" "Check python3.8 version"
            if ! python3.8 -c 'import sys; exit(1) if (sys.version_info.major == 3 and sys.version_info.minor < 7) else exit(0)'; then
                log "LOG" "Instal python3.8"
                sudo apt-get install python3.8 -y
            fi
        fi

        # install pip3
        if ! command -v pip3 &> /dev/null
        then
            log "LOG" "Instal python3-pip"
            sudo apt-get install python3-pip -y
        fi

        # install zip/unzip
        if ! command -v unzip &> /dev/null
        then
            log "LOG" "Install unzip"
            sudo apt-get install unzip -y
        fi

        source $(which virtualenvwrapper.sh)
        source ~/.bashrc

        # install virtualenvwrapper
        if ! command -v workon &> /dev/null
        then
            log "LOG" "Install virtualenvwrapper"
            sudo python3.8 -m pip install virtualenv virtualenvwrapper
            if ! grep -q "virtualenvwrapper.sh" ~/.bashrc ; then
                log "LOG" "Add virtualenvwrapper.sh to ~/.bashrc"
                echo "source $(which virtualenvwrapper.sh | head -1)" >> ~/.bashrc
            fi
        fi
        check_virtualenvwrapper
    else 
        echo $wslpass | sudo -S apt-get update -y

        # install python3.8
        log "LOG" "Check python3.8"
        if ! command -v python3.8 &> /dev/null; then
            log "LOG" "Instal python3.8"
            echo $wslpass | sudo -S apt-get install python3.8 -y
        else
            log "LOG" "Check python3.8 version"
            if ! python3.8 -c 'import sys; exit(1) if (sys.version_info.major == 3 and sys.version_info.minor < 7) else exit(0)'; then
                log "LOG" "Instal python3.8"
                echo $wslpass | sudo -S apt-get install python3.8 -y
            fi
        fi
        python3.8 --version

        # install pip3
        if ! command -v pip3 &> /dev/null
        then
            log "LOG" "Instal python3-pip"
            echo $wslpass | sudo -S apt-get install python3-pip -y
        fi
        pip3 --version
        # install zip/unzip
        if ! command -v unzip &> /dev/null
        then
            log "LOG" "Install unzip"
            echo $wslpass | sudo -S apt-get install unzip -y
        fi

        source $(which virtualenvwrapper.sh)
        source ~/.bashrc

        # install virtualenvwrapper
        if ! command -v workon &> /dev/null
        then
            log "LOG" "Install virtualenvwrapper"
            echo $wslpass | sudo -S python3.8 -m pip install virtualenv virtualenvwrapper
            if ! grep -q "virtualenvwrapper.sh" ~/.bashrc ; then
                log "LOG" "Add virtualenvwrapper.sh to ~/.bashrc"
                echo "source $(which virtualenvwrapper.sh | head -1)" >> ~/.bashrc
            fi
        fi
        check_virtualenvwrapper
    fi

}
check_virtualenvwrapper(){
    echo "Checking Virtualenvwrapper environment variables in .bashrc .........."
    if [ "$(echo "export VIRTUALENVWRAPPER_PYTHON=$(which python3.8 | head -1)" | grep -Fxc --file ~/.bashrc || echo 0)" -eq "0" ];
    then
        echo "export VIRTUALENVWRAPPER_PYTHON=$(which python3.8 | head -1)" >> ~/.bashrc
    fi
    if  [ "$(echo "export VIRTUALENVWRAPPER_VIRTUALENV=$(which virtualenv | head -1)" | grep -Fxc --file ~/.bashrc)" -eq "0" ];
    then
        echo "export VIRTUALENVWRAPPER_VIRTUALENV=$(which virtualenv | head -1)" >> ~/.bashrc
    fi
    if [ "$(echo "export WORKON_HOME=$WORKON_HOME" | grep -Fxc --file ~/.bashrc)" -eq "0" ];
    then
        echo "export WORKON_HOME=$WORKON_HOME" >> ~/.bashrc
    fi
    if [ "$(echo "source $VIRTUALENVWRAPPER_SCRIPT " | grep -Fxc --file ~/.bashrc)" -eq "0" ];
    then
        echo "source $VIRTUALENVWRAPPER_SCRIPT "$'\n' >> ~/.bashrc
    fi
    
    source $VIRTUALENVWRAPPER_SCRIPT
    source ~/.bashrc
    log "LOG" "~/.bashrc File is Modified"
    # echo "============================ ~/.bashrc ============================="
    # echo "$(cat ~/.bashrc)"
    # echo "===================================================================="
}
create_env() {
    if [ -z ${VINTGO_USER_HOME} ]; then 
        export VINTGO_USER_HOME=~/.vintgo
    fi

    if [ ! "$wslpass" ] 
    then
        # Create VIntGo environment folder
        log "LOG" "Create VIntGo environment folder $VINTGO_USER_HOME"
        sudo mkdir -p "$VINTGO_USER_HOME" && sudo chmod 777 "$VINTGO_USER_HOME"

        # Create virtual python environment folder
        log "LOG" "Create python virtual environment folder $WORKON_HOME"
        sudo mkdir -p "$WORKON_HOME" && sudo chmod 777 "$WORKON_HOME"
    else
        # Create VIntGo environment folder
        log "LOG" "Create VIntGo environment folder $VINTGO_USER_HOME"
        echo $wslpass | sudo -S mkdir -p "$VINTGO_USER_HOME" && echo $wslpass | sudo -S chmod 777 "$VINTGO_USER_HOME"

        # Create virtual python environment folder
        log "LOG" "Create python virtual environment folder $WORKON_HOME"
        echo $wslpass | sudo -S mkdir -p "$WORKON_HOME" && echo $wslpass | sudo -S chmod 777 "$WORKON_HOME"
    fi

    export VIRTUALENVWRAPPER_PYTHON=$(which python3.8 | head -1)
    source $(which virtualenvwrapper.sh | head -1)

    # generate virtual env
    log "LOG" "Generate python virtual env $1 using $VIRTUALENVWRAPPER_PYTHON"
    mkvirtualenv --python python3.8 "$1"
    workon "$1"
    # log "LOG" "Listing Virtual envs"
    # lsvirtualenv
}
install_vintgo(){
	pip3 install -i https://$1:$2@forge-nexus.vnet.valeo.com/nexus/repository/vintgo_pypi/simple/ --trusted-host forge-nexus.vnet.valeo.com vintgo --extra-index-url https://pypi.python.org/simple/
	source $(which vintgo.sh) && echo source $(which vintgo.sh) >> $VIRTUAL_ENV/bin/postactivate
}
create_netrc_file(){
    # if ! grep -Fxq  "default login $1 password $2" ~/.netrc
    # then
    #     echo "default login $1 password $2" >> ~/.netrc
    # fi
    if ! grep -Fxq  "machine forge.vnet.valeo.com login $1 password $2" ~/.netrc
    then
        if grep -Fq  "machine forge.vnet.valeo.com login $1 " ~/.netrc
        then
            sed -i '/^machine forge.vnet.valeo.com login /d'  ~/.netrc
            echo "machine forge.vnet.valeo.com login $1 password $2" >> ~/.netrc
        else 
            echo "machine forge.vnet.valeo.com login $1 password $2" >> ~/.netrc
        fi
        
    fi
    if ! grep -Fxq  "machine forge-nexus.vnet.valeo.com login $1 password $2" ~/.netrc
    then
        if grep -Fq  "machine forge-nexus.vnet.valeo.com login $1 " ~/.netrc
        then
            sed -i '/^machine forge-nexus.vnet.valeo.com login /d'  ~/.netrc
            echo "machine forge-nexus.vnet.valeo.com login $1 password $2" >> ~/.netrc
        else 
            echo "machine forge-nexus.vnet.valeo.com login $1 password $2" >> ~/.netrc
        fi
    fi
    log "LOG" "~/.netrc File is created"
    # echo "======================== ~/.netrc ============================="
    # cat ~/.netrc
    # echo "==============================================================="
}
setup_vintgo() {
	# Fixing install issue regarding ubuntu 20.04
	# result=$(cat /etc/os-release | grep VERSION_ID | grep 20.)
    # if [ ! $? -eq 1 ]; then
    log "LOG" "Setting up VIntGo ..."
    vintgo setup install --valeo --username $1 --password $2
    # fi
}

check_py_env() {
    log "LOG" "Creating $1 python virtualenv..."
    if [ -d $WORKON_HOME/$1 ]; then
        log "LOG" "Environment $1 already exist"
        workon "$1"
        log "LOG" "$(vintgo --version)"
    else
        create_env $1
    fi
    check_inside_virtualenv
}

check_vintgo() {
    log "LOG" "Installing VIntGo ..."
    if ! command -v vintgo &> /dev/null 
    then
        install_vintgo "$1" "$2"
    fi
}

check_inside_virtualenv(){
    python3.8 - << EOF
import sys
if(hasattr(sys, 'real_prefix') or (sys.prefix != sys.base_prefix)):
	print("Yes, you are in a virtual environment")
else:
	print("No, you are not in a virtual environment.")
EOF
    
}
print_vintgo() {
    echo -e "${GREEN}
    ____   ____.___        __     ________         ._.      
    \   \ /   /|   | _____/  |_  /  _____/  ____   | |      
     \   Y   / |   |/    \   __\/   \  ___ /  _ \  | |
      \     /  |   |   |  \  |  \    \_\  (  <_> )  \|
       \___/   |___|___|  /__|   \______  /\____/   __
                        \/              \/          \/                       
    ${NC}"
}

log() {
    echo -e "${BLUE}$(date +"%Y/%m/%d - %H:%M:%S.%3N") - $(basename $0) - $1: $2${NC}"
}

usage() { 
    echo -e "Usage: $0 [-u <username>] [-p '<password>'] [-e <python virtualenv>] [-w <Wsl Sudo Password [Optional]>]"
    exit 0
}

print_help() {
        echo "  
        This script installs and setup VIntGo environment in a python virtualenv."
        usage
}   

main() {
    echo "version: ${VERSION}"
    printf "%0.s-" {1..10}
    printf "\n"
    if [[ $1 == "" ]]; then
        usage
    else
        while getopts ":u:p:e:w:h" arg; do
            case "${arg}" in
                u) username=${OPTARG} ;;
                p) password=${OPTARG} ;;
                e) environment=${OPTARG} ;;
                w) wslpass=${OPTARG} ;;
                h) print_help ;;
                *) usage ;;
            esac
        done
    fi  

    if [ ! "$username" ] || [ ! "$password" ] || [ ! "$environment" ]
    then
        usage
    fi  

    print_vintgo

    echo -e "${UGREEN}Welcome >> ${username^^} << to VIntGo 1click installer !${NC}"

    fix_forgenet_wsl
    do_prerequisite

    check_py_env $environment
    check_vintgo $username $password
    setup_vintgo $username $password  
    create_activate_file $environment

    echo -e "${BGREEN}Hooray! You're ready to use VIntGo, just run:"
    echo -e "   $ source $VINTGO_USER_HOME/activate.sh"
    echo -e "   $ vintgo  --version${NC}"
}

(main $* | tee -a "vintgo_oneclick.log")