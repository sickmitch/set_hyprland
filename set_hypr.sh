#!/bin/bash

# IMPORTANT - This script is meant to run on a clean fresh Arch install on physical hardware

# Define the software that would be inbstalled
#Need some prep work
prep_stage=(
	qt5-wayland
	qt5ct
	qt6-wayland
	qt6ct
	gtk3
	polkit-gnome
	pipewire
	wireplumber
	jq
	gcc12
	wl-clipboard
	cliphist
	python-requests
	pacman-contrib
	tlp
	plocate
	xorg-xhost
	pulseaudio
	pulseaudio-bluetooth
)

#software for nvidia GPU only
nvidia_stage=(
	linux-headers
	nvidia-dkms
	nvidia-settings
	libva
	libva-nvidia-driver-git
)

#the main packages
install_stage=(
	hyprpaper
	neofetch
	swaylock-effects-git
	tldr
	udiskie
	kitty
	dunst
	waybar-hyprland-git
	wlogout
	webapp-manager
	xdg-desktop-portal-hyprland
	swappy
	grim
	slurp
	thunar
	popsicle-bin
	btop
	firefox
	mpv
	pamixer
	pavucontrol
	telegram-desktop
	sublime-text-4
	spotify-launcher
	brightnessctl
	bluez
	bluez-utils
	blueman
	autojump
	network-manager-applet
	gvfs
	thunar-archive-plugin
	file-roller
	starship
	papirus-icon-theme
	ttf-jetbrains-mono-nerd
	noto-fonts-emoji
	xfce4-settings
	nwg-look-bin
	vlc
	bat
	catppuccin-cursors-mocha
	catppuccin-gtk-theme-mocha
	papirus-folders-catppuccin-git
)

for str in ${myArray[@]}; do
	echo $str
done

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"
INSTLOG="install.log"
RC='\e[0m'
RED='\e[31m'
YELLOW='\e[33m'
GREEN='\e[32m'

######
# functions go here

# function that would show a progress bar to the user
show_progress() {
	while ps | grep $1 &>/dev/null; do
		echo -n "."
		sleep 2
	done
	echo -en "Done!\n"
	sleep 2
}

# function that will test for a package and if not found it will attempt to install it
install_software() {
	# First lets see if the package is there
	if yay -Q $1 &>>/dev/null; then
		echo -e "$COK - $1 is already installed."
	else
		# no package found so installing
		echo -en "$CNT - Now installing $1 ."
		yay -S --noconfirm $1 &>>$INSTLOG &
		show_progress $!
		# test to make sure package installed
		if yay -Q $1 &>>/dev/null; then
			echo -e "\e[1A\e[K$COK - $1 was installed."
		else
			# if this is hit then a package is missing, exit to review log
			echo -e "\e[1A\e[K$CER - $1 install had failed, please check the install.log"
			exit
		fi
	fi
}

# clear the screen
clear

# set some expectations for the user
echo -e "$CNT - You are about to execute a script that would attempt to setup Hyprland.
Please note that Hyprland is still in Beta."
sleep 1

# attempt to discover if this is a VM or not
echo -e "$CNT - Checking for Physical or VM..."
ISVM=$(hostnamectl | grep Chassis)
echo -e "Using $ISVM"
if [[ $ISVM == *"vm"* ]]; then
	echo -e "$CWR - Please note that VMs are not fully supported and if you try to run this on
    a Virtual Machine there is a high chance this will fail."
	sleep 1
fi

# let the user know that we will use sudo
echo -e "$CNT - This script will run some commands that require sudo. You will be prompted to enter your password.
If you are worried about entering your password then you may want to review the content of the script."
sleep 1

# give the user an option to exit out
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to continue with the install (y,n) ' CONTINST
if [[ $CONTINST == "Y" || $CONTINST == "y" ]]; then
	echo -e "$CNT - Setup starting..."
	sudo touch /tmp/hyprv.tmp
else
	echo -e "$CNT - This script will now exit, no changes were made to your system."
	exit
fi

# find the Nvidia GPU
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
	ISNVIDIA=true
else
	ISNVIDIA=false
fi

