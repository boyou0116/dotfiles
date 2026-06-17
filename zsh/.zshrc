# =========================
# Basic Settings
# =========================

# History
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history
setopt histignorealldups sharehistory

# Keybinding (Emacs style)
bindkey -e

# =========================
# Completion
# =========================

autoload -Uz compinit

if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more, or type to insert%s'
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
zstyle ':completion:*' verbose true

# Colors
eval "$(dircolors -b)"

# =========================
# Plugins (WSL common)
# =========================

# Autosuggestions
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Syntax Highlighting
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# =========================
# PATH Fix (WSL)
# =========================

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

case ":$PATH:" in
    *":/snap/bin:"*) ;;
    *) export PATH="/snap/bin:$PATH" ;;
esac

[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-env

# =========================
# NVM (optional)
# =========================

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# =========================
# Prompt
# =========================

autoload -Uz add-zsh-hook

# function build_prompt() {
#   local venv=""
# 
#   # Python venv
#   if [[ -n "$VIRTUAL_ENV" ]]; then
#     venv="($(basename $VIRTUAL_ENV)) "
#   fi
# 
#   PROMPT="${venv}%F{cyan}%~%f %# "
# }
# 
# add-zsh-hook precmd build_prompt

# Setup zoxide on zsh
eval "$(zoxide init zsh)"

# setup starship on zsh
eval "$(starship init zsh)"

# =========================
# Aliases
# =========================

alias ls='eza --icons --grid --group-directories-first'
alias bat='batcat'

# Python
alias pip='python3 -m pip'

# Git
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'

# Find
alias fd='fdfind'

# =========================
# End
# =========================
