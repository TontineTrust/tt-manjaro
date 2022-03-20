#!/usr/bin/env bash
set -euo pipefail

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
# Read this install script and check you are happy with it.
# Note that this script is interactive, it requires your input.
# TODO add --no-confirm flag
#
# Download this install script:
#   wget -O tt-manjaro-install.sh https://raw.githubusercontent.com/tontinetrust/tt-manjaro/main/tt-manjaro-install.sh
#
# Make this script executable:
#   chmod +x ./tt-manjaro-install.sh
# TODO upload executable version of this script.
#
# Run this script as root:
#   sudo ./tt-manjaro-install.sh
#
# Thunderbird email client will be installed.
# To setup work email use these settings:
#   imap.mail.eu-west-1.awsapps.com
#   443
#   smtp.mail.eu-west-1.awsapps.com
#   465

DOOM_COMMIT="5e6689fe5e4307476e518441d99ecdd1baf3255e"
HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
KITTY_CONF_DIR="$HOME/.config/kitty"
KITTY_CONF_PATH="$KITTY_CONF_DIR/kitty.conf"
REPO_ROOT="https://raw.githubusercontent.com/tontinetrust/tt-manjaro/main"
SSH_KEY_ALGO="ed25519"
SSH_KEY_DIR="$HOME/.ssh"
SSH_KEY_PATH="$SSH_KEY_DIR/id_$SSH_KEY_ALGO"
SWAY_CONF_PATH="$HOME/.config/sway/config.d/tt.conf"

newStep() {
  echo
  echo "⚙️  TontineTrust install step:"
  echo "⚙️    $1"
  echo
}

userQ() {
  echo
  read -p "⚙️  $1 [y/n]? " -n 1 -r
}

newStepUserQ() {
  newStep "$1"
  userQ "$1"
}

takesLong() {
  echo "WARNING: The next step takes a long time!"
}

################################################
##### SYSTEM PACKAGES AND HARDWARE-RELATED #####
################################################

newStep 'Update packages'
echo 'This step can be skipped if you have previously run'
echo 'this script or if you have already manually updated'
echo 'Manjaro. OTHERWISE IT IS REQUIRED.'
echo
read -p 'Update packages [y/n]? ' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  pamac update --force-refresh --aur --devel
fi

newStep 'Install bluetooth'
pamac install --no-confirm blueman bluez bluez-utils
modprobe btusb
systemctl start bluetooth  # Start now.
systemctl enable bluetooth # Start on login.

########################
##### APPLICATIONS #####
########################

newStepUserQ "Install Bitwarden"
if [[ $REPLY =~ ^[Yy]$ ]]
then
  pamac install --no-confirm bitwarden
fi

newStep "Install emacs"
read -p "Install emacs [y/n]? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  pamac install --no-confirm emacs
  echo
  takesLong
  read -p "Install Doom emacs [y/n]? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    pamac install --no-confirm fd findutils ripgrep
    git clone --depth 1 https://github.com/hlissner/doom-emacs "HOME/.emacs.d" || true
    (cd "$HOME/.emacs.d" && git pull && git checkout "$DOOM_COMMIT")
    su "$SUDO_USER" -c "$HOME/.emacs.d/bin/doom -y install"
    echo
    takesLong
    read -p "Use TontineTrust Doom emacs config [y/n]? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      pamac install --no-confirm direnv pandoc shellcheck
      if ! command -v nixfmt &> /dev/null
      then
        pamac build --no-confirm nixfmt
      fi
      DOOM_DIR=~/.doom.d
      wget -O "$DOOM_DIR/config.el" "$REPO_ROOT/doom/config.el"
      wget -O "$DOOM_DIR/config.el" "$REPO_ROOT/doom/init.el"
      wget -O "$DOOM_DIR/config.el" "$REPO_ROOT/doom/packages.el"
      su "$SUDO_USER" -c "$HOME/.emacs.d/bin/doom -y sync"
      su "$SUDO_USER" -c "$HOME/.emacs.d/bin/doom -y doctor"
    fi
  fi
fi