### Disable wifi powersave mode ###
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to disable WiFi powersave? (y,n) ' WIFI
if [[ $WIFI == "Y" || $WIFI == "y" ]]; then
	LOC="/etc/NetworkManager/conf.d/wifi-powersave.conf"
	echo -e "$CNT - The following file has been created $LOC.\n"
	echo -e "[connection]\nwifi.powersave = 2" | sudo tee -a $LOC &>>$INSTLOG
	echo -en "$CNT - Restarting NetworkManager service, Please wait."
	sleep 2
	sudo systemctl restart NetworkManager &>>$INSTLOG

	#wait for services to restore (looking at you DNS)
	for i in {1..6}; do
		echo -n "."
		sleep 1
	done
	echo -en "Done!\n"
	sleep 2
	echo -e "\e[1A\e[K$COK - NetworkManager restart completed."
fi

#### Check for package manager ####
if [ ! -f /sbin/yay ]; then
	echo -en "$CNT - Configuering yay."
	git clone https://aur.archlinux.org/yay.git &>>$INSTLOG
	cd yay
	makepkg -si --noconfirm &>>../$INSTLOG &
	show_progress $!
	if [ -f /sbin/yay ]; then
		echo -e "\e[1A\e[K$COK - yay configured"
		cd ..

		# update the yay database
		echo -en "$CNT - Updating yay."
		yay -Suy --noconfirm &>>$INSTLOG &
		show_progress $!
		echo -e "\e[1A\e[K$COK - yay updated."
	else
		# if this is hit then a package is missing, exit to review log
		echo -e "\e[1A\e[K$CER - yay install failed, please check the install.log"
		exit
	fi
fi

