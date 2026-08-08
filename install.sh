#!/bin/bash

set -e

echo "Installing vim config"

TEMP_DIR=$(mktemp -d)
VERSION=$(date +%Y%m%d%H%M%s)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

IS_TERMUX=false
if [[ -d /data/data/com.termux ]] || [[ -n "$PREFIX" && -d "$PREFIX" ]]; then
	IS_TERMUX=true
fi

REAL_USER="${SUDO_USER:-$(whoami)}"
REAL_HOME=$(eval echo "~$REAL_USER")

if $IS_TERMUX; then
	REAL_HOME="$HOME"
	REAL_USER="$(whoami)"
fi

SYS_VIMRC="/etc/vim/vimrc"

if $IS_TERMUX; then
	SYS_VIMRC="$PREFIX/etc/vim/vimrc"
fi

CAN_WRITE_SYSTEM=false
if $IS_TERMUX; then
	CAN_WRITE_SYSTEM=true
elif [ "$EUID" -ne 0 ]; then 
	CAN_WRITE_SYSTEM=true
fi

declare -a MISSING_PACKAGES=()

if $IS_TERMUX; then
	PKG_MGR="pkg"
elif command -v apt &>/dev/null; then
	PKG_MGR="apt"
elif command -v apk &>/dev/null; then
	PKG_MGR="apk"
elif command -v dnf &>/dev/null; then
	PKG_MGR="dnf"
elif command -v pacman &>/dev/nul; then
	PKG_MGR="pacman"
elif command -v zypper &>/dev/null; then
	PKG_MGR="zypper"
else
    echo -e "${RED}No supported package manager found.${NC}"
    echo "Please install 'curl', 'vim' and 'git' manually."
    PKG_MGR="none"
fi

is_installed(){
	case $PKG_MGR in
		pkg)    pkg list-installed 2>/dev/null | grep -qw "$1" ;;
		apt)    dpkg -l 2>/dev/null | grep -qw "$1" ;;
		dnf)    dnf list installed "$1" &>/dev/null ;;
		pacman) pacman -Q "$1" &>/dev/null ;;
		zypper) zypper search --installed-only "$1" &>/dev/null ;;
		apk) apk search "$1";;
		*)      command -v "$1" &>/dev/null ;;   # fallback
	esac
}

install_packages() {
	local pkgs=("$@")
	[[ ${#pkgs[@]} -eq 0 ]] && return
	echo -e "${YELLOW}Installing missing packages: ${pkgs[*]}${NC}"
	case $PKG_MGR in
		pkg)    pkg update && pkg install -y "${pkgs[@]}" ;;
		apt)    sudo apt update && sudo apt install -y "${pkgs[@]}" ;;
		dnf)    sudo dnf install -y "${pkgs[@]}" ;;
		pacman) sudo pacman -S --noconfirm "${pkgs[@]}" ;;
		zypper) sudo zypper install -y "${pkgs[@]}" ;;
		apk) 	apk add "${pkgs[@]}";;
		*)      echo -e "${RED}Cannot install automatically. Please install: ${pkgs[*]}${NC}" ;;
	esac
}

check_dependencies() {
    local deps=("curl" "vim" "git")
    MISSING_PACKAGES=()
    for pkg in "${deps[@]}"; do
        if is_installed "$pkg"; then
            echo "$pkg is installed."
        else
            echo "$pkg isn't installed."
            MISSING_PACKAGES+=("$pkg")
        fi
    done
    install_packages "${MISSING_PACKAGES[@]}"
}


backup_configs() {
	echo -e "${YELLOW}Backing up existing configs...${NC}"
	BACKUP_DIR="/tmp/vim-config/backup-$(date +%Y%m%d-%H%M%s)"
	mkdir -p "$BACKUP_DIR"

	[ -f /etc/vim/vimrc ] && cp /etc/vim/vimrc "$BACKUP_DIR/"
	[ -f $REAL_HOME/.vimrc ] && cp $REAL_HOME/.vimrc "$BACKUP_DIR/"

	echo "Backup saved to: $BACKUP_DIR"
}

