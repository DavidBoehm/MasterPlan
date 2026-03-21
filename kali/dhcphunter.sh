#!/bin/bash
# ==============================================================================
# DHCP Hunter: Rogue Router Detection
# Broadcasts a DHCP Discover packet and lists every server that responds.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then echo -e "\e[31m[!] Please run as root: sudo dhcphunter\e[0m"; exit 1; fi

RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; CYAN='\e[36m'; NC='\e[0m'

echo -e "${CYAN}==============================================================================${NC}"
echo -e "${GREEN}                       DHCP HUNTER: ROGUE ROUTER SCANNER                      ${NC}"
echo -e "${CYAN}==============================================================================${NC}"

if ! command -v nmap &> /dev/null; then
    echo -e "${RED}[!] 'nmap' is required. Run: sudo apt install nmap${NC}"; exit 1
fi

ACTIVE_IFACE=$(ip -br link show | awk '$2 == "UP" || $2 == "UNKNOWN" {print $1}' | grep -E '^eth|^en|^wl' | head -n 1)
[ -z "$ACTIVE_IFACE" ] && { echo -e "${RED}[!] No active connection.${NC}"; exit 1; }

echo -e "Broadcasting DHCP Discover on: ${YELLOW}$ACTIVE_IFACE${NC}"
echo -e "Waiting for responses (takes ~10 seconds)...\n"

# Run nmap broadcast script
DHCP_OUTPUT=$(nmap --script broadcast-dhcp-discover -e "$ACTIVE_IFACE" -p 67 2>/dev/null)

# Parse the results
OFFERS=$(echo "$DHCP_OUTPUT" | grep "Response" | wc -l)

if [ "$OFFERS" -eq 0 ]; then
    echo -e "${RED}[!] CRITICAL: No DHCP servers found. Devices cannot get IP addresses!${NC}"
elif [ "$OFFERS" -eq 1 ]; then
    SERVER_IP=$(echo "$DHCP_OUTPUT" | grep "Server Identifier" | awk '{print $4}')
    echo -e "${GREEN}[OK] Exactly ONE healthy DHCP Server found!${NC}"
    echo -e "Authorized Router IP: ${CYAN}$SERVER_IP${NC}"
else
    echo -e "${RED}[!] WARNING: MULTIPLE DHCP SERVERS DETECTED ($OFFERS)! NETWORK CONFLICT LIKELY!${NC}"
    echo "$DHCP_OUTPUT" | grep -E "Server Identifier|IP Offered" | while read -r line; do
        echo -e "  -> ${YELLOW}$line${NC}"
    done
    echo -e "\n${CYAN}TECH NOTE: If one of these IPs is NOT your Deco Router, unplug it immediately!${NC}"
fi

echo -e "\n${CYAN}==============================================================================${NC}"