#!/bin/bash

# --- Styling ---
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}      🚀 MASTERPLAN DISPATCHER       ${NC}"
echo -e "${CYAN}=====================================${NC}"

# Detect Environment
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    ENV="Windows"
else
    ENV="Linux/WSL"
fi

echo -e "${YELLOW}Detected Environment: $ENV${NC}\n"

options=(
    "System Admin Toolkit (PowerShell)"
    "Network & WSL Toolkit (PowerShell)"
    "Ollama Master Toolkit (Bash)"
    "GitHub CLI Toolkit (Bash)"
    "Update All Submodules (Git)"
    "Exit"
)

# Fix: Added missing closing quote in the prompt string
PS3=$'\n\033[1;33mSelect a script to target: \033[0m'

select opt in "${options[@]}"; do
    case $opt in
        "System Admin Toolkit (PowerShell)")
            echo -e "${GREEN}Launching Windows Toolkit...${NC}"
            # Ensure we target the file on the Dev Drive mount
            powershell.exe -ExecutionPolicy Bypass -File "./windows/toolkit.ps1"
            ;;
        "Network & WSL Toolkit (PowerShell)")
            echo -e "${GREEN}Launching Network Toolkit...${NC}"
            powershell.exe -ExecutionPolicy Bypass -File "./windows/netkit.ps1"
            ;;
        "Ollama Master Toolkit (Bash)")
            bash "./ollama_kit.sh"
            ;;
        "GitHub CLI Toolkit (Bash)")
            bash "./gh_kit.sh"
            ;;
        "Update All Submodules (Git)")
            echo -e "${YELLOW}Syncing Kali and Dotfiles submodules...${NC}"
            git submodule update --init --recursive
            ;;
        "Exit")
            break
            ;;
        *) 
            # Fix: Added missing double semicolons (;;)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
done