install_configs() {
	if $CAN_WRITE_SYSTEM; then
		echo "Installing system‑wide vimrc to $SYS_VIMRC"
		mkdir -p "$(dirname "$SYS_VIMRC")"
		cp vimrc "$SYS_VIMRC"
		chmod 644 "$SYS_VIMRC"
	else
		echo -e "${YELLOW}Skipping system vimrc (need root on this system).${NC}"
	fi

	echo "Installing user .vimrc to $REAL_HOME/.vimrc"
	cp .vimrc "$REAL_HOME/"
	chmod 644 "$REAL_HOME/.vimrc"
}


install_plugins() {
	echo "Installing plugins..."
	mkdir -p "$REAL_HOME/.vim/autoload" "$REAL_HOME/.vim/bundle"

	if [[ ! -f "$REAL_HOME/.vim/autoload/plug.vim" ]]; then
	echo "Downloading vim-plug..."
	curl -fLo "$REAL_HOME/.vim/autoload/plug.vim" --create-dirs \
	    "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
	else
	echo "Vim-Plug already exists."
	fi

	vim -E -s -u "$REAL_HOME/.vimrc" +PlugInstall +qall 2>/dev/null || \
        echo -e "${YELLOW}Plugins may need manual install: run vim and type :PlugInstall${NC}"
}

create_user_symlink(){
	if $IS_TERMUX; then
		echo -e "${YELLOW}Symlinks for root not applicable on Termux.${NC}"
		return
	fi
	if [[ $EUID -ne 0 ]]; then
		echo -e "${YELLOW}Not running as root, skipping root symlinks.${NC}"
		return
	fi

	echo -e "${YELLOW}Creating root symlinks...${NC}"
	if [[ -L "/root/.vimrc" ]]; then
		read -p "/root/.vimrc symlink already exists. Recreate? (y/n): " answer
		if [[ $answer =~ ^[Yy]$ ]]; then
		    ln -sf "$REAL_HOME/.vim" /root/.vim
		    ln -sf "$REAL_HOME/.vimrc" /root/.vimrc
		    echo "Symlinks updated."
		fi
	else
		ln -sf "$REAL_HOME/.vim" /root/.vim
		ln -sf "$REAL_HOME/.vimrc" /root/.vimrc
		echo "Symlinks created."
	fi
}

installation_process() {
	echo "====================================="
	echo "| Vim configuration installer       |"
	echo "| Detected environment:             |"
	if $IS_TERMUX; then
		echo "|   Termux (Android)                |"
	else
		echo "|   Linux distribution              |"
	fi
	echo "| Package manager: $PKG_MGR"
	echo "====================================="

	read -p "Use easy installation (all steps, no backup)? (y/n): " easy
	if [[ $easy =~ ^[Yy]$ ]]; then
		check_dependencies
		install_configs
		install_plugins
		create_user_symlink
	else
		read -p "Backup existing configs? (y/n): " dobackup
		[[ $dobackup =~ ^[Yy]$ ]] && backup_configs

		read -p "Install Vim configs? (y/n): " doconfig
		[[ $doconfig =~ ^[Yy]$ ]] && install_configs

		read -p "Install plugins? (y/n): " doplug
		[[ $doplug =~ ^[Yy]$ ]] && install_plugins

		read -p "Create symlinks for root? (y/n): " dosym
		[[ $dosym =~ ^[Yy]$ ]] && create_user_symlink
	fi
}

main() {
	installation_process
	echo -e "\n${GREEN}Installation complete!${NC}"
	echo ""
	echo "Installed files:"
	$CAN_WRITE_SYSTEM && echo "  - $SYS_VIMRC"
	echo "  - $REAL_HOME/.vimrc"
	echo "  - $REAL_HOME/.vim/autoload/plug.vim (vim-plug)"
	echo "  - $REAL_HOME/.vim/bundle (plugin directory)"
	echo ""
	echo "To remove:"
	if $CAN_WRITE_SYSTEM; then
		echo "  rm $SYS_VIMRC"
	fi
	echo "  rm -rf $REAL_HOME/.vim $REAL_HOME/.vimrc"
	echo ""
	echo "Restart Vim or run: vim +PlugInstall"
}

main "$@"
