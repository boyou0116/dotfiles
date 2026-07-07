# dotfiles

Personal configuration files for Zsh and Git, optimized for WSL (Windows Subsystem for Linux).

## Contents

| File                     | Symlink target                | Purpose                  |
|--------------------------|--------------------------------|--------------------------|
| `zsh/.zshrc`             | `~/.zshrc`                     | Zsh shell configuration  |
| `git/.gitconfig`         | `~/.gitconfig`                 | Git global configuration |
| `claude/settings.json`   | `~/.claude/settings.json`      | Claude Code settings     |
| `claude/statusline.sh`   | `~/.claude/statusline.sh`      | Claude Code status line  |

---

## Setup

```bash
git clone https://github.com/boyou0116/dotfiles.git ~/dotfiles && ~/dotfiles/install.sh
```

`install.sh` will:
1. Install apt packages (`git`, `zsh`, `bat`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `jq`, `bc`)
2. Install `eza` (adds the [eza apt repo](https://github.com/eza-community/eza/blob/main/INSTALL.md#debian--ubuntu) automatically on distros where it isn't in the default repos yet, e.g. Ubuntu 22.04)
3. Install Emacs via snap (skipped if already present)
4. Install Starship, zoxide, nvm, and the Claude Code CLI (skipped if already present)
5. Symlink `~/.zshrc`, `~/.gitconfig`, and `~/.claude/` configs (backs up any existing files with `.bak`)
6. Set zsh as the default shell

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

### Claude Code (`claude/`)

| File            | Purpose                                                              |
|-----------------|------------------------------------------------------------------------|
| `settings.json` | Enables the `codex@openai-codex` plugin, fullscreen TUI, and points `statusLine` at `statusline.sh` |
| `statusline.sh` | Custom status line: model, repo/branch, git stats, context usage bar, cost, duration, rate limits, token/cache stats |

`statusline.sh` requires `jq` and `bc` (installed by `install.sh`).

---

## Requirements

Ubuntu/Debian (WSL or native) with `snap` available (used to install Emacs). The install script handles all package installation automatically.
