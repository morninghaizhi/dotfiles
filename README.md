# dotfiles

morninghaizhi's personal Mac configuration, managed via symbolic links from `~/dotfiles/`.

## Structure

```
~/dotfiles/
├── .gitignore
├── README.md
├── zsh/
│   ├── .zshenv        # Env vars except PATH (read in all shells)
│   ├── .zprofile      # PATH / toolchains (login shell, after path_helper)
│   ├── .zprofile.local.example  # Template for ~/.zprofile.local (machine-specific, untracked)
│   └── .zshrc         # Interactive shell only (alias, prompt)
├── .config/
│   ├── aerospace/
│   │   └── aerospace.toml   # AeroSpace tiling window manager
│   ├── ghostty/
│   │   └── config           # Ghostty terminal
│   ├── git/
│   │   ├── config           # Shared git config (delta, merge/push/fetch). user/credential stay in ~/.gitconfig
│   │   └── ignore           # Global gitignore (don't set core.excludesfile, or this file is skipped)
│   ├── herdr/
│   │   └── config.toml      # herdr agent multiplexer (runs inside Ghostty)
│   ├── lazygit/
│   │   └── config.yml       # lazygit TUI (loaded via LG_CONFIG_FILE)
│   ├── sketchybar/
│   │   ├── sketchybarrc     # SketchyBar status bar (shows AeroSpace workspaces)
│   │   └── plugins/
│   ├── starship/
│   │   └── starship.toml
│   └── wezterm/
│       ├── wezterm.lua      # WezTerm terminal
│       ├── keybinds.lua
│       └── session-restore/ # wz-session.py (session state JSON is gitignored)
└── zmk-config-roBa/    # git submodule — keyboard firmware config (builds on its own GitHub Actions)
```

## Setup on a new Mac

```bash
# 1. Install Homebrew (Apple Silicon)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install required tools
brew install starship git
brew install --cask nikitabobko/tap/aerospace
brew install FelixKratz/formulae/sketchybar FelixKratz/formulae/borders
brew install --cask font-hack-nerd-font   # icons used by SketchyBar
brew install --cask ghostty
brew install herdr
brew install --cask codex   # OpenAI Codex CLI (a second agent to drive from herdr)
brew install lazygit git-delta fzf gh   # git TUI / diff pager / fuzzy finder / GitHub CLI

# 3. Clone this repository (--recurse-submodules to also fetch zmk-config-roBa)
git clone --recurse-submodules https://github.com/morninghaizhi/dotfiles.git ~/dotfiles
# Already cloned without it? Run: git submodule update --init --recursive

# 4. Create symbolic links
ln -s ~/dotfiles/zsh/.zshenv ~/.zshenv
ln -s ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -s ~/dotfiles/zsh/.zprofile ~/.zprofile

mkdir -p ~/.config
ln -s ~/dotfiles/.config/starship ~/.config/starship
ln -s ~/dotfiles/.config/aerospace ~/.config/aerospace
ln -s ~/dotfiles/.config/sketchybar ~/.config/sketchybar
ln -s ~/dotfiles/.config/ghostty ~/.config/ghostty
# herdr writes logs into ~/.config/herdr, so link the file only
mkdir -p ~/.config/herdr
ln -s ~/dotfiles/.config/herdr/config.toml ~/.config/herdr/config.toml
ln -s ~/dotfiles/.config/wezterm ~/.config/wezterm
ln -s ~/dotfiles/.config/lazygit ~/.config/lazygit
mkdir -p ~/.config/git
ln -s ~/dotfiles/.config/git/config ~/.config/git/config
ln -s ~/dotfiles/.config/git/ignore ~/.config/git/ignore

# AeroSpace: launch once and grant Accessibility permission
# (System Settings → Privacy & Security → Accessibility)
open -a AeroSpace

# SketchyBar: start as a service, then allow it in
# System Settings → General → Login Items & Extensions → Allow in the Background
# Also hide the macOS menu bar (Control Center → Automatically hide and show the menu bar → Always)
brew services start sketchybar

# herdr: Claude Code / Codex integrations (hooks in ~/.claude, ~/.codex) and agent skill
# Re-run both after `brew upgrade herdr` to keep them in sync with the binary
herdr integration install claude
mkdir -p ~/.claude/skills/herdr
herdr --skill > ~/.claude/skills/herdr/SKILL.md
herdr integration install codex
mkdir -p ~/.codex/skills/herdr
herdr --skill > ~/.codex/skills/herdr/SKILL.md

# 5. Restart terminal
```

## Design principles

- **`.zshenv`** — env vars except PATH. Loaded by all zsh types (interactive, non-interactive, login, non-login). PATH set here would be reordered by `/etc/zprofile` (`path_helper`).
- **`.zprofile`** — PATH and toolchain locations. Login shell only, read after `path_helper`, so the intended order survives. Non-login, non-interactive shells (scripts, `ssh host cmd`) don't get Homebrew on PATH.
- **`~/.zprofile.local` / `~/.zshrc.local`** — machine-specific settings (e.g. Android SDK / JDK paths). Sourced at the end of `.zprofile` / `.zshrc` if present; never committed. Start from `zsh/.zprofile.local.example`.
- **Guards** — every external command (`brew`, `mise`, `fzf`, `starship`) is checked before use, so a machine without them starts silently.
- **`.zshrc`** — interactive-only features (alias, prompt, keybindings, completion).
- **Single source of truth** — actual files live in `~/dotfiles/`; home directory contains symlinks only.
- **`zmk-config-roBa`** — a git submodule, not a symlinked dotfile. It stays a standalone repo so its own GitHub Actions keep building the keyboard firmware (`.uf2`); dotfiles only pins which commit to use.

## Updating the keyboard config (zmk-config-roBa)

```bash
cd ~/dotfiles/zmk-config-roBa
# edit keymap / config, then commit & push inside the submodule
git add -A && git commit -m "tweak keymap" && git push   # triggers firmware build on GitHub

# back in dotfiles, record the new submodule commit
cd ~/dotfiles
git add zmk-config-roBa && git commit -m "chore: bump zmk-config-roBa"
```

## Editing workflow

```bash
# Edit files in ~/dotfiles/ (or use the symlinked paths — same effect)
nvim ~/dotfiles/zsh/.zshenv

# Reload in current shell (or just open a new terminal)
source ~/.zshenv && source ~/.zprofile && source ~/.zshrc

# Commit & push
cd ~/dotfiles
git add -A
git commit -m "describe the change"
git push
```
