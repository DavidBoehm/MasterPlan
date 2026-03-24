#!/bin/bash

# --- MASTERPLAN DISPATCHER ---
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
MAGENTA='\033[1;35m'
NC='\033[0m'

echo -e "${CYAN}================================================================================${NC}"
echo -e "${CYAN}                  🚀 WELCOME TO THE MASTERPLAN AUTOMATION HUB!                  ${NC}"
echo -e "${CYAN}================================================================================${NC}"

# --- Environment Detection ---
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    ENV="Windows (PowerShell/Bash)"
elif grep -qi microsoft /proc/version 2>/dev/null; then
    ENV="WSL (Windows Subsystem for Linux)"
else
    ENV="Linux/Unix"
fi

echo -e "${YELLOW}🌎 Detected Environment: ${MAGENTA}$ENV${NC}\n"

echo -e "${CYAN}This menu lets you launch, manage, and explore all major scripts in your MasterPlan repo.${NC}"
echo -e "${CYAN}Each tool is color-coded, highly verbose, and beginner-friendly!${NC}\n"

# --- Main Menu Options ---
PS3=$'\n\033[1;33mSelect a script or toolkit to launch: \033[0m'

options=(
    "🪟 System Admin Toolkit (PowerShell)      - Windows system admin menu (toolkit.ps1)"
    "🌐 Network & WSL Toolkit (PowerShell)     - Network, WSL, and diagnostics (netkit.ps1)"
    "🖨️ Printer Diagnostics (PowerShell)        - Advanced printer troubleshooting (printer_kit.ps1)"
    "🛠️ Registry Tweaks Toolkit (PowerShell)     - Safe registry tweaks & backup (reg_kit.ps1)"
    "🐙 GitHub CLI Toolkit (Bash)               - GitHub repo management (gh_kit.sh)"
    "📊 Git Repo Data Exporter (Bash)           - Visualize and export repo data (git_kit.sh)"
    "🦙 Ollama Master Toolkit (Bash)            - AI model management (ollama_kit.sh)"
    "🐉 Kali Linux Tools (Bash)                  - Launch Kali network/security scripts"
    "⚙️  Dotfiles Bootstrap (Bash)                - Setup Zsh, Oh My Zsh, and configs (dotfiles/bootstrap.sh)"
    "🔄 Update All Submodules (Git)              - Sync all submodules (dotfiles, kali, etc.)"
    "❌ Exit"
)

select opt in "${options[@]}"; do
    case $REPLY in
        1)
            echo -e "${GREEN}Launching System Admin Toolkit...${NC}"
            powershell.exe -ExecutionPolicy Bypass -File "./windows/toolkit.ps1"
            ;;
        2)
            echo -e "${GREEN}Launching Network & WSL Toolkit...${NC}"
            powershell.exe -ExecutionPolicy Bypass -File "./windows/netkit.ps1"
            ;;
        3)
            echo -e "${GREEN}Launching Printer Diagnostics...${NC}"
            powershell.exe -ExecutionPolicy Bypass -File "./windows/printer_kit.ps1"
            ;;
        4)
            echo -e "${GREEN}Launching Registry Tweaks Toolkit...${NC}"
            powershell.exe -ExecutionPolicy Bypass -File "./windows/reg_kit.ps1"
            ;;
        5)
            echo -e "${CYAN}Launching GitHub CLI Toolkit...${NC}"
            bash "./gh_kit.sh"
            ;;
        6)
            echo -e "${CYAN}Launching Git Repo Data Exporter...${NC}"
            bash "./git_kit.sh"
            ;;
        7)
            echo -e "${CYAN}Launching Ollama Master Toolkit...${NC}"
            bash "./linux/ollama_kit.sh"
            ;;
        8)
            # Kali submenu using select for compatibility
            echo -e "${MAGENTA}\nKali Linux Tools Menu:${NC}"
            kali_options=(
                "DHCP Hunter         - Detect rogue DHCP servers   [kali/dhcphunter.sh]"
                "NetMapper           - Local device discovery      [kali/netmapper.sh]"
                "Speed Profiler      - ISP speed & latency         [kali/speedprofiler.sh]"
                "LinkMonitor         - Connection stability tester [kali/linkmonitor.sh]"
                "Printer Kit         - Kali printer/network diag   [kali/printer_kit.sh]"
                "SwitchWhisperer     - Managed switch/port discovery [kali/switchwhisperer.sh]"
                "WifiMaster Scan     - Wi-Fi analyzer              [kali/wifimaster_scan.sh]"
                "Back to Main Menu"
            )
            PS3=$'\n\033[1;33mSelect a Kali tool: \033[0m'
            select kaliopt in "${kali_options[@]}"; do
                case $REPLY in
                    1) sudo bash "./kali/dhcphunter.sh"; break ;;
                    2) sudo bash "./kali/netmapper.sh"; break ;;
                    3) sudo bash "./kali/speedprofiler.sh"; break ;;
                    4) sudo bash "./kali/linkmonitor.sh"; break ;;
                    5) sudo bash "./kali/printer_kit.sh"; break ;;
                    6) sudo bash "./kali/switchwhisperer.sh"; break ;;
                    7) sudo bash "./kali/wifimaster_scan.sh"; break ;;
                    8) break ;;
                    *) echo -e "${RED}Invalid Kali tool selection.${NC}" ;;
                esac
            done
            ;;
        9)
            echo -e "${CYAN}Bootstrapping Dotfiles and Zsh...${NC}"
            bash "./dotfiles/bootstrap.sh"
            ;;
        10)
            echo -e "${YELLOW}Syncing all submodules (dotfiles, kali, etc.)...${NC}"
            git submodule update --init --recursive
            ;;
        11)
            echo -e "${MAGENTA}Thank you for using the MasterPlan Dispatcher!${NC}"
            break
            ;;
        *)
            echo -e "${RED}Invalid selection. Please choose a valid option!${NC}"
            ;;
    esac
done