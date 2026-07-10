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

# fzf: fuzzy Ctrl-R history search, Ctrl-T file picker, Alt-C cd
# (paths used by the Ubuntu/Debian fzf package)
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi
if [ -f /usr/share/doc/fzf/examples/completion.zsh ]; then
  source /usr/share/doc/fzf/examples/completion.zsh
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
# Ghostty
# =========================

# Ubuntu's Ghostty launcher (D-Bus service and .desktop file) passes
# --shell-integration-features=ssh-env on the command line, which overrides
# the config file's no-cursor and re-enables the integration's bar cursor at
# the prompt. Strip the cursor feature here: the integration only reads
# GHOSTTY_SHELL_FEATURES at the first prompt, after .zshrc has run.
if [[ -n "$GHOSTTY_SHELL_FEATURES" ]]; then
  _ghostty_features=(${(s:,:)GHOSTTY_SHELL_FEATURES})
  export GHOSTTY_SHELL_FEATURES=${(j:,:)_ghostty_features:#cursor*}
  unset _ghostty_features
fi

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

alias ls='eza --icons --group-directories-first'
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
