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

#!/usr/bin/env bash
set -euxo pipefail

# System update.
pamac update --force-refresh --aur --devel

# Bluetooth.
pamac install --no-confirm bluez bluez-utils
modprobe btusb
systemctl start bluetooth  # Start now.
systemctl enable bluetooth # Start on login.

# git.
pamac install --no-confirm git
if [[ $(git config user.name) ]]; then
  echo "git username already set"
else
  read -p "Enter git username: " GIT_USERNAME
  git config --global user.name "$GIT_USERNAME"
fi
if [[ $(git config user.name) ]]; then
  echo "git username already set"
else
  read -p "Enter git email: " GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
fi
# Authenticate with GitHub with an SSH key.
#  https://docs.github.com/es/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent

# Emacs.
read -p "Install emacs [y/n]? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  pamac install --no-confirm emacs
  read -p "Install Doom emacs [y/n]? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    pamac install --no-confirm emacs
    read -p "Install Doom emacs [y/n]? " -n 1 -r
  fi
fi

# vscode.

# Nix.
pamac install --no-confirm nix

# Cachix.

# tontine-frontend.

# robo-actuary.

# Authenticate with GitHub with an SSH key.
#  https://docs.github.com/es/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent

# Setup work email in Thunderbird. Use these settings:
#  imap.mail.eu-west-1.awsapps.com
#  443
#  smtp.mail.eu-west-1.awsapps.com
#  465

# Bitwarden.
pamac install --no-confirm bitwarden
echo
echo "Please keep work-related passwords in a password manager."
echo "TontineTrust recommends Bitwarden."
echo