newStep 'git'
pamac install --no-confirm git
if [[ $(git config user.name) ]]; then
  GIT_USERNAME=$(git config user.name)
  echo "git username already set to: $GIT_USERNAME"
  echo "To update git username:"
  echo "  git config --global user.name <new_username>"
else
  read -p 'Enter git username: ' GIT_USERNAME
  git config --global user.name "$GIT_USERNAME"
fi
if [[ $(git config user.email) ]]; then
  GIT_EMAIL=$(git config user.email)
  echo "git email already set to: $GIT_EMAIL"
  echo "To update git email:"
  echo "  git config --global user.email <new_email"
else
  read -p 'Enter git email: ' GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
fi
if [ ! -f "$SSH_KEY_PATH" ]; then
  su "$SUDO_USER" -c "mkdir -p $SSH_KEY_DIR || true"
  su "$SUDO_USER" -c "echo $SSH_KEY_PATH | ssh-keygen -P '' -t $SSH_KEY_ALGO -C $GIT_EMAIL"
  su "$SUDO_USER" -c "eval \$(ssh-agent -s) && ssh-add"
  echo
  echo "SSH PUBLIC KEY:"
  cat ~/.ssh/id_ed25519.pub
  echo
  echo 'Select and copy the contents of the above public key'
  echo 'and upload the key to GitHub. More information here:'
  echo '  https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account'
  echo 'key to GitHub.'
  echo
fi

newStep 'kitty terminal'
pamac install --no-confirm kitty kitty-shell-integration
userQ "Use TontineTrust kitty config"
if [[ $REPLY =~ ^[Yy]$ ]]
then
  mkdir -p "$KITTY_CONF_DIR" || true
  wget -O "$KITTY_CONF_PATH" "$REPO_ROOT/kitty/kitty.conf"
fi

newStep 'lsd'
pamac install --no-confirm lsd

newStep 'Nix & Cachix'
pamac install --no-confirm nix
nix-env -iA cachix -f https://cachix.org/api/v1/install

newStep 'sway'
pamac install --no-confirm swaylock wlogout
userQ "Use TontineTrust sway config (TODO fix)"
if [[ $REPLY =~ ^[Yy]$ ]]
then
  wget -O "$SWAY_CONF_PATH" "$REPO_ROOT/sway/tt.conf"
fi

newStep 'Thunderbird'
pamac install --no-confirm thunderbird

newStep 'Visual Studio Code'
pamac install --no-confirm code

# TODO Install zoom.

# TODO change default shell to zsh.
# newStep 'zsh'
# pamac install --no-confirm zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search

####################################
##### ADDITIONAL CONFIGURATION #####
####################################

# TODO Fix zoom issue.
# https://gitlab.gnome.org/GNOME/gnome-shell/-/issues/4665

# GTK theme.
# TODO don't build if already built.
pamac build --no-confirm dracula-gtk-theme
# https://wiki.manjaro.org/index.php/Set_all_Qt_app%27s_to_use_GTK%2B_font_%26_theme_settings
pamac install --no-confirm qt5ct

# TODO enable Fira Code.
# GTK font.
# pamac install --no-confirm woff2-fira-code
# userQ "Use FiraCode font"
# if [[ $REPLY =~ ^[Yy]$ ]]
# then
#   su "$SUDO_USER" -c "gsettings set org.gnome.desktop.interface font-name 'Fira Code 10'"
#   su "$SUDO_USER" -c "gsettings set org.gnome.desktop.interface document-font-name 'Fira Code 10'"
#   su "$SUDO_USER" -c "gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Code 10'"
#   su "$SUDE_USER" -c "gsettings set org.gnome.nautilus.desktop font 'Ubuntu 10'"
# fi

# Bash config.
# NOTE: Keep this at the bottom.
wget -O "$HOME/.bashrc" "$REPO_ROOT/bash/.bashrc"
source "$HOME/.bashrc"

echo
echo
echo '🔥  Reload sway with:'
echo '🔥    sway reload:'
echo
echo '🔥  Install our GitHub projects with:'
echo  🔥    'bash <(curl -s https://raw.githubusercontent.com/tontinetrust/tt-manjaro/main/install-projects.sh)'
echo
echo
