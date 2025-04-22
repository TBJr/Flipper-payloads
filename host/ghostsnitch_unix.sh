#!/bin/bash

# GhostSnitch for macOS and Linux
# Author: TBJr
# Version: 1.0 (Unix)
# Description: Cross-platform roast prank with TTS and recon

USERNAME=$(whoami)
OS_TYPE=$(uname)
HOSTNAME=$(hostname)
SPEAKER=""

function speak() {
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    say "$1"
  elif command -v spd-say &> /dev/null; then
    spd-say "$1"
  elif command -v espeak &> /dev/null; then
    espeak "$1"
  else
    echo "$1"
  fi
}

function get_ram() {
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    RAM=$(($(sysctl -n hw.memsize) / 1073741824))
  else
    RAM=$(free -g | awk '/Mem:/ {print $2}')
  fi

  if [[ "$RAM" -lt 4 ]]; then
    speak "$RAM gigabytes of RAM? This machine is powered by paperclips and dreams."
  elif [[ "$RAM" -lt 8 ]]; then
    speak "$RAM gigs? Just enough to open Twitter and crash."
  elif [[ "$RAM" -lt 16 ]]; then
    speak "$RAM gigs? Not bad. But your firewall probably runs on trust."
  else
    speak "$RAM gigs? Okay, flex. But I still got in."
  fi
}

function get_ip() {
  IP=$(curl -s ifconfig.me)
  speak "Your public IP is $IP. You are now visible to the universe."
}

function get_wifi() {
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    SSID=$(networksetup -getairportnetwork en0 | cut -d ':' -f2 | xargs)
    speak "Your current WiFi is $SSID. Cute network name."
  elif command -v nmcli &> /dev/null; then
    SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    speak "You're connected to $SSID. Probably unprotected like your passwords."
  else
    speak "I can't find your WiFi name, but I bet it's embarrassing."
  fi
}

function get_last_pass_change() {
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    PASSINFO=$(dscl . read /Users/$USERNAME accountPolicyData 2>/dev/null)
    speak "I have no idea when you last changed your password. I assume it's been a while."
  else
    DAYS=$(chage -l $USERNAME | grep "Last password change" | cut -d: -f2 | xargs)
    speak "You last changed your password on $DAYS. How retro."
  fi
}

function get_email_hint() {
  EMAIL=$(grep -E -o "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}" ~/.bash_history ~/.gitconfig 2>/dev/null | head -n 1)
  if [[ -n "$EMAIL" ]]; then
    speak "Found an email on this system: $EMAIL. Should I send myself a thank you note?"
  else
    speak "Couldn't find your email. Mysterious. I like it."
  fi
}

function change_wallpaper() {
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    osascript -e 'tell application "Finder" to set desktop picture to POSIX file "/System/Library/Desktop Pictures/Solid Colors/Solid Gray Dark.png"'
  elif [[ "$XDG_CURRENT_DESKTOP" == "GNOME" ]]; then
    gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/gnome/adwaita-night.jpg"
  fi
  speak "By the way, I changed your wallpaper. You're welcome."
}

speak "Hello $USERNAME. Let's see what you're hiding."
get_ram
get_ip
get_wifi
get_last_pass_change
get_email_hint
change_wallpaper
speak "GhostSnitch Unix edition signing off."
