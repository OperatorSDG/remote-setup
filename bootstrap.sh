#!/usr/bin/env sh
set -eu

REMOTE_SETUP_DIR="${REMOTE_SETUP_DIR:-$HOME/.remote-setup}"
PROFILE="${1:-minimal}"

if [ ! -d "$REMOTE_SETUP_DIR" ]; then
  printf '%s\n' "remote-setup: clone this repo to $REMOTE_SETUP_DIR first, then run ./install.sh $PROFILE" >&2
  exit 1
fi

exec "$REMOTE_SETUP_DIR/install.sh" "$PROFILE"

