#!/bin/bash
####################################################################################################
# Title       : GhostSnitch iOS (Jailbroken)
# Version     : 1.2
# Author      : I am TBJr
# Description : Recon + roast prank for jailbroken iOS devices with shell access
#
# Requirements: Jailbroken iOS device with a shell (via SSH, NewTerm, etc.)
#               Procursus/Sileo or Cydia with bash, curl installed
# For non-jailbroken devices use ghostsnitch_ios.html instead
####################################################################################################

function speak() {
    # 'say' is available on some jailbreaks (Procursus provides it)
    if command -v say &>/dev/null; then
        say "$1" 2>/dev/null
        local len=${#1}
        sleep $(awk "BEGIN { s=$len*0.07; print (s<1?1:s) }")
    elif command -v espeak &>/dev/null; then
        espeak "$1" 2>/dev/null
        sleep 1
    else
        echo "[GhostSnitch] $1"
    fi
}

# ── Device info ──────────────────────────────────────────────────────────────
function get_device_info() {
    local IOS_VER DEVICE_MODEL DEVICE_NAME

    # sw_vers exists on Procursus jailbreaks; fall back to SystemVersion.plist
    IOS_VER=$(sw_vers -productVersion 2>/dev/null \
        || defaults read /System/Library/CoreServices/SystemVersion ProductVersion 2>/dev/null \
        || plutil -p /System/Library/CoreServices/SystemVersion.plist 2>/dev/null \
            | grep '"ProductVersion"' | cut -d'"' -f4 \
        || uname -r)

    # hw.model returns the internal identifier e.g. "iPhone14,3" or "iPad13,4"
    DEVICE_MODEL=$(sysctl -n hw.model 2>/dev/null || echo "Unknown")

    # ComputerName is the user-facing device name set in Settings > General > About
    DEVICE_NAME=$(scutil --get ComputerName 2>/dev/null \
        || defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName 2>/dev/null \
        || hostname)

    speak "You're using a $DEVICE_MODEL running iOS $IOS_VER. Brave, but foolish."
    echo "📱 Model:   $DEVICE_MODEL  (iOS $IOS_VER)"
    echo "💻 Name:    $DEVICE_NAME"
}

# ── RAM ──────────────────────────────────────────────────────────────────────
function get_ram_info() {
    local RAM_BYTES RAM_GB
    RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null)
    if [[ -n "$RAM_BYTES" && "$RAM_BYTES" -gt 0 ]]; then
        RAM_GB=$(( RAM_BYTES / 1024 / 1024 / 1024 ))
        speak "This device has approximately $RAM_GB gigabytes of RAM. That's cute."
        echo "💾 RAM: ${RAM_GB} GB"
    else
        speak "Couldn't read RAM. Maybe the hamster escaped the wheel."
        echo "💾 RAM: Unknown"
    fi
}

# ── Battery ──────────────────────────────────────────────────────────────────
function get_battery_info() {
    # /sys/class/power_supply is a Linux sysfs path — does not exist on iOS.
    # iOS battery data lives in the IOKit registry under IOPMPowerSource.
    local MAX_CAP CURR_CAP PCT

    MAX_CAP=$(ioreg -l 2>/dev/null \
        | grep -m1 '"MaxCapacity"' \
        | grep -oE '[0-9]+')
    CURR_CAP=$(ioreg -l 2>/dev/null \
        | grep -m1 '"CurrentCapacity"' \
        | grep -oE '[0-9]+')

    if [[ -n "$MAX_CAP" && -n "$CURR_CAP" && "$MAX_CAP" -gt 0 ]]; then
        PCT=$(( CURR_CAP * 100 / MAX_CAP ))
        speak "Your battery is at $PCT percent. Keep it charged, will you?"
        echo "🔋 Battery: ${PCT}%  (${CURR_CAP}/${MAX_CAP} mAh)"
    else
        speak "Couldn't check your battery. Probably dead anyway."
        echo "🔋 Battery: Unknown"
    fi
}

