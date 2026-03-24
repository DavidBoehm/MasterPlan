#!/bin/bash

# --- Styling Variables ---
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}      🦙 Ollama Master Toolkit       ${NC}"
echo -e "${CYAN}=====================================${NC}"

PS3=$'\n\033[1;33mSelect an action (1-9): \033[0m'

options=(
    "List installed models"
    "Run a model"
    "Pull a model"
    "Remove a model"
    "Show model info"
    "Stop a running model"
    "Start Server (Network/CORS Config)"
    "Edit Ollama Config (systemd)"
    "Exit"
)

select opt in "${options[@]}"; do
    case $opt in
        "List installed models")
            echo -e "\n${GREEN}--- Installed Models ---${NC}"
            ollama list
            ;;
        "Run a model")
            read -p $'\033[1;32mEnter model name: \033[0m' model
            ollama run "$model"
            ;;
        "Pull a model")
            read -p $'\033[1;32mEnter model name to pull: \033[0m' model
            echo -e "${YELLOW}Pulling $model...${NC}"
            ollama pull "$model"
            ;;
        "Remove a model")
            read -p $'\033[1;31mEnter model name to remove: \033[0m' model
            ollama rm "$model"
            echo -e "${GREEN}Removed $model.${NC}"
            ;;
        "Show model info")
            read -p $'\033[1;32mEnter model name: \033[0m' model
            ollama show "$model"
            ;;
        "Stop a running model")
            read -p $'\033[1;33mEnter model name to stop: \033[0m' model
            ollama stop "$model"
            echo -e "${GREEN}Stopped $model.${NC}"
            ;;
        "Start Server (Network/CORS Config)")
            echo -e "\n${CYAN}--- Network Configuration ---${NC}"
            read -p $'\033[1;32mEnter IP bind (Default: 127.0.0.1, Network: 0.0.0.0): \033[0m' host
            host=${host:-127.0.0.1}
            read -p $'\033[1;32mEnter Allowed CORS Origins (Default: empty, All: *): \033[0m' origins
            
            echo -e "${GREEN}Starting Ollama server on ${host}:11434...${NC}"
            if [ -n "$origins" ]; then
                echo -e "${YELLOW}CORS Enabled for: $origins${NC}"
            fi
            
            OLLAMA_HOST="$host:11434" OLLAMA_ORIGINS="$origins" ollama serve
            ;;
        "Edit Ollama Config (systemd)")
            echo -e "\n${CYAN}--- Edit Configuration ---${NC}"
            read -p $'\033[1;32mChoose editor (nano/code): \033[0m' editor
            if [[ "$editor" == "nano" || "$editor" == "code" ]]; then
                echo -e "${YELLOW}Opening Ollama systemd config with $editor...${NC}"
                # Using SYSTEMD_EDITOR to safely edit the service override file
                sudo SYSTEMD_EDITOR="$editor" systemctl edit ollama.service
                
                # Prompt to restart the service after exiting the editor
                echo -e "${GREEN}Configuration updated.${NC}"
                read -p $'\033[1;33mRestart Ollama service to apply changes? (y/n): \033[0m' restart_choice
                if [[ "$restart_choice" == "y" || "$restart_choice" == "Y" ]]; then
                    sudo systemctl daemon-reload
                    sudo systemctl restart ollama
                    echo -e "${GREEN}Ollama service restarted.${NC}"
                fi
            else
                echo -e "${RED}Invalid editor selection. Please enter 'nano' or 'code'.${NC}"
            fi
            ;;
        "Exit")
            echo -e "${CYAN}Exiting toolkit. Goodbye!${NC}"
            break
            ;;
        *) echo -e "${RED}Invalid option $REPLY${NC}";;
    esac
done