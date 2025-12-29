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


