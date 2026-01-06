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

dependencies=("curl" "vim" "git")

check_dependencies() {
	local missing_packages=()

	for package in "${dependencies[@]}"; do
		if dpkg -l | grep -qw "$package"; then
			echo "$package is installed."
		else
			echo "$package isn't installed."
			missing_packages+=("$package")
		fi
	done

	if [ ${#missing_packages[@]} -ne 0 ]; then
		echo -e "\e[103mInstalling missing packages: ${missing_packages[*]}${NC}"
		sudo apt update && sudo apt install -y ${missing_packages[@]}
	else
		echo -e "\e[102mAll packages already installed!${NC}"
	fi
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
	echo "Installing configs..."
	cp vimrc /etc/vim/vimrc
	cp .vimrc $REAL_HOME/

	chmod 644 /etc/vim/vimrc
	chmod 644 $REAL_HOME/.vimrc

	echo -e "- System configs installed!"
}

install_plugins() {
	echo "Installing plugins..."
	mkdir -p "$REAL_HOME/.vim/autoload" "$REAL_HOME/.vim/bundle"
	if [[ ! -f $REAL_HOME/.vim/autoload/plug.vim ]]; then 
		echo "Installing Vim-Plug..."
		curl -fLo $REAL_HOME/.vim/autoload/plug.vim --create-dirs \
			"https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
	else 
		echo "Vim-Plug already exists in the folder $REAL_HOME/.vim/autoload"
	fi

	vim -E -s -u +PlugInstall +qall 2>/dev/null || \
		echo "Plugins installed (may need to run vim and type :PlugInstall if auto-install failed)"
	}

create_user_symlink(){
	echo -e "${YELLOW}Creating root symlinks...${NC}"
	if [[ -L "/root/.vimrc" ]]; then
		echo "/root/.vimrc symlink already exists!"
		read -p "Recreate the link with new parameters? (y/n): " root_answers
		if [[ $root_answer =~ ^[Yy]$ ]]; then
			sudo ln -sf $REAL_HOME/.vim /root/.vim 2>/dev/null
			sudo ln -sf $REAL_HOME/.vimrc /root/.vimrc
			
			echo "- Symlinks created!"
		fi
	elif [[ ! -L "/root/.vimrc" ]]; then
		sudo ln -sf $REAL_HOME/.vim /root/.vim 2>/dev/null
		sudo ln -sf $REAL_HOME/.vimrc /root/.vimrc
	else
		echo "- Skipped."
	fi
	
}

installation_process() {
	echo "====================================="
	echo "|    Vim configuration installer    |"
	echo "====================================="
	read -p "Use easy installation w/o backup? (y/n): "
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		check_dependencies``
		install_configs
		install_plugins
		create_user_symlink
	elif [[ $REPLY =~ ^[Nn]$ ]]; then
		read -p "Backup existing configs? (y/n): "
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			backup_configs
		fi

		read -p "Install Vim configs system-wide? (y/n): "
		if [[ $REPLY =~ ^[Yy]$ ]]; then 
			install_configs
		fi

		read -p "Install plugins? (y/n): "
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			install_plugins
		fi
		
		read -p "Create symlinks? (y/n): "
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			create_user_symlink
		fi
	fi
}

main() {
	installation_process
	echo -e "\nInstallation complete!${NC}"
	echo ""
	echo "Installed files:"
	echo "  - /etc/vim/vimrc"
	echo "  - ${REAL_HOME}/.vimrc"
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
