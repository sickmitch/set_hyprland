#!/bin/bash
#

clear

# read -rep $'[\e[1;33mACTION\e[0m] - Would you like to setup pulseaudio? (y,n) ' PULSE
# read -rep $'[\e[1;33mACTION\e[0m] - Would you like to use secret-service? (y,n) ' SECRET
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install sddm as display manager? (y,n) ' SDDM
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install and set nvim? (y,n) ' NVIM
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to rice hyprland? (y,n) ' RICE
# read -rep $'[\e[1;33mACTION\e[0m] - Would you like to set spotify ad-block? (y,n) ' SPOT

#Set pulseaudio
# if [[ $PULSE == "Y" || $PULSE == "y" ]]; then
# 	echo -n "Configuring pulseaudio....."
# 	mkdir -p $HOME/.config/systemd/user/default.target.wants/ 
# 	mkdir -p $HOME/.config/systemd/user/sockets.target.wants/ 
# 	sudo ln -s /usr/lib/systemd/user/pulseaudio.service $HOME/.config/systemd/user/default.target.wants/pulseaudio.service 
# 	sudo ln -s /usr/lib/systemd/user/pulseaudio.socket $HOME/.config/systemd/user/sockets.target.wants/pulseaudio.socket 
# 	pulseaudio -D &>/dev/null
# 	echo "Done!"
# fi

if [[ $SECRET == "Y" || $SECRET == "y" ]]; then
  echo "Configuring secret-service...."
  if [ ! -d "/home/$USER/.config/systemd/user/" ]; then
    mkdir -p /home/$USER/.config/systemd/user/
  fi
  NAME="/home/$USER/.config/systemd/user/secret-service.service"
  echo "[Unit] " >> $NAME
  echo "Description=Service to keep secrets of applications " >> $NAME
  echo "Documentation=https://github.com/yousefvand/secret-service " >> $NAME
  echo "[Install] " >> $NAME
  echo "WantedBy=default.target " >> $NAME
  echo "[Service] " >> $NAME
  echo "Type=simple " >> $NAME
  echo "RestartSec=30 " >> $NAME
  echo "Restart=always " >> $NAME
  echo "Environment="MASTERPASSWORD=0ZO53KsQvF2pSfd4qdrqaiULzPSBsLZO" " >> $NAME
  echo "WorkingDirectory=%h " >> $NAME
  echo "ExecStart=/usr/bin/secretserviced" >> $NAME
  echo "Service file created"
  echo -e "Installing secret-service\n"
  yay -S secret-service-bin
  echo "Enabling secret-service"
  systemctl --user daemon-reload
  systemctl enable --now --user secret-service.service
fi

#Set login manager
if [[ $SDDM == "Y" || $SDDM == "y" ]]; then
	echo -n "Configuring SDDM....."
	sudo apt install sddm 
	LOC="/etc/sddm.conf"
	echo -e "The following has been added to $LOC.\n"
	echo -e "[Autologin]\nUser = $(whoami)\nSession=hyprland" | sudo tee -a $LOC
	echo -e "\n"
	echo -e "Enabling SDDM service...\n"
	sudo systemctl enable sddm 
	sleep 3
	echo "Done!"
fi

#Nvim
if [[ $NVIM == "Y" || $NVIM == "y" ]]; then
	echo -n "Installing neovim....."
	sudo apt install neovim nodejs ripgrep fd 
	show_progress $!
	echo -n "Backing up....."
	mv ~/.config/nvim ~/.config/nvim.bak 
	mv ~/.local/share/nvim ~/.local/share/nvim.bak 
	mv ~/.local/state/nvim ~/.local/state/nvim.bak 
	mv ~/.cache/nvim ~/.cache/nvim.bak 
	echo -n "Configuring...."
	mkdir -p ~/.config/nvim 
	mkdir -p ~/.local/share/nvim/site/pack/packer/start 
	git clone -b prima https://github.com/sickmitch/nvim.git ~/.config/nvim 
	git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 		~/.local/share/nvim/site/pack/packer/start/packer.nvim  
	echo -n "Cleaning...."
	rm -rf ~/.config/nvim/.git 
	rm -rf ~/.config/nvim/.gitignore 
	echo -n "Remember to run :checkhealth at first nvim start and follow errors"
	echo -n "A big packer sync should be needed"
fi

#Ricing
if [[ $RICE == "Y" || $RICE == "y" ]]; then
	echo -e "Ricing your hyprland install...."
	git clone https://github.com/sickmitch/dotfiles.git 
	mkdir -p $HOME/.config/systemd/user &>/dev/null
	rm -rf dotfiles/.git dotfiles/.gitignore dotfiles/README.md 
	cp -r dotfiles/* $HOME/.config 
	systemctl --user --now enable check-battery-user.service
	systemctl --user --now enable check-battery-user.timer
  sudo systemctl --now enable bluetooth-autoconnect.service
	echo -e "Cleaning...."
	dir=${0%/*}
	cd $dir
	rm -rf dotfiles 
	echo -e "Done!"  
fi

#ad-block
if [[ $SPOT == "Y" || $SPOT == "y" ]]; then
	echo -e "Getting spotify-adblock setted up...."
	sudo pacman -S --noconfirm rust & 1>&-
	git clone https://github.com/abba23/spotify-adblock.git 
	cd spotify-adblock 
	make 
	sudo make install 
	dir=${0%/*}
	cd $dir 
	rm -rf spotify-adblock 
	echo -e "Done!"
fi

exit
