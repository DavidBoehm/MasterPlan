#!/bin/bash
# ==============================================================================
# SwitchWhisperer: Managed Switch & Port Discovery Tool
# Listens for LLDP and CDP packets to identify the upstream switch and physical port.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[!] Please run as root: sudo switchwhisperer\e[0m"
  exit 1
fi

RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; CYAN='\e[36m'; NC='\e[0m'

echo -e "${CYAN}==============================================================================${NC}"
echo -e "${GREEN}                       SWITCH WHISPERER: PORT DISCOVERY                       ${NC}"
echo -e "${CYAN}==============================================================================${NC}"

# 1. Dependency Check
if ! command -v lldpcli &> /dev/null; then
    echo -e "${RED}[!] 'lldpd' is missing. Installing it now...${NC}"
    apt-get update > /dev/null && apt-get install lldpd -y > /dev/null
    echo -e "${GREEN}[+] Installed lldpd.${NC}"
fi

# 2. Ensure the daemon is running and configured
systemctl start lldpd
# Force lldpd to listen to Cisco (CDP), Foundry (FDP), Extreme (EDP), and Nortel (SONMP) protocols
lldpcli configure lldp custom-tlv enable &> /dev/null 

# 3. Find the active Wired Interface
ACTIVE_IFACE=$(ip -br link show | awk '$2 == "UP" {print $1}' | grep -E '^eth|^en' | head -n 1)

if [ -z "$ACTIVE_IFACE" ]; then
    echo -e "${RED}[!] No active wired connection found. Please plug in an Ethernet cable!${NC}"
    exit 1
fi

echo -e "Listening on Interface: ${YELLOW}$ACTIVE_IFACE${NC}"
echo -e "Waiting for Switch Beacons (LLDP/CDP). This can take up to 60 seconds..."
echo -e "------------------------------------------------------------------------------"

# 4. The Hunting Loop (Listen for up to 65 seconds)
FOUND=0
for (( i=65; i>0; i--)); do
    # Print countdown timer on the same line
    printf "\r${CYAN}Listening... %2d seconds remaining${NC} " "$i"
    
    # Ask lldpcli to dump neighbors in Key=Value format for easy parsing
    NEIGHBORS=$(lldpcli show neighbors -f keyvalue 2>/dev/null)
    
    # If the output contains a chassis MAC, we caught a beacon!
    if echo "$NEIGHBORS" | grep -q "chassis.mac"; then
        FOUND=1
        echo -e "\n\n${GREEN}[+] MANAGED SWITCH DETECTED!${NC}\n"
        break
    fi
    
    sleep 1
done

# 5. Parse and Display the Data
if [ $FOUND -eq 1 ]; then
    # Extract specific values using grep and cut
    SW_NAME=$(echo "$NEIGHBORS" | grep "chassis.name" | cut -d '=' -f 2 | head -n 1)
    SW_IP=$(echo "$NEIGHBORS" | grep "mgmt-ip" | cut -d '=' -f 2 | head -n 1)
    SW_MAC=$(echo "$NEIGHBORS" | grep "chassis.mac" | cut -d '=' -f 2 | head -n 1)
    SW_PORT=$(echo "$NEIGHBORS" | grep "port.ifname" | cut -d '=' -f 2 | head -n 1)
    SW_DESC=$(echo "$NEIGHBORS" | grep "port.descr" | cut -d '=' -f 2 | head -n 1)
    SW_VLAN=$(echo "$NEIGHBORS" | grep "vlan.vlan-id" | cut -d '=' -f 2 | tr '\n' ' ' | awk '{print $1}')
    SW_VENDOR=$(echo "$NEIGHBORS" | grep "chassis.descr" | cut -d '=' -f 2 | head -n 1 | cut -d ' ' -f 1-3)

    # Fallbacks if switch doesn't provide the info
    [ -z "$SW_NAME" ] && SW_NAME="[Hidden]"
    [ -z "$SW_IP" ] && SW_IP="[No Mgmt IP Broadcasted]"
    [ -z "$SW_VLAN" ] && SW_VLAN="[Untagged/Native]"
    [ -z "$SW_DESC" ] && SW_DESC="[No Port Description]"
    [ -z "$SW_VENDOR" ] && SW_VENDOR="[Unknown Vendor]"

    echo -e "  Hardware Vendor:   ${CYAN}$SW_VENDOR${NC}"
    echo -e "  Switch Hostname:   ${GREEN}$SW_NAME${NC}"
    echo -e "  Management IP:     ${GREEN}$SW_IP${NC} (MAC: $SW_MAC)"
    echo -e "  Physical Port ID:  ${YELLOW}$SW_PORT${NC}"
    echo -e "  Port Description:  ${CYAN}$SW_DESC${NC}"
    echo -e "  Assigned VLAN:     ${YELLOW}VLAN $SW_VLAN${NC}"
    
    echo -e "\n${CYAN}TECH NOTE: You can type http://$SW_IP into your browser to attempt login.${NC}"
else
    # The timer hit zero
    echo -e "\n\n${RED}[!] TIMEOUT: No managed switch beacons detected.${NC}"
    echo -e "${YELLOW}  -> The switch upstream is likely an unmanaged 'dumb' switch.${NC}"
    echo -e "${YELLOW}  -> Grab your Klein VDV500-705 Tone & Probe kit to trace this line manually.${NC}"
fi

echo -e "\n${CYAN}==============================================================================${NC}"