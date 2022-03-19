# Manjaro install instructions for TontineTrust software development.
#
# Download a Manjaro ISO. Minimal edition of Manjaro Sway is recommended:
#   https://manjaro-sway.download/
#
# Burn the ISO to an installer USB:
#   sudo dd bs=4M if=/path/to/manjaro.iso of=/dev/sd<installer drive letter> status=progress oflag=sync
#
# Format your target drive:
#   sudo mkfs.etx4 /dev/sd<target drive letter>
#
# Boot into the installer USB.
#
# Follow the installer instructions. Make sure to select disk encryption.
#
# Poweroff. Remove the installer USB. Boot into your new Manjaro OS.
#
# Run Manjaro hardware detection:
#   mhwd
#
# Get internet access. USB tether from your phone if you're in a pinch.
#
# Download this install script:
#   wget -O tt-manjaro-install.sh https://raw.githubusercontent.com/tontinetrust/tt-manjaro/main/tt-manjaro-install.sh
#
# Read the install script and check you are happy with it.
#
# Run the install script.
#   chmod +x tt-manjaro-install.sh
#   sudo ./tt-manjaro-install.sh
#
# You will be prompted during the install a number of times.
#
# Thunderbird email client will be installed.
# To setup work email use these settings:
#   imap.mail.eu-west-1.awsapps.com
#   443
#   smtp.mail.eu-west-1.awsapps.com
#   465

#!/usr/bin/env bash
set -euxo pipefail

setupLn () {
  echo
  echo
  echo "⚙️ TontineTrust setting up:"
  echo "⚙️   $1" 
}

################################################
##### SYSTEM PACKAGES AND HARDWARE-RELATED #####
################################################

setupLn 'system packages'
pamac update --force-refresh --aur --devel

setupLn 'bluetooth'
pamac install --no-confirm bluez bluez-utils
modprobe btusb
systemctl start bluetooth  # Start now.
systemctl enable bluetooth # Start on login.

########################
##### APPLICATIONS #####
########################

setupLn 'Bitwarden'
pamac install --no-confirm bitwarden

setupLn 'emacs'
read -p "Install emacs [y/n]? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  pamac install --no-confirm emacs
  read -p "Install Doom emacs [y/n]? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    pamac install --no-confirm fd findutils ripgrep # Doom dependencies.
    git clone --depth 1 https://github.com/hlissner/doom-emacs ~/.emacs.d || true
    yes | ~/.emacs.d/bin/doom install
    # TODO Doom config files.
  fi
fi

setupLn 'git'
pamac install --no-confirm git
if [[ $(git config user.name) ]]; then
  echo 'git username already set'
  echo 'to change username:'
  echo '  git config --global user.name YOUR_USERNAME'
else
  read -p 'Enter git username: ' GIT_USERNAME
  git config --global user.name "$GIT_USERNAME"
fi
if [[ $(git config user.name) ]]; then
  echo 'git username already set'
  echo 'to change email:'
  echo '  git config --global user.email YOUR_EMAIL'
else
  read -p 'Enter git email: ' GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
fi
# TODO Authenticate with GitHub with an SSH key.
#  https://docs.github.com/es/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent

setupLn 'TODO kitty terminal'

setupLn 'Nix'
pamac install --no-confirm nix

setupLn 'Cachix'

setupLn 'Thunderbird'

setupLn 'TODO Visual Studio Code'

####################################
##### ADDITIONAL CONFIGURATION #####
####################################

# https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/4665

##############################
##### TONTINETRUST REPOS #####
##############################

setupLn 'tontine-frontend'
git clone git@github.com:tontinetrust/tontine-frontend ~/tontine-frontend || true

setupLn 'robo-actuary'
git clone git@github.com:tontinetrust/robo-actuary ~/robo-actuary || true