# ── IP ────────────────────────────────────────────────────────────────────────
function get_ip_info() {
    # Local IP from the first non-loopback IPv4 interface
    local LOCAL_IP PUBLIC_IP
    LOCAL_IP=$(ifconfig 2>/dev/null \
        | awk '/inet / && $2 != "127.0.0.1" { print $2; exit }')

    PUBLIC_IP=$(curl -fsSL --max-time 5 https://api.ipify.org 2>/dev/null \
        || curl -fsSL --max-time 5 https://api4.my-ip.io/ip 2>/dev/null \
        || echo "unknown")

    if [[ "$PUBLIC_IP" != "unknown" && -n "$PUBLIC_IP" ]]; then
        speak "Your public IP is $PUBLIC_IP. And I know where you live now."
        echo "🌐 Public IP: $PUBLIC_IP"
    else
        speak "Couldn't fetch your public IP. Probably hiding behind a VPN."
        echo "🌐 Public IP: Unknown"
    fi
    [[ -n "$LOCAL_IP" ]] && echo "🔗 Local  IP: $LOCAL_IP"
}

# ── WiFi SSID ─────────────────────────────────────────────────────────────────
function get_wifi_info() {
    local SSID=""

    # Approach 1: networksetup (available on Procursus/bootstrap jailbreaks)
    if command -v networksetup &>/dev/null; then
        local WIFI_IF
        WIFI_IF=$(networksetup -listallhardwareports 2>/dev/null \
            | awk '/Wi-Fi/{getline; print $NF}')
        SSID=$(networksetup -getairportnetwork "$WIFI_IF" 2>/dev/null \
            | sed 's/Current Wi-Fi Network: //')
        [[ "$SSID" == *"not associated"* ]] && SSID=""
    fi

    # Approach 2: airport utility — present on some jailbreaks; the macOS path
    # does NOT exist on iOS, so we check the local /usr/sbin path instead
    if [[ -z "$SSID" ]] && [[ -x /usr/sbin/airport ]]; then
        SSID=$(/usr/sbin/airport -I 2>/dev/null \
            | awk -F': ' '/^\s+SSID:/ { print $2; exit }')
    fi

    # Approach 3: last-connected SSID from the airport preferences plist
    if [[ -z "$SSID" ]] && command -v plutil &>/dev/null; then
        SSID=$(plutil -p \
            /private/var/preferences/SystemConfiguration/com.apple.airport.preferences.plist \
            2>/dev/null \
            | awk '/"SSID_STR"/ { match($0,/"[^"]+"\s*$/); print substr($0,RSTART+1,RLENGTH-2); exit }')
    fi

    if [[ -n "$SSID" ]]; then
        speak "Your WiFi network is $SSID. Weak sauce."
        echo "📶 WiFi: $SSID"
    else
        speak "Not connected to WiFi, or couldn't read the SSID. Cellular peasant."
        echo "📶 WiFi: Unknown / Not connected"
    fi
}

# ── Device UDID / Chip ID ─────────────────────────────────────────────────────
function get_udid() {
    local UDID=""

    # ioreg exposes UniqueChipID on all iOS devices without root
    UDID=$(ioreg -l 2>/dev/null \
        | awk -F'"' '/"UniqueChipID"/ { print $4; exit }')

    # Fallback: system_profiler exists on Procursus
    if [[ -z "$UDID" ]]; then
        UDID=$(system_profiler SPHardwareDataType 2>/dev/null \
            | awk '/Hardware UUID/ { print $3; exit }')
    fi

    if [[ -n "$UDID" ]]; then
        speak "I have your device's unique chip identifier. Not creepy at all."
        echo "🆔 Chip ID: $UDID"
    else
        echo "🆔 Chip ID: Unavailable"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo "🍎 GhostSnitch iOS (Jailbroken)"
echo "================================"
echo ""

speak "Hello iOS user. Let's begin."
sleep 1
get_device_info
sleep 1
get_ram_info
sleep 1
get_battery_info
sleep 1
get_ip_info
sleep 1
get_wifi_info
sleep 1
get_udid
sleep 1
speak "GhostSnitch iOS signing off. Sleep tight."
echo ""
echo "✅ Execution complete"
