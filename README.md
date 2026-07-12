# dotfiles

Personal configuration files for Zsh, Git, Emacs, and Claude Code. Works on native Ubuntu and WSL (Windows Subsystem for Linux).

## Contents

| File                     | Symlink target                | Purpose                  |
|--------------------------|--------------------------------|--------------------------|
| `zsh/.zshrc`             | `~/.zshrc`                     | Zsh shell configuration  |
| `git/.gitconfig`         | `~/.gitconfig`                 | Git global configuration |
| `emacs/init.el`          | `~/.emacs.d/init.el`           | Emacs configuration      |
| `ghostty/config`         | `~/.config/ghostty/config`     | Ghostty terminal configuration |
| `rime/default.custom.yaml` | `~/.config/ibus/rime/default.custom.yaml` | Rime input method (ibus-rime) overrides |
| `tmux/.tmux.conf`        | `~/.tmux.conf`                 | tmux configuration       |
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
1. Install apt packages (`curl`, `git`, `zsh`, `tmux`, `bat`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `jq`, `bc`, `fontconfig`, `fonts-noto-core`, `xz-utils`, `build-essential`, `gdb`, `python3-venv`, `unzip`, `zip`, `shellcheck`, `fzf`, `htop`, `tree`)
2. Install the external tools Emacs needs (`ripgrep`, `fd-find`, `clangd`, `python3-pylsp` via apt; `grip` from PyPI via pipx — the apt package named `grip` is an unrelated CD ripper, and PEP 668 (Ubuntu 24.04+) forbids bare `pip install`)
3. Install `eza` (adds the [eza apt repo](https://github.com/eza-community/eza/blob/main/INSTALL.md#debian--ubuntu) automatically on distros where it isn't in the default repos yet, e.g. Ubuntu 22.04)
4. Install [Ghostty](https://ghostty.org) on Ubuntu 26.04 or newer (where it's packaged in `universe`); skipped on earlier releases
5. Install [ibus-rime](https://rime.im) (Traditional Chinese input via the Rime engine); skipped on WSL, where typing goes through the Windows-side IME. After install, add the input source in GNOME Settings → Keyboard → **Chinese (Rime)**
6. Install Google Chrome from Google's `.deb` (which also registers Google's apt repo for updates); skipped on WSL and non-amd64
7. Install Emacs via snap (skipped if already present; aborts with an error if snap/systemd is unavailable)
8. Install Starship, zoxide, nvm, and the Claude Code CLI (skipped if already present)
9. Install [IntoneMono Nerd Font](https://www.nerdfonts.com/) — provides the icons used by `eza --icons` and Starship. On WSL it is installed into Windows per-user fonts via PowerShell (no admin needed); on native Linux into `~/.local/share/fonts`. Afterwards, close **all** terminal windows (GNOME Terminal shares one process), reopen, and select **IntoneMono Nerd Font Mono** in the terminal's profile settings (search "Intone", no space)
10. Install Symbols Nerd Font — icon glyphs for GUI Emacs, which ignores the terminal font (`init.el` sets its own frame font)
11. Symlink `~/.zshrc`, `~/.gitconfig`, `~/.emacs.d/init.el`, `~/.config/ghostty/config`, `~/.tmux.conf`, `~/.config/ibus/rime/default.custom.yaml`, and `~/.claude/` configs (backs up any existing files with `.bak`)
12. Set up GitHub SSH: generate an ed25519 key if missing, print the public key for you to add at [github.com/settings/keys](https://github.com/settings/keys), and switch this repo's remote from HTTPS to SSH once authentication works (press Enter to skip — the remote then stays on HTTPS and you can re-run later)
13. Set zsh as the default shell

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

> **Per-machine step:** the fullscreen TUI copies on mouse selection by default. That toggle lives in `~/.claude.json` (machine-local state, not syncable via `settings.json`), so on each new machine run `/config` in Claude Code and turn **Copy on select** off — copying is then explicit via `Ctrl+Shift+C`, matching the tmux/terminal setup.

---

### tmux (`tmux/.tmux.conf`)

- Mouse mode on: the wheel scrolls tmux's scrollback instead of being translated into arrow keys (which cycles shell history at a prompt). Hold **Shift** while selecting for the terminal's native copy
- `set-clipboard off`: tmux selections stay in tmux's own buffer (paste with `prefix+]`) and never touch the system clipboard, so stray selections can't clobber it. Copy to the system clipboard explicitly: **Shift+drag** (terminal-native selection), then **Ctrl+Shift+C** / paste with **Ctrl+Shift+V**

---

### Rime (`rime/default.custom.yaml`)

- Trims the enabled schema list to **bopomofo_tw** (注音・臺灣) only
- Machine state stays local and out of the repo: `user.yaml`, `installation.yaml`, `build/`, and `*.userdb/` are all generated by Rime
- After editing the config, redeploy: IBus input switcher menu → **Deploy** (部署)

---

## Requirements

Ubuntu/Debian (WSL or native) with `snap` available (used to install Emacs — requires a running systemd; on WSL set `systemd=true` in `/etc/wsl.conf`). The install script handles all package installation automatically.
