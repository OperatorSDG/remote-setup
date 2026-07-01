#!/usr/bin/env sh
set -eu

PROFILE="${1:-minimal}"
REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BACKUP_DIR="$HOME/.remote-setup-backup/$(date +%Y%m%d-%H%M%S)"

info() {
  printf '%s\n' "remote-setup: $*"
}

die() {
  printf '%s\n' "remote-setup: error: $*" >&2
  exit 1
}

ensure_dir() {
  [ -d "$1" ] || mkdir -p "$1"
}

backup_path() {
  path="$1"
  [ -e "$path" ] || [ -L "$path" ] || return 0

  ensure_dir "$BACKUP_DIR"
  target="$BACKUP_DIR/$(basename "$path")"
  info "backing up $path to $target"
  mv "$path" "$target"
}

link_file() {
  source="$1"
  target="$2"

  [ -f "$source" ] || die "missing source file: $source"

  if [ -L "$target" ]; then
    current=$(readlink "$target")
    if [ "$current" = "$source" ]; then
      info "already linked: $target"
      return 0
    fi
  fi

  backup_path "$target"
  ensure_dir "$(dirname "$target")"
  ln -s "$source" "$target"
  info "linked $target"
}

install_script() {
  source="$1"
  target="$HOME/.local/bin/$(basename "$source")"

  [ -f "$source" ] || die "missing script: $source"
  ensure_dir "$HOME/.local/bin"
  cp "$source" "$target"
  chmod 755 "$target"
  info "installed $(basename "$target")"
}

write_once() {
  path="$1"
  content="$2"

  if [ ! -e "$path" ]; then
    ensure_dir "$(dirname "$path")"
    printf '%s\n' "$content" > "$path"
    info "created $path"
  fi
}

case "$PROFILE" in
  minimal|dev|server) ;;
  *) die "unknown profile '$PROFILE' (use minimal, dev, or server)" ;;
esac

ensure_dir "$HOME/.config/remote-setup"
ensure_dir "$HOME/.local/bin"
ensure_dir "$HOME/.local/share"
ensure_dir "$HOME/.cache"

printf '%s\n' "$PROFILE" > "$HOME/.config/remote-setup/profile"
printf '%s\n' "$REPO_DIR" > "$HOME/.config/remote-setup/repo-dir"
write_once "$HOME/.config/remote-setup/local.zsh" "# Machine-local shell config. This file is not managed by remote-setup."
write_once "$HOME/.config/remote-setup/gitconfig.local" "# Machine-local Git identity.
# Example:
# [user]
# 	name = Your Name
# 	email = you@example.com"

link_file "$REPO_DIR/dotfiles/zshrc" "$HOME/.zshrc"
link_file "$REPO_DIR/dotfiles/gitconfig" "$HOME/.gitconfig"
link_file "$REPO_DIR/dotfiles/tmux.conf" "$HOME/.tmux.conf"

install_script "$REPO_DIR/scripts/remote-update"
install_script "$REPO_DIR/scripts/remote-doctor"

if [ -f "$REPO_DIR/profiles/$PROFILE.sh" ]; then
  sh "$REPO_DIR/profiles/$PROFILE.sh"
fi

info "installed profile: $PROFILE"
info "open a new shell or run: exec zsh"
