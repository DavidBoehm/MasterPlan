#!/bin/bash
# ==============================================================================
# LinkMonitor v2.0: Long-Term Connection Stability Tester
# Dual-target monitoring (Local + WAN), structured logging, and summary reports.
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[!] Please run as root: sudo linkmonitor\e[0m"
  exit 1
fi

RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; CYAN='\e[36m'; NC='\e[0m'

# Dynamic log file name based on start time
START_DATE=$(date '+%Y-%m-%d %H:%M:%S')
LOGFILE="linkmonitor_$(date '+%Y%m%d_%H%M%S').log"
WAN_TARGET="8.8.8.8"

# Counters
TOTAL_PINGS=0
LOCAL_DROPS=0
WAN_DROPS=0
START_EPOCH=$(date +%s)

echo -e "${CYAN}==============================================================================${NC}"
echo -e "${GREEN}                       LINKMONITOR STABILITY TESTER v2.0                      ${NC}"
echo -e "${CYAN}==============================================================================${NC}"

# Find default gateway (the router)
GATEWAY=$(ip route | grep default | awk '{print $3}' | head -n 1)

if [ -z "$GATEWAY" ]; then
    echo -e "${RED}[!] No Gateway found. Are you connected to a network?${NC}"
    exit 1
fi

echo -e "Local Target (Router/Switch): ${YELLOW}$GATEWAY${NC}"
echo -e "WAN Target (Internet):        ${YELLOW}$WAN_TARGET${NC}"
echo -e "Log File:                     ${YELLOW}$PWD/$LOGFILE${NC}"
echo -e "------------------------------------------------------------------------------"
echo -e "Monitoring started at: $START_DATE"
echo -e "Press ${RED}Ctrl+C${NC} to stop monitoring and generate a report.\n"
echo -e "Only connection drops will be printed below to keep the screen clean..."

# Initialize Log
echo "LinkMonitor v2.0 Log - Started $START_DATE" > "$LOGFILE"
echo "Target Local: $GATEWAY | Target WAN: $WAN_TARGET" >> "$LOGFILE"
echo "---------------------------------------------------" >> "$LOGFILE"

# Function to handle Ctrl+C (Graceful Exit)
function generate_report() {
    END_EPOCH=$(date +%s)
    RUNTIME=$((END_EPOCH - START_EPOCH))
    HOURS=$((RUNTIME / 3600))
    MINS=$(((RUNTIME % 3600) / 60))
    SECS=$((RUNTIME % 60))
    
    # Calculate percentages
    if [ $TOTAL_PINGS -gt 0 ]; then
        LOCAL_LOSS_PCT=$(awk "BEGIN {printf \"%.2f\", ($LOCAL_DROPS/$TOTAL_PINGS)*100}")
        WAN_LOSS_PCT=$(awk "BEGIN {printf \"%.2f\", ($WAN_DROPS/$TOTAL_PINGS)*100}")
    else
        LOCAL_LOSS_PCT=0; WAN_LOSS_PCT=0
    fi

    echo -e "\n\n${CYAN}==============================================================================${NC}"
    echo -e "${GREEN}                              TEST SUMMARY REPORT                             ${NC}"
    echo -e "${CYAN}==============================================================================${NC}"
    echo -e "Total Run Time:   ${YELLOW}${HOURS}h ${MINS}m ${SECS}s${NC}"
    echo -e "Total Ping Cycles: ${YELLOW}$TOTAL_PINGS${NC}\n"
    
    echo -e "LOCAL CONNECTION ($GATEWAY):"
    echo -e "  Dropped Packets: ${RED}$LOCAL_DROPS${NC}"
    echo -e "  Packet Loss:     ${YELLOW}${LOCAL_LOSS_PCT}%${NC}\n"
    
    echo -e "INTERNET CONNECTION ($WAN_TARGET):"
    echo -e "  Dropped Packets: ${RED}$WAN_DROPS${NC}"
    echo -e "  Packet Loss:     ${YELLOW}${WAN_LOSS_PCT}%${NC}"
    echo -e "${CYAN}==============================================================================${NC}"
    
    # Append summary to the log file as well
    echo -e "\n--- TEST SUMMARY ---" >> "$LOGFILE"
    echo "Run Time: ${HOURS}h ${MINS}m ${SECS}s | Total Cycles: $TOTAL_PINGS" >> "$LOGFILE"
    echo "Local Drops: $LOCAL_DROPS ($LOCAL_LOSS_PCT%) | WAN Drops: $WAN_DROPS ($WAN_LOSS_PCT%)" >> "$LOGFILE"
    
    exit 0
}

# Trap the Ctrl+C signal and route it to the generate_report function
trap generate_report SIGINT

# Infinite monitoring loop
while true; do
    TOTAL_PINGS=$((TOTAL_PINGS + 1))
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ping Local Gateway
    if ! ping -c 1 -W 1 "$GATEWAY" &> /dev/null; then
        LOCAL_DROPS=$((LOCAL_DROPS + 1))
        echo -e "${RED}[$TIMESTAMP] LOCAL DROP DETECTED! (Cannot reach $GATEWAY)${NC}"
        echo "[$TIMESTAMP] LOCAL DROP" >> "$LOGFILE"
    fi
    
    # Ping Public WAN
    if ! ping -c 1 -W 1 "$WAN_TARGET" &> /dev/null; then
        WAN_DROPS=$((WAN_DROPS + 1))
        echo -e "${YELLOW}[$TIMESTAMP] WAN DROP DETECTED! (Cannot reach Internet)${NC}"
        echo "[$TIMESTAMP] WAN DROP" >> "$LOGFILE"
    fi
    
    sleep 1
done