#!/bin/bash

# ==============================================================================
# WifiMaster-Scan v2.0: Environmental Wi-Fi Analyzer
# Upgraded for Band Detection, Robust Error Handling, and Rogue Channel Alerting
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[!] Please run this script as root. Type: sudo ./wifimaster_scan.sh\e[0m"
  exit 1
fi

# Color codes
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
NC='\e[0m'

echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}       WIFIMASTER AIRSPACE ANALYZER v2.0              ${NC}"
echo -e "${CYAN}======================================================${NC}"
echo -e "Initializing hardware and scanning local airspace...\n"

# ==========================================
# 0. ROBUSTNESS & DEPENDENCY CHECKS
# ==========================================
if ! command -v nmcli &> /dev/null; then
    echo -e "${RED}[!] 'nmcli' is not installed. Please run: sudo apt install network-manager${NC}"
    exit 1
fi

# Check if Wi-Fi radio is actually turned on
WIFI_STATE=$(nmcli radio wifi)
if [ "$WIFI_STATE" = "disabled" ]; then
    echo -e "${YELLOW}[!] Wi-Fi radio is disabled. Attempting to enable it...${NC}"
    nmcli radio wifi on
    sleep 3
fi

# Force a fresh scan (suppress errors if it complains about scanning too fast)
echo -n "Sweeping frequencies (takes ~5 seconds)... "
nmcli dev wifi rescan >/dev/null 2>&1
sleep 5
echo -e "${GREEN}Done.${NC}\n"

# Dump scan results (SSID, Channel, Frequency in MHz, Signal %, Security)
nmcli -t -f SSID,CHAN,FREQ,SIGNAL,SECURITY dev wifi > /tmp/wifi_scan.txt

if [ ! -s /tmp/wifi_scan.txt ]; then
    echo -e "${RED}[!] No networks found or Wi-Fi interface is down. Check Kali network manager.${NC}"
    rm -f /tmp/wifi_scan.txt
    exit 1
fi

# ==========================================
# 1. RAW AIRSPACE MAP (WITH BANDS)
# ==========================================
echo -e "${YELLOW}--- 1. NEARBY NETWORKS (STRONGEST TO WEAKEST) ---${NC}"
printf "%-26s | %-8s | %-7s | %-8s | %-15s\n" "SSID (Network Name)" "BAND" "CHANNEL" "SIGNAL" "SECURITY"
echo "--------------------------------------------------------------------------------"

# Sort raw data numerically by signal (Field 4) descending, THEN format with colors
sort -t ':' -k 4 -nr /tmp/wifi_scan.txt | awk -F':' '
    {
        ssid=$1; chan=$2; freq=$3; sig=$4; sec=$5;
        
        # Handle hidden networks
        if (ssid == "") ssid="[Hidden Network]"
        
        # Clean up frequency string and determine band
        gsub(/ MHz/, "", freq);
        if (freq >= 2400 && freq < 2500) band="2.4 GHz";
        else if (freq >= 5000 && freq < 6000) band="5 GHz";
        else if (freq >= 6000) band="6 GHz";
        else band="Unknown";

        # Color code signal strength
        if (sig >= 70) sig_color="\033[32m" # Green
        else if (sig >= 40) sig_color="\033[33m" # Yellow
        else sig_color="\033[31m" # Red
        
        # Print formatted row
        printf "%-26s | %-8s | %-7s | " sig_color "%-8s\033[0m | %-15s\n", substr(ssid,1,26), band, chan, sig"%", sec
    }
'
echo ""

# ==========================================
# 2. CONGESTION & INTERFERENCE ANALYSIS
# ==========================================
echo -e "${YELLOW}--- 2. AIRSPACE HEALTH & INTERFERENCE ---${NC}"

# 2.4 GHz Analysis
CH1=$(awk -F':' '$2=="1" {count++} END {print count+0}' /tmp/wifi_scan.txt)
CH6=$(awk -F':' '$2=="6" {count++} END {print count+0}' /tmp/wifi_scan.txt)
CH11=$(awk -F':' '$2=="11" {count++} END {print count+0}' /tmp/wifi_scan.txt)
ROGUE_CH=$(awk -F':' '{gsub(/ MHz/,"",$3)} $3>=2400 && $3<2500 && $2!=1 && $2!=6 && $2!=11 {count++} END {print count+0}' /tmp/wifi_scan.txt)

echo -e "${CYAN}[2.4 GHz Spectrum]${NC}"
echo -e "  Networks on Ch 1:  ${GREEN}$CH1${NC}"
echo -e "  Networks on Ch 6:  ${GREEN}$CH6${NC}"
echo -e "  Networks on Ch 11: ${GREEN}$CH11${NC}"

if [ "$ROGUE_CH" -gt 0 ]; then
    echo -e "  Rogue Overlap:     ${RED}$ROGUE_CH network(s) using wrong channels!${NC}"
    echo -e "  -> TECH NOTE: Someone is using channels like 2, 3, or 8. This causes heavy interference."
else
    echo -e "  Rogue Overlap:     ${GREEN}0 networks (Clean airspace!)${NC}"
fi
echo ""

# 5 GHz Analysis
TOTAL_5G=$(awk -F':' '{gsub(/ MHz/,"",$3)} $3>=5000 && $3<6000 {count++} END {print count+0}' /tmp/wifi_scan.txt)
echo -e "${CYAN}[5 GHz Spectrum]${NC}"
echo -e "  Total 5GHz Networks Detected: ${GREEN}$TOTAL_5G${NC}"
if [ "$TOTAL_5G" -gt 5 ]; then
    echo -e "  -> TECH NOTE: 5GHz is crowded. Rely on DFS channels (52-144) for your Decos if supported."
else
    echo -e "  -> TECH NOTE: 5GHz is relatively clean. Wide open for your Gigabit backhaul."
fi

echo -e "\n${CYAN}======================================================${NC}"
echo -e "${GREEN}                 SCAN COMPLETE                        ${NC}"
echo -e "${CYAN}======================================================${NC}"

# Clean up temp file safely
rm -f /tmp/wifi_scan.txt