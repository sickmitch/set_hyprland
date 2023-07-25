#!/bin/bash

sudo pacman -Syu --noconfirm
clear

read -rep $'[\e[1;33mACTION\e[0m] - Would you like to setup pulseaudio? (y,n) ' PULSE
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install sddm as display manager? (y,n) ' SDDM
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install and set nvim? (y,n) ' NVIM
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to rice hyprland? (y,n) ' RICE
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to set spotify ad-block? (y,n) ' SPOT

#Set pulseaudio
if [[ $PULSE == "Y" || $PULSE == "y" ]]; then
	echo -en "$CNT - Configuering pulseaudio."
	mkdir -p $HOME/.config/systemd/user/default.target.wants/
	mkdir -p $HOME/.config/systemd/user/sockets.target.wants/
	sudo ln -s /usr/lib/systemd/user/pulseaudio.service $HOME/.config/systemd/user/default.target.wants/pulseaudio.service
	sudo ln -s /usr/lib/systemd/user/pulseaudio.socket $HOME/.config/systemd/user/sockets.target.wants/pulseaudio.socket
	pulseaudio -D
fi

#Set login manager
if [[ $SDDM == "Y" || $SDDM == "y" ]]; then
	sudo pacman -S --noconfirm sddm
	LOC="/etc/sddm.conf"
	echo -e "The following has been added to $LOC.\n"
	echo -e "[Autologin]\nUser = $(whoami)\nSession=hyprland" | sudo tee -a $LOC
	echo -e "\n"
	echo -e "Enabling SDDM service...\n"
	sudo systemctl enable sddm
	sleep 3
fi

#Nvim lazyvim
if [[ $NVIM == "Y" || $NVIM == "y" ]]; then
	sudo pacman -S --noconfirm neovim ripgrep fd
	echo -e "Backing up..\n"
	mv ~/.config/nvim ~/.config/nvim.bak
	mv ~/.local/share/nvim ~/.local/share/nvim.bak
	mv ~/.local/state/nvim ~/.local/state/nvim.bak
	mv ~/.cache/nvim ~/.cache/nvim.bak
	git clone https://github.com/LazyVim/starter ~/.config/nvim
	rm -rf ~/.config/nvim/.git
	echo -e "Remember to run :checkhealth at first nvim start\n"
fi

#Ricing
if [[ $RICE == "Y" || $RICE == "y" ]]; then
	git clone https://github.com/sickmitch/dotfiles.git
	mkdir -p $HOME/.config
	cp -r dotfiles/* $HOME/.config
	rm -rf dotfiles
fi

#ad-block
if [[ $SPOT == "Y" || $SPOT == "y" ]]; then
	sudo pacman -S --noconfirm rust
	git clone https://github.com/abba23/spotify-adblock.git
	cd spotify-adblock
	make
	sudo make install
	cd ..
	rm -rf spotify-adblock
fi