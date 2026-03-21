#!/bin/bash
# ==============================================================================
# Speed Profiler: ISP Bandwidth and Latency Baseline
# Tests real-world download/upload and DNS resolution times.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then echo -e "\e[31m[!] Please run as root: sudo speedprofiler\e[0m"; exit 1; fi

RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; CYAN='\e[36m'; NC='\e[0m'

echo -e "${CYAN}==============================================================================${NC}"
echo -e "${GREEN}                        ISP SPEED & LATENCY PROFILER                          ${NC}"
echo -e "${CYAN}==============================================================================${NC}"

if ! command -v speedtest-cli &> /dev/null; then
    echo -e "${YELLOW}[!] Installing required tool 'speedtest-cli'...${NC}"
    apt install speedtest-cli -y &> /dev/null
fi

echo -e "${YELLOW}--- 1. DNS LATENCY (ROUTING HEALTH) ---${NC}"
# Ping Google, Cloudflare, and Quad9
for target in "8.8.8.8 (Google)" "1.1.1.1 (Cloudflare)" "9.9.9.9 (Quad9)"; do
    IP=$(echo $target | awk '{print $1}')
    NAME=$(echo $target | awk '{print $2}')
    PING_MS=$(ping -c 3 -W 1 $IP | tail -1 | awk '{print $4}' | cut -d '/' -f 2)
    
    if [ -z "$PING_MS" ]; then
        echo -e "  $NAME: ${RED}FAILED${NC}"
    else
        # Color code the latency
        if (( $(echo "$PING_MS < 30" | bc -l) )); then COLOR="${GREEN}"
        elif (( $(echo "$PING_MS < 80" | bc -l) )); then COLOR="${YELLOW}"
        else COLOR="${RED}"; fi
        echo -e "  $NAME: ${COLOR}${PING_MS} ms${NC}"
    fi
done
echo -e "${CYAN}TECH NOTE: Under 30ms is excellent. Over 100ms means the ISP is lagging.${NC}\n"

echo -e "${YELLOW}--- 2. RAW ISP BANDWIDTH TEST ---${NC}"
echo -e "Connecting to nearest speedtest server (Takes ~30 seconds)..."

# Run speedtest and format output
SPEED_DATA=$(speedtest-cli --simple 2>/dev/null)

if [ -z "$SPEED_DATA" ]; then
    echo -e "${RED}[!] Speedtest failed. Check internet connection.${NC}"
else
    PING=$(echo "$SPEED_DATA" | grep "Ping" | awk '{print $2 " " $3}')
    DOWN=$(echo "$SPEED_DATA" | grep "Download" | awk '{print $2 " " $3}')
    UP=$(echo "$SPEED_DATA" | grep "Upload" | awk '{print $2 " " $3}')
    
    echo -e "  Test Server Latency: ${CYAN}$PING${NC}"
    echo -e "  Download Speed:      ${GREEN}$DOWN${NC}"
    echo -e "  Upload Speed:        ${GREEN}$UP${NC}"
fi

echo -e "\n${CYAN}==============================================================================${NC}"