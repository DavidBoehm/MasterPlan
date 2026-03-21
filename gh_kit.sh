#!/bin/bash

# --- Styling Variables ---
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}        🐙 GitHub CLI Toolkit        ${NC}"
echo -e "${CYAN}=====================================${NC}"

# --- Dependency Check & OS-Aware Auto-Install ---
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}GitHub CLI (gh) is not installed. Detecting OS...${NC}"
    
    OS_TYPE=$(uname -s)
    
    if [[ "$OS_TYPE" == *"MINGW"* ]] || [[ "$OS_TYPE" == *"MSYS"* ]] || [[ "$OS_TYPE" == *"CYGWIN"* ]]; then
        # Git Bash / MSYS environment on Windows
        echo -e "${CYAN}Windows environment detected. Installing via winget...${NC}"
        winget install --id GitHub.cli -e --source winget
        
        echo -e "${YELLOW}Installation initiated. You may need to restart this terminal session for 'gh' to be recognized in your PATH.${NC}"
        exit 0
        
    elif [[ "$OS_TYPE" == *"Linux"* ]]; then
        # Linux / WSL environment
        echo -e "${CYAN}Linux environment detected. Installing via apt...${NC}"
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update && sudo apt install gh -y
        
    else
        echo -e "${RED}Unsupported OS for auto-install. Please install manually: https://cli.github.com/${NC}"
        exit 1
    fi
    
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}Installation failed or requires terminal restart.${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ GitHub CLI installed successfully.${NC}"
fi

# --- Authentication Check ---
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}No active session found. Initiating login...${NC}"
    gh auth login
else
    echo -e "${GREEN}✓ Authenticated with GitHub.${NC}"
fi

# --- Interactive Menu ---
PS3=$'\n\033[1;33mSelect an action (1-7): \033[0m'

options=(
    "Clone a Repository"
    "Check Git Status"
    "Fetch Origin"
    "Pull Latest Changes"
    "Quick Commit & Push"
    "Create Pull Request"
    "Exit"
)

select opt in "${options[@]}"; do
    case $opt in
        "Clone a Repository")
            echo -e "\n${CYAN}--- Recent Repositories ---${NC}"
            gh repo list --limit 10
            read -p $'\033[1;32mEnter repo name to clone (e.g., user/repo): \033[0m' repo
            if [ -n "$repo" ]; then
                gh repo clone "$repo"
            fi
            ;;
        "Check Git Status")
            echo -e "\n${CYAN}--- Git Status ---${NC}"
            git status
            ;;
        "Fetch Origin")
            echo -e "\n${YELLOW}Fetching origin...${NC}"
            git fetch origin
            echo -e "${GREEN}Fetch complete.${NC}"
            ;;
        "Pull Latest Changes")
            echo -e "\n${YELLOW}Pulling latest changes...${NC}"
            git pull
            ;;
"Quick Commit & Push")
    echo -e "\n${CYAN}--- Stage, Commit, & Push ---${NC}"
    
    # Check for changes
    if [[ -z $(git status -s) ]]; then
        echo -e "${YELLOW}No changes detected to commit.${NC}"
    else
        git add .
        echo -e "${GREEN}✓ All changes staged.${NC}"
        
        read -p $'\033[1;32mEnter commit message: \033[0m' msg
        if [ -z "$msg" ]; then
            msg="Update: $(date +'%Y-%m-%d %H:%M:%S')"
            echo -e "${YELLOW}Empty message. Using default: $msg${NC}"
        fi
        
        git commit -m "$msg"
        
        echo -e "${YELLOW}Pushing to origin...${NC}"
        git push origin HEAD
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Successfully pushed to GitHub.${NC}"
        else
            echo -e "${RED}✗ Push failed. Check your internet or permissions.${NC}"
        fi
    fi
    ;;
            "Create Pull Request")
            echo -e "\n${YELLOW}Opening PR creation in browser...${NC}"
            gh pr create --web
            ;;
        "Exit")
            echo -e "${CYAN}Exiting toolkit. Goodbye!${NC}"
            break
            ;;
        *) echo -e "${RED}Invalid option $REPLY${NC}";;
    esac
done