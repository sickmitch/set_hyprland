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
	wireplumber
	jq
	wl-clipboard
	cliphist
	python-requests
	pacman-contrib
	tlp
	plocate
	xorg-xhost
	pipewire
	pulseaudio
	pulseaudio-bluetooth
	pulseaudio-equalizer
	bluetooth-autoconnect
	acpi
  ncdu
  xdg-autostart
  wireless_tools
)

#the main packages
install_stage=(
	# hyprpicker-git
  pyprland
	hyprpaper
  wofi
	neofetch
	swaylock-effects-git
	tldr
	udiskie
	kitty
  bash-completion
  fzf
  eza
  zoxide
	dunst
	waybar
	wlogout
  tmux
	webapp-manager
	xdg-desktop-portal-hyprland
	swappy
	grim
	slurp
	thunar
	tumbler
	btop
  floorp-bin
	mpv
	pamixer
	pavucontrol
	telegram-desktop
	spotify
  spicetify-cli
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
  sublime-text-2
	ttf-jetbrains-mono-nerd
	noto-fonts-emoji
	nwg-look-bin
	vlc
	bat
	xournalpp
	# catppuccin-cursors-mocha
	# catppuccin-gtk-theme-mocha
	# papirus-folders-catppuccin-git
  logseq-desktop-bin
  electronmail-bin
  secret-service-bin
  vorta
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
  sudo pacman -S git
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

	# Install the correct hyprland version
	echo -e "$CNT - Installing Hyprland, this may take a while..."
  install_software hyprland

	# Stage 1 - main components
	echo -e "$CNT - Installing main components, this may take a while..."
	for SOFTWR in ${install_stage[@]}; do
		install_software $SOFTWR
	done

	# Start the bluetooth service
	echo -e "$CNT - Starting the Bluetooth Service..."
	sudo systemctl enable --now bluetooth.service &>>$INSTLOG
	sudo systemctl enable --now bluetooth-autoconnect.service &>>$INSTLOG
	sleep 2

	# Clean out other portals
	echo -e "$CNT - Cleaning out conflicting xdg portals..."
	yay -R --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk &>>$INSTLOG

  pulseaudio -D
  systemctl enable --now tlp.service
  echo -e $"\e[1;31mThe system is set, you can now continue yourself or you can run set_opt script to rice your installed system...\e[0m"
fi
