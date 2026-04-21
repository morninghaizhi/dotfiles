# dotfiles

morninghaizhi's personal Mac configuration, managed via symbolic links from `~/dotfiles/`.

## Structure

```
~/dotfiles/
├── .gitignore
├── README.md
├── zsh/
│   ├── .zshenv        # PATH, env vars (read in all shells)
│   ├── .zprofile      # Login shell only (currently empty)
│   └── .zshrc         # Interactive shell only (alias, prompt)
└── .config/
    └── starship/
        └── starship.toml
```

## Setup on a new Mac

```bash
# 1. Install Homebrew (Apple Silicon)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install required tools
brew install starship git

# 3. Clone this repository
git clone https://github.com/morninghaizhi/dotfiles.git ~/dotfiles

# 4. Create symbolic links
ln -s ~/dotfiles/zsh/.zshenv ~/.zshenv
ln -s ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -s ~/dotfiles/zsh/.zprofile ~/.zprofile

mkdir -p ~/.config
ln -s ~/dotfiles/.config/starship ~/.config/starship

# 5. Restart terminal
```

## Design principles

- **`.zshenv`** — env vars and PATH. Loaded by all zsh types (interactive, non-interactive, login, non-login).
- **`.zprofile`** — login shell only. Currently empty; kept as a placeholder.
- **`.zshrc`** — interactive-only features (alias, prompt, keybindings, completion).
- **Single source of truth** — actual files live in `~/dotfiles/`; home directory contains symlinks only.

## Editing workflow

```bash
# Edit files in ~/dotfiles/ (or use the symlinked paths — same effect)
nvim ~/dotfiles/zsh/.zshenv

# Reload in current shell
source ~/.zshenv

# Commit & push
cd ~/dotfiles
git add -A
git commit -m "describe the change"
git push
```
