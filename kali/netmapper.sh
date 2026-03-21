#!/bin/bash
# ==============================================================================
# NetMapper v2.1: Robust Local Device Discovery
# Sweeps subnet, identifies MACs/Vendors, resolves Hostnames, and tests for Web UIs.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[!] Please run as root: sudo netmapper\e[0m"
  exit 1
fi

RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; CYAN='\e[36m'; NC='\e[0m'

echo -e "${CYAN}==============================================================================${NC}"
echo -e "${GREEN}                       NETMAPPER DEVICE DISCOVERY v2.1                        ${NC}"
echo -e "${CYAN}==============================================================================${NC}"

# Pre-flight checks
MISSING=0
for cmd in arp-scan nc nslookup nmblookup avahi-resolve; do
    if ! command -v $cmd &> /dev/null; then
        # Silently ignore missing advanced hostname tools to keep it robust
        if [[ "$cmd" != "nmblookup" && "$cmd" != "avahi-resolve" ]]; then
            echo -e "${RED}[!] Missing core tool: $cmd${NC}"
            MISSING=1
        fi
    fi
done

if [ $MISSING -eq 1 ]; then
    echo -e "${YELLOW}-> Please install missing tools: sudo apt install arp-scan netcat-traditional dnsutils${NC}"
    exit 1
fi

# Find active interface
ACTIVE_IFACE=$(ip -br link show | awk '$2 == "UP" || $2 == "UNKNOWN" {print $1}' | grep -E '^eth|^en|^wl' | head -n 1)

if [ -z "$ACTIVE_IFACE" ]; then
    echo -e "${RED}[!] No active network connection found.${NC}"
    exit 1
fi

LOCAL_IP=$(ip -4 addr show "$ACTIVE_IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
SUBNET=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | grep "$LOCAL_IP" | head -n 1)

echo -e "Scanning Interface: ${YELLOW}$ACTIVE_IFACE${NC} | Local IP: ${YELLOW}$LOCAL_IP${NC} | Subnet: ${YELLOW}$SUBNET${NC}"
echo -e "Broadcasting ARP sweep and probing ports... Please wait ~10 seconds.\n"

# Table Header
printf "${CYAN}%-15s | %-17s | %-9s | %-20s | %s${NC}\n" "IP ADDRESS" "MAC ADDRESS" "WEB UI?" "HOSTNAME" "HARDWARE VENDOR"
echo "------------------------------------------------------------------------------------------------"

# Run arp-scan and process line by line
arp-scan --localnet --interface="$ACTIVE_IFACE" -q --ignoredups | grep -E '([a-f0-9]{2}:){5}[a-f0-9]{2}' | while read -r line; do
    IP=$(echo "$line" | awk '{print $1}')
    MAC=$(echo "$line" | awk '{print $2}')
    VENDOR=$(echo "$line" | cut -d' ' -f3-)
    
    # 1. Check for Web Interface (Stylized HTTP/HTTPS Detection)
    UI_COLOR="${NC}"
    UI_TEXT="[ ---- ]"
    if nc -z -w 1 "$IP" 443 2>/dev/null; then
        UI_COLOR="${GREEN}"
        UI_TEXT="[ HTTPS ]"
    elif nc -z -w 1 "$IP" 80 2>/dev/null; then
        UI_COLOR="${GREEN}"
        UI_TEXT="[ HTTP  ]"
    fi

    # 2. Attempt to resolve hostname (Aggressive 3-Tier Approach)
    HOSTNAME=$(timeout 1 nslookup "$IP" 2>/dev/null | awk -F'= ' '/name =/ {print $2}' | sed 's/\.$//')
    if [ -z "$HOSTNAME" ] && command -v nmblookup &> /dev/null; then
        HOSTNAME=$(timeout 1 nmblookup -A "$IP" 2>/dev/null | grep '<00>' | grep -v 'GROUP' | head -n 1 | awk '{print $1}')
    fi
    if [ -z "$HOSTNAME" ] && command -v avahi-resolve &> /dev/null; then
        HOSTNAME=$(timeout 1 avahi-resolve -a "$IP" 2>/dev/null | awk '{print $2}' | sed 's/\.local$//')
    fi
    
    if [ -z "$HOSTNAME" ]; then
        HOSTNAME="[Unknown]"
    else
        HOSTNAME=$(echo "$HOSTNAME" | tr -d '\r\n' | cut -c 1-20)
    fi
    
    # 3. Highlight Rogue vs Managed Devices
    if [[ "$VENDOR" == *"Arista"* ]] || [[ "$VENDOR" == *"Mojo"* ]]; then
        VENDOR="${RED}$VENDOR (ROGUE AP?)${NC}"
    elif [[ "$VENDOR" == *"TP-Link"* ]]; then
        VENDOR="${GREEN}$VENDOR (DECO MESH)${NC}"
    fi

    # Print formatted row
    printf "%-15s | %-17s | ${UI_COLOR}%-9s${NC} | %-20s | %s\n" "$IP" "$MAC" "$UI_TEXT" "$HOSTNAME" "$VENDOR"
done

echo -e "\n${CYAN}==============================================================================${NC}"
echo -e "${GREEN}                             SCAN COMPLETE                                    ${NC}"
echo -e "${CYAN}==============================================================================${NC}"