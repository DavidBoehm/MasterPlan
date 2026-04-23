#!/bin/bash

# 1. Install system dependencies
echo "Installing Zsh and Stow..."
sudo apt update && sudo apt install -y zsh stow git curl

# 2. Install Oh My Zsh (unattended mode)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 3. Clone custom themes and plugins
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

echo "Installing P10k and Plugins..."
# Powerlevel10k
[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ] && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
# Autosuggestions
[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
# Syntax Highlighting
[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# 4. Stow configurations
echo "Linking dotfiles with Stow..."
cd ~/dotfiles || cd /mnt/d/src/MasterPlan/dotfiles || { echo "Dotfiles not found!"; exit 1; }
# Remove existing .zshrc if it's not a symlink to prevent stow errors
[ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ] && rm "$HOME/.zshrc"
stow zsh

# Fix the symlink to use absolute path
if [ -L "$HOME/.zshrc" ]; then
    echo "Fixing symlink to absolute path..."
    rm "$HOME/.zshrc"
    ln -s "$(pwd)/zsh/.zshrc" "$HOME/.zshrc"
fi

echo "Bootstrap complete! Restart your terminal or run 'zsh'."
