#!/data/data/com.termux/files/usr/bin/bash
####################################################################################################
# Title       : GhostSnitch Android (Termux)
# Version     : 2.1
# Author      : I am TBJr
# Description : Recon + roast prank via Termux with termux-api
# Requirements: Termux + Termux:API app + termux-api package (pkg install termux-api)
####################################################################################################

function speak() {
    if command -v termux-tts-speak &>/dev/null; then
        termux-tts-speak "$1" 2>/dev/null
        # Wait proportionally to text length — ~100ms per character is a rough
        # estimate that keeps the next line from firing while audio is still playing
        local len=${#1}
        sleep $(awk "BEGIN { s = $len * 0.07; print (s < 1 ? 1 : s) }")
    else
        echo "[GhostSnitch] $1"
    fi
}

function check_termux_api() {
    if ! command -v termux-tts-speak &>/dev/null; then
        echo "[!] termux-api not installed. Run: pkg install termux-api"
        echo "[!] Also install the Termux:API companion app from F-Droid."
    fi
}

function get_device_info() {
    local BRAND MODEL ANDROID_VER
    BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
    MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
    ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    speak "You're using a $BRAND $MODEL running Android $ANDROID_VER. Brave, but foolish."
}

function get_ram_info() {
    if [[ -r /proc/meminfo ]]; then
        local RAM_KB RAM_GB
        RAM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
        if [[ -n "$RAM_KB" && "$RAM_KB" -gt 0 ]]; then
            # awk avoids the bc dependency and handles decimal correctly
            RAM_GB=$(awk "BEGIN { printf \"%.1f\", $RAM_KB / 1024 / 1024 }")
            speak "This device has approximately $RAM_GB gigabytes of RAM. That's cute."
        else
            speak "Couldn't read RAM info. Probably not enough to matter anyway."
        fi
    else
        speak "Couldn't access memory info. Your device is being secretive."
    fi
}

function get_ip_info() {
    local IP
    IP=$(curl -fsSL --max-time 5 https://api.ipify.org 2>/dev/null \
      || curl -fsSL --max-time 5 https://api4.my-ip.io/ip 2>/dev/null \
      || echo "unknown")
    if [[ "$IP" != "unknown" && -n "$IP" ]]; then
        speak "Your public IP is $IP. And I know where you live now."
    else
        speak "Couldn't fetch your IP. Probably hiding behind a VPN. Smart move."
    fi
}

function get_wifi_info() {
    if ! command -v termux-wifi-connectioninfo &>/dev/null; then
        speak "Termux API not available. Can't spy on your WiFi."
        return
    fi
    local WIFI_INFO SSID
    WIFI_INFO=$(termux-wifi-connectioninfo 2>/dev/null)
    if [[ -z "$WIFI_INFO" ]]; then
        speak "Couldn't read WiFi info. Hiding, huh?"
        return
    fi
    SSID=$(echo "$WIFI_INFO" | grep -o '"ssid"[[:space:]]*:[[:space:]]*"[^"]*"' \
        | cut -d'"' -f4 | head -1)
    if [[ -n "$SSID" && "$SSID" != "null" && "$SSID" != "<unknown ssid>" ]]; then
        speak "Your WiFi network is $SSID. Weak sauce."
    else
        speak "You're not on WiFi. Using mobile data like a peasant."
    fi
}

function get_contacts_hint() {
    if ! command -v termux-contact-list &>/dev/null; then
        speak "Termux API not available. Can't peek at your contacts."
        return
    fi
    # termux-contact-list will prompt for Contacts permission on first run
    local CONTACTS CONTACT
    CONTACTS=$(termux-contact-list 2>/dev/null)
    if [[ -z "$CONTACTS" ]]; then
        speak "Contacts empty or permission denied. Ghost mode — I respect it."
        return
    fi
    CONTACT=$(echo "$CONTACTS" \
        | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' \
        | cut -d'"' -f4 \
        | grep -v '^$' | head -1)
    if [[ -n "$CONTACT" && "$CONTACT" != "null" ]]; then
        speak "You have someone named $CONTACT in your contacts. Should I prank call them too?"
    else
        speak "Your contacts are empty. Ghost mode — I respect it."
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
check_termux_api
speak "Hello Android user. Let's begin."
get_device_info
get_ram_info
get_ip_info
get_wifi_info
get_contacts_hint
speak "GhostSnitch Android signing off. Sleep tight."
