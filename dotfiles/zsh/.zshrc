# List of plugins to auto-install
PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
if [ ! -d "$PLUGINS_DIR/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions $PLUGINS_DIR/zsh-autosuggestions
fi
if [ ! -d "$PLUGINS_DIR/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting $PLUGINS_DIR/zsh-syntax-highlighting
fi

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt beep
# End of lines configured by zsh-newuser-install

# The following lines were added by compinstall
zstyle :compinstall filename '/home/dboehm/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

# -----------------------------
# Oh My Zsh + plugins + theme
# -----------------------------
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(git z zsh-autosuggestions zsh-syntax-highlighting aliases history sudo copypath copyfile web-search common-aliases)

# Disable auto-update prompts from Oh My Zsh
DISABLE_AUTO_UPDATE="true"

# Prompt and completion settings
autoload -U compinit
compinit

# Source Oh My Zsh
if [ -f "$ZSH/oh-my-zsh.sh" ]; then
	source "$ZSH/oh-my-zsh.sh"
fi

# Source Powerlevel10k user config if present
if [ -f "$HOME/.p10k.zsh" ]; then
	source "$HOME/.p10k.zsh"
fi

# If Powerlevel10k is installed in the custom themes directory but not loaded,
# source its main theme file so the `p10k` function and prompt are defined.
if [ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme" ]; then
	source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme"
fi

# zsh-autosuggestions config
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# zsh-syntax-highlighting: must be loaded last
if [ -f "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
	source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


function zconf() {
    echo "Opening .zshrc in VS Code... (Terminal will resume when tab is closed)"
    code --wait ~/.zshrc
    echo "Changes detected. Reloading zsh configuration..."
    source ~/.zshrc
    echo "Done! Your terminal is now up to date."
}

#alias nanobot='~/nanobot-agent/venv/bin/nanobot'
export PATH="$HOME/.local/bin:$PATH"
# export PATH="/home/linuxbrew/.linuxbrew/bin/openclaw:$PATH"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# OpenClaw Completion
source "/home/dboehm/.openclaw/completions/openclaw.zsh"

export OLLAMA_HOST=127.0.0.1:11434

# --- Network Intel Alias ---
alias netinfo='echo -e "\e[1;34m--- NETWORK INTEL ---\e[0m"; \
echo -ne "\e[1;32mLocal IP:   \e[0m"; hostname -I | awk "{print \$1}"; \
echo -ne "\e[1;32mPublic IP:  \e[0m"; curl -s https://ifconfig.me; echo ""; \
echo -ne "\e[1;32mOllama:     \e[0m"; if netstat -tuln | grep -q ":11434 "; then echo -e "\e[1;32mONLINE (0.0.0.0)\e[0m"; else echo -e "\e[1;31mOFFLINE\e[0m"; fi; \
echo -e "\e[1;34m---------------------\e[0m"'

# Quick access to the launcher on the Dev Drive
alias master='bash ~/mp/master.sh'

# Quick jump to the source folder
alias dev='cd /mnt/d'

# Quick jump to Windows C: drive
alias windir='cd /mnt/c'

# Tmux starter interactive menu
alias tstart='~/tmux-starter.sh'

# Split-pane setup for watching processes + working
alias splitwork='tmux split-window -h; tmux select-layout even-horizontal; echo "Split ready: Left pane = processes, Right pane = interactive"'

# Spawn a background process pane while keeping current pane interactive  
alias bgpane='tmux split-window -v "$(command -v btop 2>/dev/null || command -v htop 2>/dev/null || echo top)" 2>/dev/null || tmux split-window -v; tmux select-pane -U; echo "Bottom pane running system monitor, you keep top pane"'

# Spin up 4 bot tmux sessions
alias botfarm='for i in 1 2 3 4; do tmux new-session -d -s bot_$i 2>/dev/null || echo "bot_$i already exists"; done; tmux list-sessions | grep bot_'

# Single window with 4 panes (2x2 grid)
alias botpanes='tmux new-session -d -s botfarm 2>/dev/null; \
tmux split-window -h -t botfarm; \
tmux split-window -v -t botfarm:0.0; \
tmux split-window -v -t botfarm:0.1; \
tmux select-layout -t botfarm tiled; \
echo "botfarm session ready with 4 panes"; \
tmux attach -t botfarm'

# Dotfiles management
alias dotsync="~/dotfiles/bootstrap.sh"
alias pushdots='cd ~/dotfiles && git add . && git commit -m "update dots" && git push && cd -'
