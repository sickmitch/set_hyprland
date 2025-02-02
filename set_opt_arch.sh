#!/bin/bash
#

INSTLOG="install.log"

show_progress() {
	while ps | grep $1 &>/dev/null; do
		echo -n "."
		sleep 2
	done
	echo -en "Done!\n"
	sleep 2
}

# sudo touch /tmp/hyprv.tmp

clear

read -rep $'[\e[1;33mACTION\e[0m] - Would you like to use secret-service? (y,n) ' SECRET
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install sddm as display manager? (y,n) ' SDDM
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install and set nvim? (y,n) ' NVIM
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to rice hyprland? (y,n) ' RICE
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to set spotify ad-block? (y,n) ' SPOT


if [[ $SECRET == "Y" || $SECRET == "y" ]]; then
  echo "Configuring secret-service...."
  if [ ! -d "/home/$USER/.config/systemd/user/" ]; then
    mkdir -p /home/$USER/.config/systemd/user/
  fi
  NAME="/home/$USER/.config/systemd/user/secret-service.service"
  rm $NAME
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
	sudo pacman -S --noconfirm sddm &>>$INSTLOG &
	show_progress $!
	LOC="/etc/sddm.conf"
	echo -e "The following has been added to $LOC.\n"
	echo -e "[Autologin]\nUser = $(whoami)\nSession=hyprland" | sudo tee -a $LOC
	echo -e "\n"
	echo -e "Enabling SDDM service...\n"
	sudo systemctl enable sddm 1>/dev/null
	sleep 3
	echo "Done!"
fi

#Nvim
if [[ $NVIM == "Y" || $NVIM == "y" ]]; then
	echo -n "Installing neovim....."
	sudo pacman -S --noconfirm neovim nodejs ripgrep fd &>>$INSTLOG &
	show_progress $!
	echo -n "Backing up....."
	mv ~/.config/nvim ~/.config/nvim.bak &>>/dev/null
	mv ~/.local/share/nvim ~/.local/share/nvim.bak &>>/dev/null
	mv ~/.local/state/nvim ~/.local/state/nvim.bak &>>/dev/null
	mv ~/.cache/nvim ~/.cache/nvim.bak &>>/dev/null
	echo -n "Configuring...."
	mkdir -p ~/.config/nvim &>>dev/null
	mkdir -p ~/.local/share/nvim/site/pack/packer/start &>>dev/null
	git clone -b prima https://github.com/sickmitch/nvim.git ~/.config/nvim &>>dev/null
	git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 		~/.local/share/nvim/site/pack/packer/start/packer.nvim  &>>dev/null
	echo -n "Cleaning...."
	rm -rf ~/.config/nvim/.git &>>/dev/null
	rm -rf ~/.config/nvim/.gitignore &>>/dev/null
	echo -n "Remember to run :checkhealth at first nvim start and follow errors"
	echo -n "A big packer sync should be needed"
fi

#Ricing
if [[ $RICE == "Y" || $RICE == "y" ]]; then
	echo -e "Ricing your hyprland install...."
	git clone https://github.com/sickmitch/dotfiles.git 1>/dev/null
  git clone https://github.com/yeyushengfan258/Future-cursors.git 1>/dev/null
	mkdir -p $HOME/.config/systemd/user &>/dev/null
	rm -rf dotfiles/{.git,.gitignore,README.md} 1>/dev/null
	cp -r dotfiles/* $HOME/.config 1>/dev/null
  cd Future-cursors && ./install.sh 1>/dev/null && sudo ./install.sh 1>/dev/null
	systemctl --user --now enable check-battery-user.service
	systemctl --user --now enable check-battery-user.timer
  sudo systemctl --now enable bluetooth-autoconnect.service
  gsettings set org.gnome.desktop.interface gtk-theme catppuccin-mocha-blue-standard+default
  gsettings set org.gnome.desktop.interface cursor-theme Future-cursors
  nwg-look -a
	echo -e "Cleaning...."
	dir=${0%/*}
	cd $dir
  rm -rf Future-cursors 1>/dev/null
	rm -rf dotfiles 1>/dev/null
	echo -e "Done!"  
fi

#ad-block
if [[ $SPOT == "Y" || $SPOT == "y" ]]; then
	echo -e "Getting spotify-adblock setted up...."
	sudo pacman -S --noconfirm rust & 1>&-
	git clone https://github.com/abba23/spotify-adblock.git 1>/dev/null
	cd spotify-adblock 1>/dev/null
	make 1>/dev/null
	sudo make install & 1>&- 2>>$INSTLOG
	dir=${0%/*}
	cd $dir 1>/dev/null
	rm -rf spotify-adblock 1>/dev/null
	echo -e "Done!"
fi

exit
