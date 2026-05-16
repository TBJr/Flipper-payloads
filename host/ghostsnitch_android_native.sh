#!/system/bin/sh
####################################################################################################
# Title       : GhostSnitch Android (Native Shell)
# Version     : 3.1
# Author      : I am TBJr
# Description : Recon + roast using Android's native /system/bin/sh (no Termux required)
#
# Context notes:
#   - Intended for adb shell or a HID-launched terminal emulator (e.g. Termux, Terminal Emulator)
#   - android.intent.action.TTS_SERVICE is NOT a valid broadcast intent — removed
#   - Reliable TTS from native shell without root is not possible on modern Android
#   - Data gathering via getprop and dumpsys works without root from adb shell
#   - dumpsys wifi SSID format changed in Android 12; both patterns are tried
#   - curl may not be available in bare /system/bin/sh; busybox or Termux adds it
####################################################################################################

function speak() {
    # Native Android shell has no accessible TTS interface without root or
    # a Java service context. am broadcast -a TTS_SERVICE is not a real intent
    # and was removed. We print visually and optionally show a system toast.
    echo "[GhostSnitch] $1"

    # service call statusbar / notification approach varies wildly by ROM —
    # best-effort only; silent failure is intentional
    am broadcast --user 0 \
        -a "android.intent.action.NOTIFY" \
        --es "android.intent.extra.TEXT" "$1" \
        2>/dev/null || true
}

function get_device_info() {
    local BRAND MODEL ANDROID_VER
    BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
    MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
    ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    speak "You're using a $BRAND $MODEL running Android $ANDROID_VER. Brave, but foolish."
}

function get_ram_info() {
    if [ -r /proc/meminfo ]; then
        local RAM_KB RAM_GB
        RAM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
        if [ -n "$RAM_KB" ] && [ "$RAM_KB" -gt 0 ]; then
            # Integer division — /system/bin/sh has no bc or awk by default
            RAM_GB=$(( RAM_KB / 1024 / 1024 ))
            speak "This device has approximately $RAM_GB gigabytes of RAM. That's cute."
        else
            speak "Couldn't read RAM info. Probably not enough to matter anyway."
        fi
    else
        speak "Couldn't access memory info. Your device is being secretive."
    fi
}

function get_ip_info() {
    # curl is not part of AOSP /system/bin — available via Termux, busybox, or some ROMs
    if ! command -v curl >/dev/null 2>&1; then
        speak "No curl in this shell. Can't fetch public IP."
        return
    fi
    local IP
    IP=$(curl -fsSL --max-time 5 https://api.ipify.org 2>/dev/null \
      || curl -fsSL --max-time 5 https://api4.my-ip.io/ip 2>/dev/null \
      || echo "unknown")
    if [ "$IP" != "unknown" ] && [ -n "$IP" ]; then
        speak "Your public IP is $IP. And I know where you live now."
    else
        speak "Couldn't fetch your IP. Probably hiding behind a VPN. Smart move."
    fi
}

function get_wifi_info() {
    local SSID=""

    # Android 11 and below: mWifiInfo line contains SSID=<name>
    SSID=$(dumpsys wifi 2>/dev/null \
        | grep -m1 'mWifiInfo' \
        | grep -oE 'SSID: ?[^,]+' \
        | sed 's/SSID: *//' | tr -d '"' | xargs)

    # Android 12+: WifiInfo format changed; look for a quoted SSID field
    if [ -z "$SSID" ] || [ "$SSID" = "<unknown ssid>" ]; then
        SSID=$(dumpsys wifi 2>/dev/null \
            | grep -m1 '"SSID"' \
            | grep -oE '"SSID"[ ]*:[ ]*"[^"]*"' \
            | cut -d'"' -f4 | xargs)
    fi

    if [ -n "$SSID" ] && [ "$SSID" != "null" ] && [ "$SSID" != "<unknown ssid>" ]; then
        speak "Your WiFi network is $SSID. Weak sauce."
    else
        local WIFI_ON
        WIFI_ON=$(settings get global wifi_on 2>/dev/null || echo "0")
        if [ "$WIFI_ON" = "1" ]; then
            speak "WiFi is on, but the SSID is not readable without system permissions. Sneaky."
        else
            speak "You're not connected to WiFi. Using mobile data like a peasant."
        fi
    fi
}

function get_contacts_hint() {
    # contacts provider requires READ_CONTACTS permission — adb shell has it,
    # a HID-launched terminal does not.  content query is the correct tool here;
    # dumpsys contacts does not list contact names.
    local COUNT
    COUNT=$(content query --uri content://contacts/people 2>/dev/null | grep -c "Row:")
    # grep -c returns a count (integer) directly — no head -1 needed
    if [ -n "$COUNT" ] && [ "$COUNT" -gt 0 ] 2>/dev/null; then
        speak "You have $COUNT contacts in your phone. Should I prank call them too?"
    else
        speak "Couldn't read contacts. Either empty, or permissions blocked me. Ghost mode — I respect it."
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
speak "Hello Android user. Let's begin."
sleep 1
get_device_info
sleep 1
get_ram_info
sleep 1
get_ip_info
sleep 1
get_wifi_info
sleep 1
get_contacts_hint
sleep 1
speak "GhostSnitch Android signing off. Sleep tight."
