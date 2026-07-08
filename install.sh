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
    ln -sf "$src" "$dst"
    info "Linked $dst → $src"
}

# ── Prerequisites (Ubuntu/Debian) ────────────────────────────────────────────

if command -v apt-get &>/dev/null; then
    info "Installing apt packages..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        curl \
        git \
        zsh \
        zsh-autosuggestions \
        zsh-syntax-highlighting \
        bat \
        jq \
        bc \
        fontconfig \
        xz-utils

    # Tools used by Emacs (init.el): LSP servers and search backends
    info "Installing Emacs external tools..."
    sudo apt-get install -y -qq \
        ripgrep \
        fd-find \
        clangd \
        python3-pylsp \
        python3-pip

    if ! command -v eza &>/dev/null; then
        if apt-cache show eza &>/dev/null; then
            info "Installing eza..."
            sudo apt-get install -y -qq eza
        else
            info "eza not in default apt repo, adding eza's apt repo..."
            sudo apt-get install -y -qq gpg
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
                | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
                | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
            sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
            sudo apt-get update -qq
            sudo apt-get install -y -qq eza
        fi
    else
        info "eza already installed, skipping."
    fi
fi

# grip renders Markdown previews for Emacs grip-mode; the apt package named
# "grip" is an unrelated CD ripper, so install from PyPI instead
if ! command -v grip &>/dev/null && [[ ! -x "$HOME/.local/bin/grip" ]]; then
    info "Installing grip (Markdown preview backend)..."
    pip3 install --user grip
else
    info "grip already installed, skipping."
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
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
else
    info "zoxide already installed, skipping."
fi

if [[ ! -d "$HOME/.nvm" ]]; then
    info "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
else
    info "nvm already installed, skipping."
fi

if ! command -v claude &>/dev/null; then
    info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
else
    info "Claude Code already installed, skipping."
fi

# ── Nerd Font (IntoneMono, provides terminal icons for eza/Starship) ─────────

FONT_NAME="IntoneMono"
FONT_ASSET="IntelOneMono.tar.xz"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FONT_ASSET"

is_wsl() { [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version; }

download_font() {
    FONT_TMP="$(mktemp -d)"
    info "Downloading $FONT_NAME Nerd Font..."
    curl -fsSL -o "$FONT_TMP/$FONT_ASSET" "$FONT_URL"
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
        info "Font installed. To apply: close ALL terminal windows first (GNOME Terminal shares one process),"
        info "then reopen and select 'IntoneMono Nerd Font Mono' in the profile settings (search 'Intone', no space)."
    fi
fi

# Symbols Nerd Font: icon glyphs for GUI Emacs (nerd-icons/doom-modeline).
# GUI Emacs ignores the terminal font, so it needs this even though
# IntoneMono already bundles the same glyphs for terminal use.
if fc-list | grep -qi "Symbols Nerd Font"; then
    info "Symbols Nerd Font already installed, skipping."
else
    SYM_DIR="$HOME/.local/share/fonts/NerdFontsSymbolsOnly"
    SYM_TMP="$(mktemp -d)"
    info "Downloading Symbols Nerd Font (icons for GUI Emacs)..."
    curl -fsSL -o "$SYM_TMP/NerdFontsSymbolsOnly.tar.xz" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz"
    mkdir -p "$SYM_DIR"
    tar -xf "$SYM_TMP/NerdFontsSymbolsOnly.tar.xz" -C "$SYM_DIR"
    fc-cache -f "$SYM_DIR"
    rm -rf "$SYM_TMP"
fi

# ── Symlinks ─────────────────────────────────────────────────────────────────

info "Creating symlinks..."
link "$DOTFILES_DIR/zsh/.zshrc"        "$HOME/.zshrc"
link "$DOTFILES_DIR/git/.gitconfig"    "$HOME/.gitconfig"
link "$DOTFILES_DIR/emacs/init.el"     "$HOME/.emacs.d/init.el"

if [[ -d "$DOTFILES_DIR/claude" ]]; then
    for f in "$DOTFILES_DIR/claude/"*; do
        link "$f" "$HOME/.claude/$(basename "$f")"
    done
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
info "Done. Open a new terminal (or run: exec zsh) to apply changes."
