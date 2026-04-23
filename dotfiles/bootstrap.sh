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

# Find dotfiles directory using absolute paths
if [ -d "$HOME/dotfiles" ]; then
    DOTFILES_DIR="$HOME/dotfiles"
elif [ -d "/mnt/d/src/MasterPlan/dotfiles" ]; then
    DOTFILES_DIR="/mnt/d/src/MasterPlan/dotfiles"
else
    echo "Dotfiles not found!"
    exit 1
fi

echo "Using dotfiles at: $DOTFILES_DIR"
cd "$DOTFILES_DIR" || exit 1

# Remove existing .zshrc if it's not a symlink to prevent stow errors
if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
    echo "Backing up existing .zshrc..."
    mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
fi

# Remove broken symlink if exists
if [ -L "$HOME/.zshrc" ] && [ ! -e "$HOME/.zshrc" ]; then
    echo "Removing broken symlink..."
    rm "$HOME/.zshrc"
fi

# Run stow
stow zsh

# FIX: Ensure .zshrc uses absolute path, not relative
echo "Fixing .zshrc symlink to use absolute path..."
if [ -L "$HOME/.zshrc" ]; then
    rm "$HOME/.zshrc"
fi

# Create absolute path symlink using $HOME
ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

echo "Created: $HOME/.zshrc -> $DOTFILES_DIR/zsh/.zshrc"
ls -la "$HOME/.zshrc"

echo "Bootstrap complete! Restart your terminal or run 'zsh'."
