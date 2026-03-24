#!/bin/bash

# --- Styling Variables ---
# Matches your ollama_kit.sh and gh_kit.sh
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}      📊 Git Repo Data Exporter      ${NC}"
echo -e "${CYAN}=====================================${NC}"

# Define export directory
EXPORT_DIR="./repo_reports"
mkdir -p "$EXPORT_DIR"

PS3=$'\n\033[1;33mSelect data to export/view (1-7): \033[0m'

options=(
    "Export Visual Branch Tree"
    "Export Detailed Change Log (JSON-style)"
    "List All Tracked Files"
    "Identify Largest Files in Repo"
    "Summarize Author Contributions"
    "Check Submodule Status"
    "Exit"
)

select opt in "${options[@]}"; do
    case $opt in
        "Export Visual Branch Tree")
            echo -e "\n${YELLOW}Generating branch map...${NC}"
            # Creates a visual tree similar to the 'tree' command discussion
            git log --graph --abbrev-commit --decorate --all --oneline > "$EXPORT_DIR/branch_map.txt"
            echo -e "${GREEN}✓ Saved to $EXPORT_DIR/branch_map.txt${NC}"
            cat "$EXPORT_DIR/branch_map.txt" | head -n 15
            ;;
        "Export Detailed Change Log (JSON-style)")
            echo -e "\n${YELLOW}Exporting commit history...${NC}"
            git log --pretty=format:'{%n  "commit": "%H",%n  "author": "%an",%n  "date": "%ad",%n  "message": "%f"%n},' > "$EXPORT_DIR/commit_history.json"
            echo -e "${GREEN}✓ Saved to $EXPORT_DIR/commit_history.json${NC}"
            ;;
        "List All Tracked Files")
            echo -e "\n${CYAN}--- Files currently tracked by Git ---${NC}"
            git ls-tree -r HEAD --name-only > "$EXPORT_DIR/file_list.txt"
            echo -e "${GREEN}✓ Full list saved to $EXPORT_DIR/file_list.txt${NC}"
            head -n 10 "$EXPORT_DIR/file_list.txt"
            ;;
        "Identify Largest Files in Repo")
            echo -e "\n${RED}--- Top 10 Largest Objects ---${NC}"
            # Helps identify files that might slow down your Unraid or WSL sync
            git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | sed -n 's/^blob //p' | sort -rnk2 | head -n 10
            ;;
        "Summarize Author Contributions")
            echo -e "\n${CYAN}--- Commit Counts by Author ---${NC}"
            git shortlog -sn --all
            ;;
        "Check Submodule Status")
            echo -e "\n${YELLOW}Checking .gitmodules...${NC}"
            # Specifically for your kali and dotfiles submodules
            git submodule status
            if [ -f ".gitmodules" ]; then
                cat .gitmodules
            fi
            ;;
        "Exit")
            echo -e "${CYAN}Exiting Data Exporter. Goodbye!${NC}"
            break
            ;;
        *) echo -e "${RED}Invalid option $REPLY${NC}";;
    esac
done