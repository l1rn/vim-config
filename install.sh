#!/bin/bash

set -e

echo "Installing vim config"

AUTO_PAIRS_PLUGIN_REPO="https://github.com/jiangmiao/auto-pairs/blob/master/plugin/auto-pairs.vim"
TEMP_DIR=$(mktemp -d)
VERSION=$(date +%Y%m%d%H%M%s)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REAL_USER="${SUDO_USER:-$(whoami)}"
REAL_HOME=$(eval echo "~$REAL_USER")

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run with sudo: sudo ./install.sh${MC}"
    exit 1
fi

backup_configs() {
    echo -e "${YELLOW}Backing up existing configs...${NC}"
    BACKUP_DIR="/etc/vim/backup-$(date +%Y%m%d-%H%M%s)"
    mkdir -p "$BACKUP_DIR"

    [ -f /etc/vim/vimrc ] && cp /etc/vim/vimrc "$BACKUP_DIR/"
    [ -f /etc/vim/vimrc.local ] && cp /etc/vim/vimrc.local "$BACKUP_DIR/"

    echo "Backup saved to: $BACKUP_DIR"
}

install_configs() {
    echo -e "${GREEN}Installing configs..."

    cp vimrc /etc/vim/
    cp vimrc.local /etc/vim/
    
    chmod 644 /etc/vim/vimrc
    chmod 644 /etc/vim/vimrc.local

    echo -e "${GREEN} System configs installed!"
}

install_plugins() {
    echo -e "${GREEN}Installing Vim plugins..."
	echo "$REAL_HOME"
    mkdir -p "$REAL_HOME/.vim/autoload" "$REAL_HOME/.vim/bundle"

    if [ ! -f $REAL_HOME/.vim/autoload/plug.vim ]; then 
        echo "Installing Vim-Plug..."
        curl -fLo $REAL_HOME/.vim/autoload/plug.vim --create-dirs \
            "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
    fi

    echo "Installing plugins..."

    vim -E -s -u +PlugInstall +qall 2>/dev/null || \
    echo "Plugins installed (may need to run vim and type :PlugInstall if auto-install failed)"
}

create_user_symlink(){
    echo -e "${YELLOW} Creating user symlinks...${NC}"

    mkdir -p ~/.vim
    ln -sf /etc/vim/vimrc ~/.vim/vimrc 2>/dev/null || true
    ln -sf /etc/vim/vim.local ~/.vim/vimrc.local 2>/dev/null || true
}

installation_process() {
	echo 1
}

main() {
    echo "====================================="
    echo "|    Vim configuration installer    |"
    echo "====================================="

    backup_configs
    install_configs
    install_plugins
	
    echo -e "\n${GREEN} Installation complete!${NC}"
    echo ""
    echo "Installed files:"
    echo "  - /etc/vim/vimrc"
    echo "  - /etc/vim/vimrc.local"
    echo "  - ~/.vim/autoload/plug.vim (vim manager)"
    echo "  - ~/.vim/bundle (plugins directory)"
    echo "" 
    echo "To Remove:"
    echo "sudo rm /etc/vim/vimrc /etc/vim/vimrc.local"
    echo "rm -rf ~/.vim"
    echo ""
    echo "Restart Vim or run: vim +PlugInstall"
    echo "====================================="
}

main "$@"
