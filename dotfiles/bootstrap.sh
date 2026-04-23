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

# 4. Copy dotfiles to home directory
echo "Copying dotfiles to home directory..."

# Find dotfiles directory
if [ -d "$HOME/MasterPlan/dotfiles" ]; then
    DOTFILES_DIR="$HOME/MasterPlan/dotfiles"
elif [ -d "/mnt/d/src/MasterPlan/dotfiles" ]; then
    DOTFILES_DIR="/mnt/d/src/MasterPlan/dotfiles"
elif [ -d "$HOME/dotfiles" ]; then
    DOTFILES_DIR="$HOME/dotfiles"
else
    echo "Dotfiles not found!"
    exit 1
fi

echo "Using dotfiles at: $DOTFILES_DIR"

# Copy zsh config files to home directory (not symlink, actual copy)
if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
    echo "Copying .zshrc..."
    cp "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
    echo "Copied: .zshrc"
fi

if [ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]; then
    echo "Copying .p10k.zsh..."
    cp "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
    echo "Copied: .p10k.zsh"
fi

# Verify files exist
echo ""
echo "Verifying files in home directory:"
ls -la "$HOME/.zshrc" "$HOME/.p10k.zsh" 2>/dev/null || echo "Files not found!"

echo ""
echo "Bootstrap complete! Restart your terminal or run 'zsh'."
echo "If Powerlevel10k doesn't show, run: p10k configure"