### Install all of the above pacakges ####
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install the packages? (y,n) ' INST
if [[ $INST == "Y" || $INST == "y" ]]; then

	# Prep Stage - Bunch of needed items
	echo -e "$CNT - Prep Stage - Installing needed components, this may take a while..."
	for SOFTWR in ${prep_stage[@]}; do
		install_software $SOFTWR
	done

	# Setup Nvidia if it was found
	if [[ "$ISNVIDIA" == true ]]; then
		echo -e "$CNT - Nvidia GPU support setup stage, this may take a while..."
		for SOFTWR in ${nvidia_stage[@]}; do
			install_software $SOFTWR
		done

		# update config
		sudo sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
		sudo mkinitcpio --config /etc/mkinitcpio.conf --generate /boot/initramfs-custom.img
		echo -e "options nvidia-drm modeset=1" | sudo tee -a /etc/modprobe.d/nvidia.conf &>>$INSTLOG
	fi

	# Install the correct hyprland version
	echo -e "$CNT - Installing Hyprland, this may take a while..."
	if [[ "$ISNVIDIA" == true ]]; then
		#check for hyprland and remove it so the -nvidia package can be installed
		if yay -Q hyprland &>>/dev/null; then
			yay -R --noconfirm hyprland &>>$INSTLOG &
		fi
		install_software hyprland-nvidia
	else
		install_software hyprland
	fi

	#fix needed for waybar-hyprland
	export CC=gcc-12 CXX=g++-12

	# Stage 1 - main components
	echo -e "$CNT - Installing main components, this may take a while..."
	for SOFTWR in ${install_stage[@]}; do
		install_software $SOFTWR
	done

	# Start the bluetooth service
	echo -e "$CNT - Starting the Bluetooth Service..."
	sudo systemctl enable --now bluetooth.service &>>$INSTLOG
	sleep 2

	# Clean out other portals
	echo -e "$CNT - Cleaning out conflicting xdg portals..."
	yay -R --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk &>>$INSTLOG

	##-------------------------------------------------------------------------------------------------------------------##
  read -rep $'[\e[1;33mACTION\e[0m] - Would you like to continue setting up with this script or continue yourself? (y,n) ' CUST
	if [[ $CUST == "Y" || $CUST == "y" ]]; then
    #Set pulseaudio
    echo -en "$CNT - Configuering pulseaudio."
    pkill pulseaudio
    pulseaudio -D
    sudo ln -s /usr/lib/systemd/user/pulseaudio.service $HOME/.config/systemd/user/default.target.wants/pulseaudio.service
    sudo ln -s /usr/lib/systemd/user/pulseaudio.socket $HOME/.config/systemd/user/sockets.target.wants/pulseaudio.socket

    #Set login manager
    read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install sddm as display manager? (y,n) ' SINST
    if [[ $SINST == "Y" || $SINST == "y" ]]; then
      install_software sddm
      read -n1 -rep 'Would you like to enable SDDM autologin? (y,n)' SDDM
      if [[ $SDDM == "Y" || $SDDM == "y" ]]; then
        LOC="/etc/sddm.conf"
        echo -e "The following has been added to $LOC.\n"
        echo -e "[Autologin]\nUser = $(whoami)\nSession=hyprland" | sudo tee -a $LOC
        echo -e "\n"
        echo -e "Enabling SDDM service...\n"
        sudo systemctl enable sddm
        sleep 3
      fi
    fi

    #Nvim lazyvim
    read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install and set nvim? (y,n) ' NVIM
    if [[ $NVIM == "Y" || $NVIM == "y" ]]; then
      install_software neovim ripgrep fd
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
    read -rep $'[\e[1;33mACTION\e[0m] - Would you like to rice hyprland? (y,n) ' RICE
    if [[ $RICE == "Y" || $RICE == "y" ]]; then
      git clone https://github.com/sickmitch/dotfiles.git
      mkdir -p $HOME/.config
      cp -r dotfiles/* $HOME/.config
      rm -rf dotfiles
    fi

    #ad-block
    read -rep $'[\e[1;33mACTION\e[0m] - Would you like to set spotify ad-block? (y,n) ' SPOT
    if [[ $SPOT == "Y" || $SPOT == "y" ]]; then
      git clone https://github.com/abba23/spotify-adblock.git &>>$INSTLOG
      cd spotify-adblock
      make
      sudo make install &>>../$INSTLOG &
      cd ..
      rm -rf spotify-adblock
      show_progress $!
    fi

    #Bash Setup
    read -rep $'[\e[1;33mACTION\e[0m] - Would you like to set bash? (y,n) ' BASH
    if [[ $BASH == "Y" || $BASH == "y" ]]; then
      checkEnv(){
      ## Check if the current directory is writable.
        GITPATH="$(dirname "$(realpath "$0")")"
        if [[ ! -w ${GITPATH} ]];then
          echo -e "${RED}Can't write to ${GITPATH}${RC}"
          exit 1
        fi
      ## Check for requirements.
      REQUIREMENTS='curl yay sudo'
      if ! which ${REQUIREMENTS}>/dev/null;then
        echo -e "${RED}To run me,https://github.com/fearlessgeekmedia/mybash you need: ${REQUIREMENTS}${RC}"
        exit 1
      fi
      ## Check if member of the wheel group.
      if ! groups|grep wheel>/dev/null;then
        echo -e "${RED}You need to be a member of the wheel to run me!"
        exit 1
      fi
      }
      installDepend(){
      ## Check for dependencies.
      # For some reason, if I put autojump in the original DEPENDENCIES variable,
      # it skips the installation and just does bash and bash completion. So I
      # put autojump in a separate variable and separate yay command.
        DEPENDENCIES1='bash bash-completion'
        DEPENDENCIES2='autojump'
        DEPENDENCIES2='autojump-git'
        echo -e "${YELLOW}Installing dependencies...${RC}"
        yay -S ${DEPENDENCIES1}
        yay -S ${DEPENDENCIES2}
        yay -S ${DEPENDENCIES3}
        sudo mkdir /usr/local/bin/autojump
        sudo ln -s /etc/profile.d/autojump.sh /usr/share/autojump/autojump.sh
      }
      ìnstallStarship(){
        if ! curl -sS https://starship.rs/install.sh|sh;then
          echo -e "${RED}Something went wrong during starship install!${RC}"
          exit 1
        fi
      }
      linkConfig(){
      ## Check if a bashrc file is already there.
      OLD_BASHRC="${HOME}/.bashrc"
      if [[ -e ${OLD_BASHRC} ]];then
        echo -e "${YELLOW}Moving old bash config file to ${HOME}/.bashrc.bak${RC}"
        if ! mv ${OLD_BASHRC} ${HOME}/.bashrc.bak;then
          echo -e "${RED}Can't move the old bash config file!${RC}"
          exit 1
        fi
      fi
      echo -e "${YELLOW}Linking new bash config file...${RC}"
      ## Make symbolic link.
      ln -svf ${GITPATH}/.bashrc ${HOME}/.bashrc
      ln -svf ${GITPATH}/starship.toml ${HOME}/.config/starship.toml

      checkEnv
      installDepend
      installStarship
      if linkConfig;then
        echo -e "${GREEN}Done!\nrestart your shell to see the changes.${RC}"
      else
        echo -e "${RED}Something went wrong!${RC}"
      fi
    fi
  fi
fi
