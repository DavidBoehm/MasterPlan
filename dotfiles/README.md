# Dotfiles

Zsh configuration with Oh My Zsh, Powerlevel10k theme, and useful plugins.

## What's Included

### Zsh
Zsh (Z Shell) is an extended Bourne shell with powerful features:
- **Better autocomplete** - smarter, faster tab completion
- **Globbing** - advanced pattern matching for files
- **Spelling correction** - fixes typos in commands
- **Shared history** - commands sync across terminals
- **Path expansion** - type `/u/l/b` → expands to `/usr/local/bin`

### Oh My Zsh
A framework for managing Zsh configuration:
- **200+ plugins** for common tools (git, npm, docker, etc.)
- **Themes** for customizing your prompt
- **Auto-updates** - keeps everything current
- **Aliases** - shortcuts for common commands
- **Tab completion** - works for almost everything

### Powerlevel10k (P10k)
A fast, customizable Zsh theme:
- **Instant prompt** - shows immediately, no lag
- **Git status** - branch, dirty/clean, ahead/behind
- **Icons** - folder icons, git icons, status symbols
- **Segments** - shows user, host, path, git, exit codes, timing
- **Configuration wizard** - run `p10k configure` to customize

### Plugins Installed
- **zsh-autosuggestions** - suggests commands as you type (gray text)
- **zsh-syntax-highlighting** - colorizes commands (green=valid, red=invalid)

## Installation

### Quick Install

```bash
# 1. Clone the repo
git clone https://github.com/DavidBoehm/MasterPlan.git ~/MasterPlan

# 2. Run the bootstrap script
cd ~/MasterPlan/dotfiles
./bootstrap.sh

# 3. Restart your terminal or run
zsh
```

### What the Script Does

1. **Installs system packages** - zsh, stow, git, curl
2. **Installs Oh My Zsh** - framework for zsh (unattended mode)
3. **Installs P10k theme** - clones powerlevel10k to custom themes
4. **Installs plugins** - autosuggestions and syntax-highlighting
5. **Copies config files** - `.zshrc` and `.p10k.zsh` to your home directory

### Manual Install (if bootstrap fails)

```bash
# Install zsh
sudo apt update && sudo apt install -y zsh git curl

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install P10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# Install plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Copy config files
cp ~/MasterPlan/dotfiles/zsh/.zshrc ~/.zshrc
cp ~/MasterPlan/dotfiles/zsh/.p10k.zsh ~/.p10k.zsh
```

## Post-Install

### First Run
When you first start zsh, P10k will launch a configuration wizard:
1. Answer questions about your prompt style
2. Choose icons (nerd fonts recommended)
3. Pick which segments to show
4. Your choices are saved to `~/.p10k.zsh`

### Customize Prompt
Run the wizard again anytime:
```bash
p10k configure
```

### Edit Zsh Config
```bash
# Edit .zshrc
nano ~/.zshrc

# Reload config
source ~/.zshrc
```

### Useful Aliases (included)
| Alias | Command |
|-------|---------|
| `zconf` | Edit `.zshrc` in VS Code and auto-reload |
| `netinfo` | Show local IP, public IP, Ollama status |
| `master` | Run `~/mp/master.sh` |
| `dev` | `cd /mnt/d` |
| `windir` | `cd /mnt/c` |
| `tstart` | Start tmux interactive menu |

### Troubleshooting

**Zsh not showing P10k prompt?**
```bash
# Re-run configuration
p10k configure
```

**Missing icons?**
Install a Nerd Font: https://github.com/ryanoasis/nerd-fonts

**Want to go back to bash?**
```bash
chsh -s /bin/bash
```

**Config not loading?**
Check if files exist:
```bash
ls -la ~/.zshrc ~/.p10k.zsh
```

## File Structure

```
dotfiles/
├── bootstrap.sh      # Installation script
├── README.md         # This file
└── zsh/
    ├── .zshrc        # Main zsh config (plugins, aliases, theme)
    └── .p10k.zsh     # Powerlevel10k theme config (prompt style)
```

## Updating

To update your config after changes:

```bash
cd ~/MasterPlan
git pull origin main
./dotfiles/bootstrap.sh
```

## Uninstall

```bash
# Remove oh-my-zsh
rm -rf ~/.oh-my-zsh

# Remove zsh configs
rm ~/.zshrc ~/.p10k.zsh

# Switch back to bash
chsh -s /bin/bash
```

---

**Note:** These dotfiles are designed for Ubuntu/WSL environments. Some features may need adaptation for other systems.
