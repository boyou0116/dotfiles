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
        git \
        zsh \
        zsh-autosuggestions \
        zsh-syntax-highlighting \
        bat \
        jq \
        bc

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

if ! command -v emacs &>/dev/null; then
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

# ── Symlinks ─────────────────────────────────────────────────────────────────

info "Creating symlinks..."
link "$DOTFILES_DIR/zsh/.zshrc"        "$HOME/.zshrc"
link "$DOTFILES_DIR/git/.gitconfig"    "$HOME/.gitconfig"

if [[ -d "$DOTFILES_DIR/claude" ]]; then
    for f in "$DOTFILES_DIR/claude/"*; do
        link "$f" "$HOME/.claude/$(basename "$f")"
    done
fi

# ── Default shell ─────────────────────────────────────────────────────────────

ZSH_PATH="$(command -v zsh 2>/dev/null || true)"
if [[ -n "$ZSH_PATH" && "$SHELL" != "$ZSH_PATH" ]]; then
    info "Changing default shell to zsh..."
    chsh -s "$ZSH_PATH"
else
    info "Default shell is already zsh, skipping."
fi

echo ""
info "Done. Open a new terminal (or run: exec zsh) to apply changes."
