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
  backup_source_path="$1"
  [ -e "$backup_source_path" ] || [ -L "$backup_source_path" ] || return 0

  ensure_dir "$BACKUP_DIR"
  backup_target_path="$BACKUP_DIR/$(basename "$backup_source_path")"
  info "backing up $backup_source_path to $backup_target_path"
  mv "$backup_source_path" "$backup_target_path"
}

link_file() {
  link_source_path="$1"
  link_target_path="$2"

  [ -f "$link_source_path" ] || die "missing source file: $link_source_path"

  if [ -L "$link_target_path" ]; then
    link_current_target=$(readlink "$link_target_path")
    if [ "$link_current_target" = "$link_source_path" ]; then
      info "already linked: $link_target_path"
      return 0
    fi
  fi

  backup_path "$link_target_path"
  ensure_dir "$(dirname "$link_target_path")"
  ln -s "$link_source_path" "$link_target_path"
  info "linked $link_target_path"
}

install_script() {
  script_source_path="$1"
  script_target_path="$HOME/.local/bin/$(basename "$script_source_path")"

  [ -f "$script_source_path" ] || die "missing script: $script_source_path"
  ensure_dir "$HOME/.local/bin"
  cp "$script_source_path" "$script_target_path"
  chmod 755 "$script_target_path"
  info "installed $(basename "$script_target_path")"
}

write_once() {
  write_path="$1"
  write_content="$2"

  if [ ! -e "$write_path" ]; then
    ensure_dir "$(dirname "$write_path")"
    printf '%s\n' "$write_content" > "$write_path"
    info "created $write_path"
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
