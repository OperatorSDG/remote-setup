# Remote Setup

Clean, portable user-level development environment for remote machines.

This repo is intentionally small. It does not import local dotfiles, secrets, machine-specific package state, or host-specific aliases. The base setup should be safe to run repeatedly on servers where you only control your own user account.

## Install

Clone the repo on a remote host:

```sh
git clone <repo-url> ~/.remote-setup
cd ~/.remote-setup
./install.sh minimal
```

Profiles:

- `minimal`: shell, Git, tmux, local bin, update command
- `dev`: minimal plus optional runtime-manager hooks
- `server`: minimal with conservative server-friendly defaults

The installer is idempotent. Existing files are moved to `~/.remote-setup-backup/<timestamp>/` before symlinks are created.

## What It Manages

Linked files:

- `~/.zshrc` -> `dotfiles/zshrc`
- `~/.gitconfig` -> `dotfiles/gitconfig`
- `~/.tmux.conf` -> `dotfiles/tmux.conf`

Installed scripts:

- `~/.local/bin/remote-update`
- `~/.local/bin/remote-doctor`

Local-only machine config:

- `~/.config/remote-setup/local.zsh`
- `~/.config/remote-setup/profile`

## Update

```sh
remote-update
```

This pulls the latest repo changes when the repo has a Git remote, then reruns the installer with the saved profile.

## Local Overrides

Put machine-specific settings here:

```sh
~/.config/remote-setup/local.zsh
```

Examples:

```sh
export WORKON_HOME="$HOME/work"
alias logs='journalctl --user -n 200'
```

Do not commit secrets or host-specific paths into this repo.

