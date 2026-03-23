#!/bin/bash

# --- Styling Variables ---
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# --- Root Check ---
if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}Error: This script must be run as root. Use sudo.${NC}"
    exit 1
fi

echo -e "${CYAN}=====================================${NC}"
echo -e "${CYAN}      🐉 Kali Setup & Diag Tool      ${NC}"
echo -e "${CYAN}=====================================${NC}"

PS3=$'\n\033[1;33mSelect a task (1-7): \033[0m'

options=(
    "Update & Upgrade System"
    "Launch Kali Tweaks (Setup/Config)"
    "Fix Broken Packages"
    "Network Diagnostics"
    "Restart Core Services (SSH/Network)"
    "System Hardware Overview"
    "Exit"
)

select opt in "${options[@]}"; do
    case $opt in
        "Update & Upgrade System")
            echo -e "\n${YELLOW}Running apt update & full-upgrade...${NC}"
            apt update && apt full-upgrade -y
            apt autoremove -y
            echo -e "${GREEN}System is fully updated.${NC}"
            ;;
            
        "Launch Kali Tweaks (Setup/Config)")
            echo -e "\n${CYAN}Launching official Kali Tweaks utility...${NC}"
            if command -v kali-tweaks &> /dev/null; then
                kali-tweaks
            else
                echo -e "${YELLOW}kali-tweaks not found. Installing...${NC}"
                apt install kali-tweaks -y
                kali-tweaks
            fi
            ;;
            
        "Fix Broken Packages")
            echo -e "\n${YELLOW}Attempting to fix broken dependencies...${NC}"
            apt --fix-broken install -y
            dpkg --configure -a
            echo -e "${GREEN}Package repairs complete.${NC}"
            ;;
            
        "Network Diagnostics")
            echo -e "\n${CYAN}--- Network Status ---${NC}"
            echo -e "${GREEN}IP Configuration:${NC}"
            ip -brief address show
            echo -e "\n${GREEN}Gateway:${NC}"
            ip route | grep default
            echo -e "\n${GREEN}DNS Check (pinging 1.1.1.1 & google.com):${NC}"
            ping -c 2 1.1.1.1 &> /dev/null && echo "✓ Internet Reachable (IP)" || echo "✗ No Internet (IP)"
            ping -c 2 google.com &> /dev/null && echo "✓ DNS Resolving" || echo "✗ DNS Failing"
            ;;
            
        "Restart Core Services (SSH/Network)")
            echo -e "\n${YELLOW}Restarting NetworkManager...${NC}"
            systemctl restart NetworkManager
            echo -e "${YELLOW}Restarting SSH daemon...${NC}"
            systemctl restart ssh
            systemctl enable ssh
            echo -e "${GREEN}Services restarted and SSH enabled on boot.${NC}"
            ;;
            
        "System Hardware Overview")
            echo -e "\n${CYAN}--- Hardware Info ---${NC}"
            echo -e "${GREEN}CPU:${NC} $(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)"
            echo -e "${GREEN}RAM:${NC} $(free -h | grep Mem | awk '{print $2}') Total"
            echo -e "${GREEN}Storage:${NC}"
            df -h /
            ;;
            
        "Exit")
            echo -e "${CYAN}Exiting. Stay stealthy!${NC}"
            break
            ;;
            
        *) echo -e "${RED}Invalid option $REPLY${NC}";;
    esac
done