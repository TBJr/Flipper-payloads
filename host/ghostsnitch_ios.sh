#!/bin/bash

# GhostSnitch for iOS (Jailbroken devices only)
# Author: TBJr
# Version: 1.0
# Description: Recon + Roast prank for jailbroken iOS devices
# 
# NOTE: This script requires a jailbroken iOS device with shell access
# For non-jailbroken devices, use the web-based version (ghostsnitch_ios.html)

function speak {
  # Use iOS say command (available on jailbroken devices)
  if command -v say &>/dev/null; then
    say "$1" 2>/dev/null
    sleep 1
  elif command -v espeak &>/dev/null; then
    espeak "$1" 2>/dev/null
    sleep 1
  else
    echo "$1"
  fi
}

function get_device_info {
  # Get iOS version
  IOS_VER=$(sw_vers -productVersion 2>/dev/null || echo "Unknown")
  
  # Get device model
  DEVICE_MODEL=$(sysctl -n hw.model 2>/dev/null || echo "Unknown")
  
  # Get device name
  DEVICE_NAME=$(scutil --get ComputerName 2>/dev/null || echo "Unknown")
  
  speak "You're using a $DEVICE_MODEL running iOS $IOS_VER. Brave, but foolish."
  echo "📱 Device: $DEVICE_MODEL (iOS $IOS_VER)"
  echo "💻 Name: $DEVICE_NAME"
}

function get_ram_info {
  # Get total RAM
  if command -v sysctl &>/dev/null; then
    RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null)
    if [ -n "$RAM_BYTES" ]; then
      RAM_GB=$((RAM_BYTES / 1024 / 1024 / 1024))
      speak "This device has approximately $RAM_GB gigabytes of RAM. That's cute."
      echo "💾 RAM: ${RAM_GB} GB"
    else
      speak "Couldn't read your RAM info. Probably not enough to matter anyway."
      echo "💾 RAM: Unknown"
    fi
  else
    speak "Couldn't access memory info. Your device is being secretive."
    echo "💾 RAM: Unknown"
  fi
}

function get_ip_info {
  # Get local IP
  LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
  
  # Get public IP
  PUBLIC_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 icanhazip.com 2>/dev/null || echo "unknown")
  
  if [ "$PUBLIC_IP" != "unknown" ] && [ -n "$PUBLIC_IP" ]; then
    speak "Your public IP is $PUBLIC_IP. And I know where you live now."
    echo "🌐 Public IP: $PUBLIC_IP"
  else
    speak "Couldn't fetch your public IP address. Probably hiding behind a VPN. Smart move."
    echo "🌐 Public IP: Unknown"
  fi
  
  if [ -n "$LOCAL_IP" ]; then
    echo "🔗 Local IP: $LOCAL_IP"
  fi
}

function get_wifi_info {
  # Get WiFi SSID (requires jailbreak and appropriate tools)
  if command -v /System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport &>/dev/null; then
    SSID=$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I 2>/dev/null | grep -i "SSID" | awk '{print $2}')
    if [ -n "$SSID" ]; then
      speak "Your WiFi network is $SSID. Weak sauce."
      echo "📶 WiFi SSID: $SSID"
    else
      speak "You're not connected to WiFi. Using cellular data like a peasant."
      echo "📶 WiFi: Not connected"
    fi
  else
    speak "Couldn't find your WiFi info. Hiding, huh?"
    echo "📶 WiFi: Unknown"
  fi
}

function get_battery_info {
  # Get battery info (jailbroken devices may have access)
  if [ -f /sys/class/power_supply/BAT0/capacity ]; then
    BATTERY=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
    if [ -n "$BATTERY" ]; then
      speak "Your battery is at $BATTERY percent. Keep it charged, will you?"
      echo "🔋 Battery: ${BATTERY}%"
    fi
  else
    speak "Couldn't check your battery. Probably dead anyway."
    echo "🔋 Battery: Unknown"
  fi
}

function get_udid {
  # Get device UDID (requires appropriate permissions)
  UDID=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Hardware UUID" | awk '{print $3}')
  if [ -n "$UDID" ]; then
    echo "🆔 UDID: $UDID"
    speak "I have your device's unique identifier. Not creepy at all."
  else
    echo "🆔 UDID: Unknown"
  fi
}

# Main execution
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

