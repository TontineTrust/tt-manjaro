#!/usr/bin/env bash
set -euo pipefail

# Manjaro install script for TontineTrust software development.
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
# TODO add --all flag to install all apps with TT configs 
#
# Run this install script:
#   bash <(curl -s https://raw.githubusercontent.com/tontinetrust/tt-manjaro/main/tt-manjaro-install.sh)
#
# Thunderbird email client will be installed.
# To setup work email use these settings:
#   imap.mail.eu-west-1.awsapps.com
#   443
#   smtp.mail.eu-west-1.awsapps.com
#   465

KITTY_CONF_DIR="$HOME/.config/kitty"
KITTY_CONF_PATH="$KITTY_CONF_DIR/kitty.conf"
REPO_ROOT='https://raw.githubusercontent.com/tontinetrust/tt-manjaro/main'
SSH_KEY_ALGO='ed25519'
SSH_KEY_DIR="$HOME/.ssh"
SSH_KEY_PATH="$SSH_KEY_DIR/id_$SSH_KEY_ALGO"
SWAY_CONF_PATH="$HOME/.config/sway"

info() {
  echo "ℹ️  $1"
}

longStep() {
  echo "⚠️  '$1' takes a long time!"
}

newStep() {
  echo "⚙️  Install step: $1"
}

userQ() {
  read -p "⚙️  $1 [y/n]? " -n 1 -r
  echo
}

newStepUserQ() {
  newStep "$1"
  userQ "$1"
}

prompt() {
  read -p "⚙️  $1 " -n 1 -r
}

skipStep() {
  echo "⚙️  Skipping '$1' because $2"
}

################################################
##### SYSTEM PACKAGES AND HARDWARE-RELATED #####
################################################

STEP='Update packages'
newStep "$STEP"
info 'This step can be skipped if you have previously run'
info 'this script or if you have already manually updated'
info 'Manjaro. OTHERWISE IT IS REQUIRED.'
userQ "$STEP"
if [[ $REPLY =~ ^[Yy]$ ]]; then
  pamac update --force-refresh --aur --devel
fi

newStep 'Install bluetooth'
pamac install --no-confirm blueman bluez bluez-utils
modprobe btusb
if [[ $(systemctl is-active bluetooth) ]]; then
  info 'Bluetooth service already running'
else
  info 'Starting bluetooth service'
  systemctl start bluetooth # Start now.
fi
if [[ $(systemctl is-enabled bluetooth) ]]; then
  info 'Bluetooth already enabled on login'
else
  info 'Enabling bluetooth on login'
  systemctl enable bluetooth # Start on login.
fi

########################
##### APPLICATIONS #####
########################

STEP='Install Bitwarden'
newStep "$STEP"
if [[ ! $(pamac list | grep bitwarden) ]]; then
  pamac install --no-confirm bitwarden
else
  skipStep "$STEP" 'Bitwarden is already installed'
fi

STEP='Install Emacs'
newStep "$STEP"
if [[ ! $(pamac list | grep emacs) ]]; then
  userQ "$STEP"
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    pamac install --no-confirm emacs
  fi
else
  skipStep "$STEP" 'Emacs already installed'
fi

STEP='Install Doom emacs'
newStep "$STEP"
if [[ ! $(pamac list | grep emacs) ]]; then
  skipStep "$STEP" 'Requires Emacs to be installed'
else
  longStep "$STEP"
  userQ "$STEP"
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    pamac install --no-confirm fd findutils ripgrep
    git clone --depth 1 https://github.com/hlissner/doom-emacs "$HOME/.emacs.d" || true
    "$HOME/.emacs.d/bin/doom" -y install
    STEP='Use TontineTrust Doom Emacs config'
    longStep "$STEP"
    userQ "$STEP"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      pamac install --no-confirm direnv pandoc shellcheck
      if ! command -v nixfmt &> /dev/null
      then
        pamac build --no-confirm nixfmt
      else
        info "nixfmt already installed"
      fi
      DOOM_DIR="$HOME/.doom.d"
      wget --no-cache -O "$DOOM_DIR/config.el" "$REPO_ROOT/doom/config.el"
      wget --no-cache -O "$DOOM_DIR/init.el" "$REPO_ROOT/doom/init.el"
      wget --no-cache -O "$DOOM_DIR/packages.el" "$REPO_ROOT/doom/packages.el"
      "$HOME/.emacs.d/bin/doom" -y sync
      "$HOME/.emacs.d/bin/doom" -y doctor
      prompt "Read the doctor's diagnosis above then press any key to continue"
    fi
  fi
fi

sshKeySetup() {
  rm "$SSH_KEY_PATH*"
  mkdir -p "$SSH_KEY_DIR" || true
  echo "$SSH_KEY_PATH" | ssh-keygen -P '' -t "$SSH_KEY_ALGO" -C "$GIT_EMAIL"
  eval $(ssh-agent -s) && ssh-add
  echo 
  info 'SSH PUBLIC KEY:'
  cat ~/.ssh/id_ed25519.pub
  echo
  info 'Select and copy the contents of the above public key'
  info 'and upload the key to GitHub. More information here:'
  info '  https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account'
  prompt "Waiting for you to upload that public key... press any key when done"
  ssh -T git@github.com
}

