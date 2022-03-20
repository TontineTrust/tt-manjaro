#!/usr/bin/env bash
set -euo pipefail

newStep() {
  echo
  echo "⚙️  TontineTrust install step:"
  echo "⚙️    $1"
  echo
}

newStep 'tontine-frontend'
pamac install --no-confirm nodejs
FRONTEND_DIR="$HOME/tontine-frontend"
su "$SUDO_USER" -c "git clone git@github.com:tontinetrust/tontine-frontend $FRONTEND_DIR || true"
cd "$FRONTEND_DIR"
if [ ! -z "$(git status --porcelain)" ]
then
  npm i
fi
cd -

newStep 'robo-actuary'
BACKEND_DIR="$HOME/robo-actuary"
git clone git@github.com:tontinetrust/robo-actuary "$BACKEND_DIR" || true
cd "$BACKEND_DIR"
if [ ! -z "$(git status --porcelain)" ]
then
  echo 'use_nix' >> '.envrc'
  direnv allow
  direnv reload
fi
cd -
