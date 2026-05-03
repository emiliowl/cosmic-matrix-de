#!/usr/bin/env bash
# Matrix Terminal Setup: zsh + Oh My Zsh + Powerlevel10k + Nerd Fonts
set -e

GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
NC='\033[0m'

log() { echo -e "${BRIGHT_GREEN}[MATRIX]${GREEN} $1${NC}"; }
log_done() { echo -e "${BRIGHT_GREEN}[MATRIX] ✓ $1${NC}"; }

# ─── 1. Install zsh ───────────────────────────────────────────────────────────
log "Installing zsh..."
sudo apt-get update -qq
sudo apt-get install -y zsh git curl wget unzip fontconfig
log_done "zsh installed: $(zsh --version)"

# ─── 2. Install Oh My Zsh (non-interactive, skip chsh) ───────────────────────
log "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  log_done "Oh My Zsh installed"
else
  log_done "Oh My Zsh already present, skipping"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ─── 3. Install Powerlevel10k ─────────────────────────────────────────────────
log "Installing Powerlevel10k..."
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
  log_done "Powerlevel10k installed"
else
  log_done "Powerlevel10k already present, skipping"
fi

# ─── 4. Install plugins ───────────────────────────────────────────────────────
log "Installing zsh plugins..."

clone_if_missing() {
  local name=$1 url=$2
  local dest="$ZSH_CUSTOM/plugins/$name"
  if [ ! -d "$dest" ]; then
    git clone --depth=1 "$url" "$dest"
    log_done "Plugin: $name"
  else
    log_done "Plugin $name already present, skipping"
  fi
}

clone_if_missing zsh-autosuggestions   https://github.com/zsh-users/zsh-autosuggestions
clone_if_missing zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting
clone_if_missing zsh-completions       https://github.com/zsh-users/zsh-completions
clone_if_missing zsh-history-substring-search https://github.com/zsh-users/zsh-history-substring-search

# ─── 5. Install MesloLGS Nerd Font (p10k recommended) ────────────────────────
log "Installing MesloLGS NF (Nerd Font for p10k)..."
FONT_DIR="$HOME/.local/share/fonts/MesloLGS-NF"
mkdir -p "$FONT_DIR"

BASE_URL="https://github.com/romkatv/powerlevel10k-media/raw/master"
FONTS=(
  "MesloLGS%20NF%20Regular.ttf"
  "MesloLGS%20NF%20Bold.ttf"
  "MesloLGS%20NF%20Italic.ttf"
  "MesloLGS%20NF%20Bold%20Italic.ttf"
)
for font in "${FONTS[@]}"; do
  fname="${font//%20/ }"
  if [ ! -f "$FONT_DIR/$fname" ]; then
    wget -q -O "$FONT_DIR/$fname" "$BASE_URL/$font"
  fi
done
fc-cache -f "$FONT_DIR"
log_done "MesloLGS NF installed to $FONT_DIR"

# ─── 6. Write .zshrc ──────────────────────────────────────────────────────────
log "Writing ~/.zshrc..."
cat > "$HOME/.zshrc" << 'ZSHRC'
# ╔══════════════════════════════════════════════════════════════╗
# ║              THE MATRIX HAS YOU — zshrc config              ║
# ╚══════════════════════════════════════════════════════════════╝

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# p10k instant prompt — keep near the top
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── Plugins ────────────────────────────────────────────────────
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  zsh-history-substring-search
  docker
  npm
  python
  sudo
  extract
  z
)

source "$ZSH/oh-my-zsh.sh"

# ── History ────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY

# ── Matrix color environment ───────────────────────────────────
export TERM=xterm-256color
export COLORTERM=truecolor

# ZSH autosuggestion — matrix green
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#005f00,bold"

# Syntax highlighting — matrix palette
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]='fg=#00FF41'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#ff0000,bold'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#00FF41,bold'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#00cc33'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#00FF41,underline'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#00cc33'
ZSH_HIGHLIGHT_STYLES[path]='fg=#00FF41,underline'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#007700'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#00cc33,bold'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#00FF41,bold'
ZSH_HIGHLIGHT_STYLES[command-substitution]='none'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=#00cc33'
ZSH_HIGHLIGHT_STYLES[process-substitution]='none'
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=#00cc33'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#00aa22'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#00aa22'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='none'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#00cc33'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#00cc33'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#00cc33'
ZSH_HIGHLIGHT_STYLES[rc-quote]='fg=#00cc33'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#00FF41,bold'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#00FF41,bold'
ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#00FF41,bold'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#00FF41'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#00cc33,bold'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#005f00,italic'
ZSH_HIGHLIGHT_STYLES[named-fd]='none'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#00FF41,bold'

