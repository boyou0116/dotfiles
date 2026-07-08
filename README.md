# dotfiles

Personal configuration files for Zsh, Git, Emacs, and Claude Code. Works on native Ubuntu and WSL (Windows Subsystem for Linux).

## Contents

| File                     | Symlink target                | Purpose                  |
|--------------------------|--------------------------------|--------------------------|
| `zsh/.zshrc`             | `~/.zshrc`                     | Zsh shell configuration  |
| `git/.gitconfig`         | `~/.gitconfig`                 | Git global configuration |
| `emacs/init.el`          | `~/.emacs.d/init.el`           | Emacs configuration      |
| `claude/settings.json`   | `~/.claude/settings.json`      | Claude Code settings     |
| `claude/statusline.sh`   | `~/.claude/statusline.sh`      | Claude Code status line  |

---

## Setup

On a fresh machine, install `git` first (Ubuntu Desktop doesn't ship it):

```bash
sudo apt update && sudo apt install -y git
```

Then:

```bash
git clone https://github.com/boyou0116/dotfiles.git ~/dotfiles && ~/dotfiles/install.sh
```

`install.sh` will:
1. Install apt packages (`curl`, `git`, `zsh`, `tmux`, `bat`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `jq`, `bc`, `fontconfig`, `fonts-noto-core`, `xz-utils`)
2. Install the external tools Emacs needs (`ripgrep`, `fd-find`, `clangd`, `python3-pylsp` via apt; `grip` via PyPI — the apt package named `grip` is an unrelated CD ripper)
3. Install `eza` (adds the [eza apt repo](https://github.com/eza-community/eza/blob/main/INSTALL.md#debian--ubuntu) automatically on distros where it isn't in the default repos yet, e.g. Ubuntu 22.04)
4. Install Emacs via snap (skipped if already present; aborts with an error if snap/systemd is unavailable)
5. Install Starship, zoxide, nvm, and the Claude Code CLI (skipped if already present)
6. Install [IntoneMono Nerd Font](https://www.nerdfonts.com/) — provides the icons used by `eza --icons` and Starship. On WSL it is installed into Windows per-user fonts via PowerShell (no admin needed); on native Linux into `~/.local/share/fonts`. Afterwards, close **all** terminal windows (GNOME Terminal shares one process), reopen, and select **IntoneMono Nerd Font Mono** in the terminal's profile settings (search "Intone", no space)
7. Install Symbols Nerd Font — icon glyphs for GUI Emacs, which ignores the terminal font (`init.el` sets its own frame font)
8. Symlink `~/.zshrc`, `~/.gitconfig`, `~/.emacs.d/init.el`, and `~/.claude/` configs (backs up any existing files with `.bak`)
9. Set up GitHub SSH: generate an ed25519 key if missing, print the public key for you to add at [github.com/settings/keys](https://github.com/settings/keys), and switch this repo's remote from HTTPS to SSH once authentication works (press Enter to skip — the remote then stays on HTTPS and you can re-run later)
10. Set zsh as the default shell

> **Note:** Edit `git/.gitconfig` to replace `name` and `email` under `[user]` with your own before running.

---

## What's configured

### Zsh (`zsh/.zshrc`)

**History**
- 1000-line history saved to `~/.zsh_history`
- Deduplication and history sharing across sessions (`histignorealldups sharehistory`)

**Completion**
- Smart tab completion with approximate matching and case-insensitive fallback
- Menu-style selection (`menu select=2`)
- Completion cache refreshed once every 24 hours for faster shell startup

**Plugins** (sourced automatically if installed)
- [`zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions) — ghost-text suggestions from history
- [`zsh-syntax-highlighting`](https://github.com/zsh-users/zsh-syntax-highlighting) — real-time command highlighting

**Prompt & navigation**
- [Starship](https://starship.rs) prompt (`starship init zsh`)
- [zoxide](https://github.com/ajeetdsouza/zoxide) smart `cd` (`zoxide init zsh`)

**PATH (WSL)**
- Ensures `~/.local/bin` and `/snap/bin` are on `$PATH`

**NVM**
- Loads [nvm](https://github.com/nvm-sh/nvm) and its Bash completion if `~/.nvm` exists

**Aliases**

| Alias | Expands to                                     | Notes                                                                |
|-------|------------------------------------------------|----------------------------------------------------------------------|
| `ls`  | `eza --icons --group-directories-first`        | Requires [eza](https://github.com/eza-community/eza)                 |
| `bat` | `batcat`                                       | Debian/Ubuntu package name for [bat](https://github.com/sharkdp/bat) |
| `pip` | `python3 -m pip`                               | Avoids bare `pip` ambiguity                                          |
| `gs`  | `git status`                                   |                                                                      |
| `gc`  | `git commit`                                   |                                                                      |
| `gp`  | `git push`                                     |                                                                      |
| `gl`  | `git pull`                                     |                                                                      |

---

### Git (`git/.gitconfig`)

| Setting          | Value     |
|------------------|-----------|
| Default editor   | `emacs`   |
| Default branch   | `main`    |
| Diff tool        | `vimdiff` |
| Diff tool prompt | disabled  |

---

### Emacs (`emacs/init.el`)

- Packages auto-install on first launch via `package.el` + `use-package` (`use-package-always-ensure`) — the first launch takes a few minutes and prints compile warnings; that's normal. A transient `compat-31` activation error on the very first run heals itself on the next launch
- Completion stack: vertico + orderless + marginalia + consult + embark, corfu (+ corfu-terminal in TTY) with cape
- LSP via eglot for C/C++ (clangd with `--query-driver`), Python, Go, and Haskell
- magit, avy, which-key, windmove, recentf/savehist persistence
- UI: modus-vivendi theme, doom-modeline, line numbers, no menu/tool/scroll bars
- Customize output is redirected to `~/.emacs.d/custom.el` (machine-local, not version-controlled)

---

### Claude Code (`claude/`)

| File            | Purpose                                                              |
|-----------------|------------------------------------------------------------------------|
| `settings.json` | Enables the `codex@openai-codex` plugin, fullscreen TUI, and points `statusLine` at `statusline.sh` |
| `statusline.sh` | Custom status line: model, repo/branch, git stats, context usage bar, cost, duration, rate limits, token/cache stats |

`statusline.sh` requires `jq` and `bc` (installed by `install.sh`).

---

## Requirements

Ubuntu/Debian (WSL or native) with `snap` available (used to install Emacs — requires a running systemd; on WSL set `systemd=true` in `/etc/wsl.conf`). The install script handles all package installation automatically.
