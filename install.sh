#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}==>${NC} $*"; }
warn()    { echo -e "${YELLOW}warn:${NC} $*"; }
error()   { echo -e "${RED}error:${NC} $*" >&2; }

link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        warn "Backing up existing $dst → ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    # -n: if dst is already a symlink to a directory, replace the link itself
    # instead of dereferencing it and creating src inside the target dir
    ln -sfn "$src" "$dst"
    info "Linked $dst → $src"
}

is_wsl() { [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version; }

# curl progress for big downloads: a live bar on a terminal, but silent when
# piped (e.g. | tee): the bar repaints via \r, and a log records every repaint
# as another wall of '#'
if [[ -t 2 ]]; then CURL_PROGRESS=(--progress-bar); else CURL_PROGRESS=(-sS); fi

# ── Prerequisites (Ubuntu/Debian) ────────────────────────────────────────────

if command -v apt-get &>/dev/null; then
    info "Installing apt packages..."
    sudo apt-get update -q
    sudo apt-get install -y \
        curl \
        git \
        zsh \
        zsh-autosuggestions \
        zsh-syntax-highlighting \
        tmux \
        bat \
        jq \
        bc \
        fontconfig \
        fonts-noto-core \
        xz-utils \
        build-essential \
        gdb \
        python3-venv \
        unzip \
        zip \
        shellcheck \
        fzf \
        htop \
        tree

    # Tools used by Emacs (init.el): LSP servers and search backends
    info "Installing Emacs external tools..."
    sudo apt-get install -y \
        ripgrep \
        fd-find \
        clangd \
        bear \
        python3-pylsp \
        python3-pip

    if ! command -v eza &>/dev/null; then
        if apt-cache show eza &>/dev/null; then
            info "Installing eza..."
            sudo apt-get install -y eza
        else
            info "eza not in default apt repo, adding eza's apt repo..."
            sudo apt-get install -y gpg
            sudo mkdir -p /etc/apt/keyrings
            # Key is vendored in the repo: raw.githubusercontent.com (its
            # upstream source) aggressively rate-limits and broke installs
            sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg "$DOTFILES_DIR/apt/gierens.asc"
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
                | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
            sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
            sudo apt-get update -q
            sudo apt-get install -y eza
        fi
    else
        info "eza already installed, skipping."
    fi

    # Ghostty terminal: in Ubuntu's own repos from 26.04 (universe). On
    # 24.04+ use the community PPA's native .deb instead (Ghostty needs a
    # newer GTK4 than the distro ships, and the PPA only builds for 24.04+).
    # Anything older falls back to the snap, which bundles its own GTK4
    # stack. Fallbacks are skipped on WSL, where Windows Terminal is the
    # terminal anyway.
    # shellcheck disable=SC1091  # /etc/os-release is provided by the OS
    UBUNTU_VERSION="$(. /etc/os-release && [[ "$ID" == "ubuntu" ]] && echo "${VERSION_ID:-0}" || echo 0)"
    if command -v ghostty &>/dev/null; then
        info "Ghostty already installed, skipping."
    elif dpkg --compare-versions "$UBUNTU_VERSION" ge 26.04; then
        info "Installing Ghostty..."
        sudo apt-get install -y ghostty
    elif [[ "$UBUNTU_VERSION" == 0 ]] || is_wsl; then
        :  # non-Ubuntu or WSL: no Ghostty
    elif dpkg --compare-versions "$UBUNTU_VERSION" ge 24.04; then
        info "Installing Ghostty from the mkasberg/ghostty-ubuntu PPA..."
        sudo apt-get install -y software-properties-common
        sudo add-apt-repository -y ppa:mkasberg/ghostty-ubuntu
        sudo apt-get update -q
        sudo apt-get install -y ghostty
    elif command -v snap &>/dev/null && [[ -d /run/systemd/system ]]; then
        info "Installing Ghostty via snap (no apt package for Ubuntu $UBUNTU_VERSION)..."
        sudo snap install ghostty --classic
    else
        warn "Skipping Ghostty: no apt package for Ubuntu $UBUNTU_VERSION and snap is unavailable."
    fi

    # ibus-rime: Rime input method engine for IBus (config symlinked below
    # enables the bopomofo_tw schema). IBus runs on the desktop, so skip WSL,
    # where typing goes through the Windows-side IME.
    if ! is_wsl; then
        info "Installing ibus-rime..."
        sudo apt-get install -y ibus-rime
    fi
fi

# grip renders Markdown previews for Emacs grip-mode; the apt package named
# "grip" is an unrelated CD ripper, so install from PyPI instead. Prefer pipx:
# PEP 668 (Ubuntu 24.04+) makes pip refuse to touch the system Python.
if ! command -v grip &>/dev/null && [[ ! -x "$HOME/.local/bin/grip" ]]; then
    info "Installing grip (Markdown preview backend)..."
    if apt-cache show pipx &>/dev/null; then
        sudo apt-get install -y pipx
        pipx install grip
    else
        pip3 install --user grip
    fi
else
    info "grip already installed, skipping."
fi

# grip 4.6.2 ships a page template whose <html> lacks the data-color-mode /
# data-*-theme attributes that current GitHub (Primer) CSS needs. Without them
# every color/border custom property (e.g. --borderColor-default) stays
# undefined, so `border: 1px solid var(--borderColor-default)` is invalid and
# tables render with no borders (and washed-out colors). Add the attributes.
# Idempotent and re-run every install so it survives grip upgrades that
# overwrite the template. Handles both the pip --user and pipx venv layouts.
GRIP_BASE="$(find "$HOME/.local/lib" "$HOME/.local/share/pipx/venvs/grip" \
    -name base.html -path '*/grip/templates/*' 2>/dev/null | head -1)"
if [[ -n "$GRIP_BASE" ]] && ! grep -q 'data-color-mode' "$GRIP_BASE"; then
    info "Patching grip template to enable GitHub theme (fixes borderless tables)..."
    sed -i 's|<html lang="en">|<html lang="en" data-color-mode="light" data-light-theme="light" data-dark-theme="dark">|' "$GRIP_BASE"
fi

if ! command -v emacs &>/dev/null; then
    # snap needs a running systemd (not the case on WSL without systemd=true)
    if ! command -v snap &>/dev/null || [[ ! -d /run/systemd/system ]]; then
        error "snap is unavailable (is systemd running?). Enable systemd (WSL: set systemd=true in /etc/wsl.conf) and re-run."
        exit 1
    fi
    info "Installing Emacs via snap..."
    sudo snap install emacs --classic
else
    info "Emacs already installed, skipping."
fi

if ! command -v starship &>/dev/null; then
    info "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
else
    info "Starship already installed, skipping."
fi

if ! command -v zoxide &>/dev/null; then
    info "Installing zoxide..."
    if apt-cache show zoxide &>/dev/null; then
        sudo apt-get install -y zoxide
    else
        # Fallback for distros without the package (installer fetches from
        # raw.githubusercontent.com, which rate-limits aggressively)
        curl -sS --retry 3 https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    fi
else
    info "zoxide already installed, skipping."
fi

if [[ ! -d "$HOME/.nvm" ]]; then
    info "Installing nvm..."
    # Same as nvm's install.sh but without fetching the installer from
    # rate-limited raw.githubusercontent.com (shell setup is in .zshrc)
    git clone --depth 1 --branch v0.39.7 https://github.com/nvm-sh/nvm.git "$HOME/.nvm"
else
    info "nvm already installed, skipping."
fi

# Check the install path too: ~/.local/bin may not be on PATH yet in the
# session that runs this script (Ubuntu adds it at login, only if it exists)
if ! command -v claude &>/dev/null && [[ ! -x "$HOME/.local/bin/claude" ]]; then
    info "Installing Claude Code (the installer is quiet while downloading ~tens of MB; this can take a minute)..."
    curl -fsSL https://claude.ai/install.sh | bash
else
    info "Claude Code already installed, skipping."
fi

# Google Chrome: not in Ubuntu's repos; Google's .deb also registers their apt
# repo (google-chrome.list), so later apt upgrades keep it current. amd64 only —
# Google ships no Linux arm64 build. On WSL the browser lives on the Windows side.
if is_wsl; then
    info "WSL detected, skipping Google Chrome (use the Windows-side browser)."
elif ! command -v apt-get &>/dev/null || [[ "$(dpkg --print-architecture)" != "amd64" ]]; then
    warn "Skipping Google Chrome (needs apt on amd64)."
elif command -v google-chrome &>/dev/null; then
    info "Google Chrome already installed, skipping."
else
    info "Installing Google Chrome..."
    CHROME_TMP="$(mktemp -d)"
    curl -fL --retry 3 "${CURL_PROGRESS[@]}" -o "$CHROME_TMP/google-chrome.deb" \
        "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    # mktemp -d creates a 0700 dir apt's sandbox user (_apt) cannot traverse;
    # grant search (x) permission or apt falls back to root with a noisy warning
    chmod 711 "$CHROME_TMP"
    sudo apt-get install -y "$CHROME_TMP/google-chrome.deb"
    rm -rf "$CHROME_TMP"
fi

# ── Nerd Font (IntoneMono, provides terminal icons for eza/Starship) ─────────

FONT_NAME="IntoneMono"
FONT_ASSET="IntelOneMono.tar.xz"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FONT_ASSET"

download_font() {
    FONT_TMP="$(mktemp -d)"
    info "Downloading $FONT_NAME Nerd Font..."
    curl -fsSL --retry 3 -o "$FONT_TMP/$FONT_ASSET" "$FONT_URL"
    tar -xf "$FONT_TMP/$FONT_ASSET" -C "$FONT_TMP"
}

if is_wsl; then
    # Windows Terminal renders with Windows-side fonts, so install there (per-user, no admin)
    POWERSHELL="$(command -v powershell.exe || true)"
    [[ -z "$POWERSHELL" && -x /mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe ]] \
        && POWERSHELL=/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe
    if [[ -z "$POWERSHELL" ]]; then
        error "powershell.exe not found; cannot install the font into Windows."
        exit 1
    fi
    # shellcheck disable=SC2016  # $env:LOCALAPPDATA is PowerShell syntax, must reach powershell.exe unexpanded
    WIN_FONT_DIR="$(wslpath "$("$POWERSHELL" -NoProfile -Command 'Write-Output "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"' | tr -d '\r')")"
    if compgen -G "$WIN_FONT_DIR/${FONT_NAME}*" > /dev/null; then
        info "$FONT_NAME Nerd Font already installed in Windows, skipping."
    else
        download_font
        info "Installing $FONT_NAME Nerd Font into Windows user fonts..."
        cat > "$FONT_TMP/install-font.ps1" <<'PSEOF'
param([string]$Src)
$dst = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
New-Item -ItemType Directory -Force -Path $dst | Out-Null
$reg = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
if (-not (Test-Path $reg)) { New-Item -Path $reg -Force | Out-Null }
Get-ChildItem -Path (Join-Path $Src '*.ttf') | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $dst -Force
    New-ItemProperty -Path $reg -Name ($_.BaseName + ' (TrueType)') `
        -Value (Join-Path $dst $_.Name) -PropertyType String -Force | Out-Null
}
PSEOF
        # run from /mnt/c so powershell.exe doesn't fall back from a UNC working directory
        (cd /mnt/c && "$POWERSHELL" -NoProfile -ExecutionPolicy Bypass \
            -File "$(wslpath -w "$FONT_TMP/install-font.ps1")" \
            -Src "$(wslpath -w "$FONT_TMP")")
        rm -rf "$FONT_TMP"
        info "Font installed. Select 'IntoneMono Nerd Font' in Windows Terminal → Settings → Appearance."
    fi
else
    FONT_DIR="$HOME/.local/share/fonts/$FONT_NAME"
    if compgen -G "$FONT_DIR/${FONT_NAME}*" > /dev/null; then
        info "$FONT_NAME Nerd Font already installed, skipping."
    else
        download_font
        info "Installing $FONT_NAME Nerd Font to $FONT_DIR..."
        mkdir -p "$FONT_DIR"
        cp "$FONT_TMP"/*.ttf "$FONT_DIR/"
        fc-cache -f "$FONT_DIR"
        rm -rf "$FONT_TMP"
        info "Font installed. Select 'IntoneMono Nerd Font Mono' in your terminal (search 'Intone', no space):"
        info "  - GNOME Terminal (Ubuntu <= 24.04): close ALL windows first (it shares one process),"
        info "    then reopen and pick the font in the profile settings."
        info "  - Ptyxis (default since Ubuntu 25.10): Preferences -> turn off 'Use System Font' -> pick the font."
    fi
fi

# Symbols Nerd Font: icon glyphs for GUI Emacs (nerd-icons/doom-modeline).
# GUI Emacs ignores the terminal font, so it needs this even though
# IntoneMono already bundles the same glyphs for terminal use.
# Font checks: grep must consume all of fc-list's output (no -q). grep -q
# exits at the first match, fc-list dies of SIGPIPE, and pipefail turns that
# into a false "not installed" — re-downloading fonts on every run.
if fc-list | grep -i "Symbols Nerd Font" >/dev/null; then
    info "Symbols Nerd Font already installed, skipping."
else
    SYM_DIR="$HOME/.local/share/fonts/NerdFontsSymbolsOnly"
    SYM_TMP="$(mktemp -d)"
    info "Downloading Symbols Nerd Font (icons for GUI Emacs)..."
    curl -fsSL --retry 3 -o "$SYM_TMP/NerdFontsSymbolsOnly.tar.xz" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz"
    mkdir -p "$SYM_DIR"
    tar -xf "$SYM_TMP/NerdFontsSymbolsOnly.tar.xz" -C "$SYM_DIR"
    fc-cache -f "$SYM_DIR"
    rm -rf "$SYM_TMP"
fi

# Sarasa Mono TC: CJK font for GUI Emacs. init.el maps CJK scripts to it and
# rescales it so one CJK char spans exactly two IntoneMono columns, keeping
# mixed Chinese/English text (e.g. org tables) aligned. Terminal Emacs doesn't
# need it — the terminal grid already forces CJK into 2 cells. Always
# installed Linux-side: GUI Emacs reads Linux fonts even under WSLg.
if fc-list | grep -i "Sarasa Mono TC Nerd Font" >/dev/null; then
    info "Sarasa Mono TC Nerd Font already installed, skipping."
else
    SARASA_DIR="$HOME/.local/share/fonts/SarasaMonoTCNerdFont"
    SARASA_TMP="$(mktemp -d)"
    info "Downloading Sarasa Mono TC Nerd Font (2:1 CJK font for GUI Emacs, ~143 MB)..."
    curl -fL --retry 3 "${CURL_PROGRESS[@]}" -o "$SARASA_TMP/sarasa-mono-tc-nerd-font.zip" \
        "https://github.com/jonz94/Sarasa-Gothic-Nerd-Fonts/releases/latest/download/sarasa-mono-tc-nerd-font.zip"
    mkdir -p "$SARASA_DIR"
    unzip -qo "$SARASA_TMP/sarasa-mono-tc-nerd-font.zip" -d "$SARASA_DIR"
    fc-cache -f "$SARASA_DIR"
    rm -rf "$SARASA_TMP"
fi

# ── Symlinks ─────────────────────────────────────────────────────────────────

info "Creating symlinks..."
link "$DOTFILES_DIR/zsh/.zshrc"        "$HOME/.zshrc"
link "$DOTFILES_DIR/git/.gitconfig"    "$HOME/.gitconfig"
link "$DOTFILES_DIR/emacs/init.el"     "$HOME/.emacs.d/init.el"
link "$DOTFILES_DIR/ghostty/config"    "$HOME/.config/ghostty/config"
link "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES_DIR/tmux/.tmux.conf"   "$HOME/.tmux.conf"
link "$DOTFILES_DIR/rime/default.custom.yaml" "$HOME/.config/ibus/rime/default.custom.yaml"

if [[ -d "$DOTFILES_DIR/claude" ]]; then
    for f in "$DOTFILES_DIR/claude/"*; do
        link "$f" "$HOME/.claude/$(basename "$f")"
    done
fi

# ── GitHub SSH (push access for this repo) ───────────────────────────────────

SSH_KEY="$HOME/.ssh/id_ed25519"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"

if [[ ! -f "$SSH_KEY" ]]; then
    info "Generating SSH key..."
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "$USER@$(hostname)"
fi

# Pre-trust GitHub's host key so the first connection doesn't prompt
if ! grep -q "^github.com" "$HOME/.ssh/known_hosts" 2>/dev/null; then
    ssh-keyscan -t ed25519 github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null
fi

github_ssh_ok() {
    # GitHub exits 1 even on successful auth (no shell access), which
    # pipefail would turn into a false negative — judge by output only
    { ssh -o BatchMode=yes -o ConnectTimeout=10 -T git@github.com 2>&1 || true; } \
        | grep -q "successfully authenticated"
}

if github_ssh_ok; then
    info "GitHub SSH authentication works."
else
    warn "This machine's SSH key is not registered with GitHub yet."
    echo ""
    cat "${SSH_KEY}.pub"
    echo ""
    echo "Add the key above at https://github.com/settings/keys, then press Enter."
    read -rp "(Enter to continue; skipping leaves the remote on HTTPS) " || true
fi

# Switch this repo's remote to SSH once authentication works
REMOTE_URL="$(git -C "$DOTFILES_DIR" remote get-url origin 2>/dev/null || true)"
if [[ "$REMOTE_URL" == https://github.com/* ]]; then
    if github_ssh_ok; then
        info "Switching dotfiles remote to SSH..."
        git -C "$DOTFILES_DIR" remote set-url origin \
            "${REMOTE_URL/https:\/\/github.com\//git@github.com:}"
    else
        warn "GitHub SSH still not working; leaving remote on HTTPS."
    fi
fi

# ── Default shell ─────────────────────────────────────────────────────────────

ZSH_PATH="$(command -v zsh 2>/dev/null || true)"
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [[ -n "$ZSH_PATH" && "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
    info "Changing default shell to zsh..."
    # sudo chsh: reuses cached sudo credentials instead of prompting for a password
    sudo chsh -s "$ZSH_PATH" "$USER"
else
    info "Default shell is already zsh, skipping."
fi

echo ""
info "Done. Log out and back in to apply the default shell change (or run: exec zsh to try zsh now)."