# ── History substring search bindings ─────────────────────────
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ── Useful aliases ─────────────────────────────────────────────
alias ls='eza --icons --group-directories-first'
alias ll='eza -lAh --icons --group-directories-first --git'
alias la='eza -A --icons --group-directories-first'
alias l='eza --icons --group-directories-first'
alias lt='eza --icons --tree --level=2'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -pv'
alias df='df -h'
alias free='free -h'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --all'
alias gd='git diff'

# ── Matrix welcome banner ───────────────────────────────────────
if [[ $- == *i* ]]; then
  echo "\033[0;32m"
  echo "  ╔╦╗╦ ╦╔═╗  ╔╦╗╔═╗╔╦╗╦═╗╦═╗ ╦"
  echo "   ║ ╠═╣║╣   ║║║╠═╣ ║ ╠╦╝║╠╩╗╠╩╗"
  echo "   ╩ ╩ ╩╚═╝  ╩ ╩╩ ╩ ╩ ╩╚═╩╩ ╩╩ ╩"
  echo "\033[0;32m  Wake up, $USER... The Matrix has you."
  echo "\033[0m"
fi

# ── p10k config ────────────────────────────────────────────────
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
ZSHRC
log_done ".zshrc written"

# ─── 7. Write .p10k.zsh (Matrix theme) ───────────────────────────────────────
log "Writing ~/.p10k.zsh (Matrix theme)..."
cat > "$HOME/.p10k.zsh" << 'P10K'
# Powerlevel10k — Matrix Edition
# Colors: #00FF41 (matrix green), #003B00 (dark green), #000000 (void black)

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob

  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  autoload -Uz is-at-least && is-at-least 5.1 || return

  # ── Prompt segments ──────────────────────────────────────────
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    os_icon
    context
    dir
    vcs
    newline
    prompt_char
  )

  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status
    command_execution_time
    background_jobs
    virtualenv
    node_version
    go_version
    rust_version
    time
    newline
  )

  # ── Core look ─────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_MODE=nerdfont-complete
  typeset -g POWERLEVEL9K_ICON_PADDING=moderate
  typeset -g POWERLEVEL9K_BACKGROUND=                             # transparent bg
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION='${P9K_VISUAL_IDENTIFIER}'

  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  # ── OS icon ───────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=46          # bright matrix green
  typeset -g POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION='⬡ '

  # ── Prompt char ───────────────────────────────────────────────
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=46
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK_VIINS,ERROR_VIINS}_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK_VICMD,ERROR_VICMD}_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK_VIVIS,ERROR_VIVIS}_CONTENT_EXPANSION='V'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK_VIOWR,ERROR_VIOWR}_CONTENT_EXPANSION='▶'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=

  # ── Directory ─────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_DIR_BACKGROUND=
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=46                      # #00FF00
  typeset -g POWERLEVEL9K_DIR_HOME_FOREGROUND=46
  typeset -g POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND=46
  typeset -g POWERLEVEL9K_DIR_ETC_FOREGROUND=82
  typeset -g POWERLEVEL9K_DIR_DEFAULT_FOREGROUND=76
  typeset -g POWERLEVEL9K_DIR_NOT_WRITABLE_FOREGROUND=196
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=46
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=28
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER=
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=0
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=v3

  # Lock icon for non-writable dirs
  typeset -g POWERLEVEL9K_LOCK_ICON='󰌾'
  typeset -g POWERLEVEL9K_DIR_NOT_WRITABLE_VISUAL_IDENTIFIER_EXPANSION='${P9K_VISUAL_IDENTIFIER}'

  # ── Context (user@host) ───────────────────────────────────────
  typeset -g POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND=34          # dimmer green
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=196
  typeset -g POWERLEVEL9K_CONTEXT_SUDO_FOREGROUND=220
  typeset -g POWERLEVEL9K_CONTEXT_REMOTE_FOREGROUND=46
  typeset -g POWERLEVEL9K_CONTEXT_REMOTE_SUDO_FOREGROUND=196
  typeset -g POWERLEVEL9K_CONTEXT_DEFAULT_CONTENT_EXPANSION='%n@%m'
  typeset -g POWERLEVEL9K_CONTEXT_{ROOT,REMOTE_SUDO}_CONTENT_EXPANSION='%n@%m'
  typeset -g POWERLEVEL9K_ALWAYS_SHOW_CONTEXT=false

  # ── VCS (git) ─────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=' '
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=46
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=226
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=208
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=196
  typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=28
  typeset -g POWERLEVEL9K_VCS_BACKGROUND=

  typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED,UNTRACKED,CONFLICTED,COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=-1

  typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_COLOR=46
  typeset -g POWERLEVEL9K_VCS_LOADING_VISUAL_IDENTIFIER_COLOR=28

  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${${\
    $(( !P9K_CONTENT_VISUAL_IDENTIFIER_EXPANSION ))\
    }:+${P9K_CONTENT_VISUAL_IDENTIFIER_EXPANSION} }${P9K_VCS_HEAD_HASH} ${P9K_CONTENT}'

  # ── Status ────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=46
  typeset -g POWERLEVEL9K_STATUS_OK_VISUAL_IDENTIFIER_EXPANSION='✔'
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=196
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=196
  typeset -g POWERLEVEL9K_STATUS_VERBOSE=true
  typeset -g POWERLEVEL9K_STATUS_VERBOSE_SIGNAME=true

  # ── Execution time ────────────────────────────────────────────
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=1
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=28
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'

  # ── Background jobs ───────────────────────────────────────────
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=true
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=46

  # ── Virtualenv ────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=34
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=

  # ── Node version ──────────────────────────────────────────────
  typeset -g POWERLEVEL9K_NODE_VERSION_FOREGROUND=34
  typeset -g POWERLEVEL9K_NODE_VERSION_PROJECT_ONLY=true

  # ── Go version ────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_GO_VERSION_FOREGROUND=34
  typeset -g POWERLEVEL9K_GO_VERSION_PROJECT_ONLY=true

  # ── Rust version ──────────────────────────────────────────────
  typeset -g POWERLEVEL9K_RUST_VERSION_FOREGROUND=34
  typeset -g POWERLEVEL9K_RUST_VERSION_PROJECT_ONLY=true

  # ── Time ──────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=22
  typeset -g POWERLEVEL9K_TIME_VISUAL_IDENTIFIER_EXPANSION=

  # ── Transient prompt ──────────────────────────────────────────
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=same-dir

  # ── Instant prompt ────────────────────────────────────────────
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  (( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
} always {
  'builtin' 'unset' 'p10k_config_opts'
}
P10K
log_done ".p10k.zsh written (Matrix theme)"

# ─── 8. Install eza (modern ls with icons) ───────────────────────────────────
log "Installing eza..."
if ! command -v eza &>/dev/null; then
  sudo apt-get install -y -qq eza
  log_done "eza installed: $(eza --version | head -1)"
else
  log_done "eza already installed, skipping"
fi

# ─── 9. Set zsh as default shell ─────────────────────────────────────────────
log "Setting zsh as default shell..."
ZSH_PATH="$(which zsh)"
if [ "$SHELL" != "$ZSH_PATH" ]; then
  sudo chsh -s "$ZSH_PATH" "$USER"
  log_done "Default shell set to $ZSH_PATH"
else
  log_done "zsh is already the default shell"
fi


# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BRIGHT_GREEN}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BRIGHT_GREEN}║  Matrix terminal setup complete.                  ║${NC}"
echo -e "${BRIGHT_GREEN}║                                                  ║${NC}"
echo -e "${BRIGHT_GREEN}║  Next steps:                                     ║${NC}"
echo -e "${BRIGHT_GREEN}║  1. Set terminal font to: MesloLGS NF            ║${NC}"
echo -e "${BRIGHT_GREEN}║  2. Set terminal background: #0D0D0D             ║${NC}"
echo -e "${BRIGHT_GREEN}║  3. Set terminal foreground: #00FF41             ║${NC}"
echo -e "${BRIGHT_GREEN}║  4. Log out and back in (or run: exec zsh)       ║${NC}"
echo -e "${BRIGHT_GREEN}╚══════════════════════════════════════════════════╝${NC}"