STEP='git setup'
newStep "$STEP"
pamac install --no-confirm git
if [[ $(git config user.name) ]]; then
  GIT_USERNAME=$(git config user.name)
  info "git username already set to: $GIT_USERNAME"
  info 'To update git username: git config --global user.name <username>'
else
  read -p 'Enter git username: ' GIT_USERNAME
  git config --global user.name "$GIT_USERNAME"
fi
if [[ $(git config user.email) ]]; then
  GIT_EMAIL=$(git config user.email)
  info "git email already set to: $GIT_EMAIL"
  info 'To update git email: git config --global user.email <email>'
else
  read -p 'Enter git email: ' GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
fi
if [[ ! -f "$SSH_KEY_PATH" ]]; then
  sshKeySetup
else
  userQ 'Generate new GitHub SSH key (overwrite any existing key)'
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sshKeySetup
  fi
fi

newStep 'Install kitty terminal'
pamac install --no-confirm kitty kitty-shell-integration
userQ 'Use TontineTrust kitty config'
if [[ $REPLY =~ ^[Yy]$ ]]; then
  mkdir -p "$KITTY_CONF_DIR" || true
  wget --no-cache -O "$KITTY_CONF_PATH" "$REPO_ROOT/kitty/kitty.conf"
fi

newStep 'lsd'
pamac install --no-confirm lsd

STEP='Install nix & cachix'
newStep "$STEP"
if ! command -v nix &> /dev/null
then
  sh <(curl -L https://nixos.org/nix/install) --no-daemon
  nix-env -iA cachix -f https://cachix.org/api/v1/install
  echo
  cat << EOF
keep-derivations    = true
keep-outputs        = true
substituters        = https://hydra.iohk.io/ https://iohk.cachix.org https://cache.nixos.org/
trusted-public-keys = hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ= iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
EOF
  info 'Make sure that /etc/nix/nix.conf contains the above lines'
  prompt 'Waiting for you to update /etc/nix/nix.conf... press any key when done'
  info 'You need a read token to use cachix, you can find it here:'
  info '  https://github.com/TontineTrust/secrets/blob/master/cachix-read-token'
  info 'Once you have a token run: '
  info '  cachix authtoken <TOKEN>'
  prompt 'Waiting for you to add a token to cachix... press any key when done'
  cachix use tontinetrust-roboactuary
else
  skipStep "$STEP" "nix already installed"
fi

STEP='Install Sublime Text'
newStep "$STEP"
PKG_NAME='sublime-text-4'
if [[ ! $(pamac list | grep "$PKG_NAME") ]]; then
  pamac build --no-confirm "$PKG_NAME"
else
  skipStep "$STEP" 'Sublime Text already installed'
fi

newStep 'sway'
pamac install --no-confirm swaylock wlogout
wget --no-cache -O "$SWAY_CONF_PATH/definitions.d/tt.conf" "$REPO_ROOT/sway/definitions.d/tt.conf"

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
# https://wiki.manjaro.org/index.php/Set_all_Qt_app%27s_to_use_GTK%2B_font_%26_theme_settings
pamac install --no-confirm qt5ct
if [[ ! $(pamac list | grep dracula-gtk-theme) ]]; then
  pamac build --no-confirm dracula-gtk-theme
fi
if [[ ! $(pamac list | grep woff2-fira-code) ]]; then
  pamac build --no-confirm woff2-fira-code
fi

# GTK font.
# TODO factor this install pattern out: install IFF not installed.
if [[ ! $(pamac list | grep ttf-ubuntu-font-family) ]]; then
  pamac install --no-confirm ttf-ubuntu-font-family
fi

# NOTE: Keep this at the bottom of this file.
newStep 'Bash config'
userQ 'Use TontineTrust bash config (overwrites existing config)'
if [[ $REPLY =~ ^[Yy]$ ]]; then
  wget --no-cache -O "$HOME/.bashrc" "$REPO_ROOT/bash/.bashrc"
  source "$HOME/.bashrc"
fi

#########################
##### PROJECT SETUP #####
#########################

newStep 'Install tontine-frontend'
pamac install --no-confirm nodejs npm
FRONTEND_DIR="$HOME/tontine-frontend"
git clone git@github.com:tontinetrust/tontine-frontend $FRONTEND_DIR || true
cd "$FRONTEND_DIR"
if [ -z "$(git status --porcelain)" ]
then
  npm i
fi
cd -

newStep 'Install robo-actuary'
BACKEND_DIR="$HOME/robo-actuary"
git clone git@github.com:tontinetrust/robo-actuary "$BACKEND_DIR" || true
cd "$BACKEND_DIR"
if [ -z "$(git status --porcelain)" ]
then
  echo 'use_nix' >> '.envrc'
  direnv allow
  nix-shell --run "echo 'built robo-actuary'"
fi
cd -

#########################
##### FINAL MESSAGE #####
#########################

echo
info 'You may need to logout and login again for some changes to take effect.'
info 'Reboot now if running this script for the first time!'
echo
