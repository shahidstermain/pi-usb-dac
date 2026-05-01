#!/usr/bin/env bash
# Pi Zero W + RPi DAC Pro -> USB Audio Class gadget for Mac mini.
# Idempotent: safe to run multiple times. Run as root on the Pi.
#
#   sudo bash setup.sh
#
# After a successful run it reboots once (config.txt + cmdline.txt changes).
# On the second boot the usb-dac.service comes up automatically.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo bash $0" >&2
  exit 1
fi

CONFIG_TXT="/boot/firmware/config.txt"
CMDLINE_TXT="/boot/firmware/cmdline.txt"
# Fallback for pre-Bookworm images.
if [[ ! -f $CONFIG_TXT ]]; then CONFIG_TXT="/boot/config.txt"; fi
if [[ ! -f $CMDLINE_TXT ]]; then CMDLINE_TXT="/boot/cmdline.txt"; fi

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
backup() { cp -n "$1" "$1.bak.$STAMP" || true; }

log() { printf '\n== %s ==\n' "$*"; }

# ---------------------------------------------------------------------------
log "apt: refresh + install alsa-utils"
apt-get update -y
apt-get install -y alsa-utils

# ---------------------------------------------------------------------------
log "config.txt: enable DAC Pro + dwc2 USB gadget"
backup "$CONFIG_TXT"

# Helper: ensure a single line exists somewhere in the file.
ensure_line() {
  local line="$1" file="$2"
  grep -qxF "$line" "$file" || printf '%s\n' "$line" >> "$file"
}

# Comment out any existing dtparam=audio=on (onboard audio must be off).
sed -i -E 's/^[[:space:]]*dtparam=audio=on/# &/' "$CONFIG_TXT"

{
  echo ""
  echo "# --- pi-usb-dac bootstrap ($STAMP) ---"
} >> "$CONFIG_TXT"

ensure_line "dtparam=audio=off"            "$CONFIG_TXT"
ensure_line "dtoverlay=iqaudio-dacplus"    "$CONFIG_TXT"
ensure_line "dtoverlay=dwc2"               "$CONFIG_TXT"

# ---------------------------------------------------------------------------
log "cmdline.txt: add modules-load=dwc2 (single-line file)"
backup "$CMDLINE_TXT"

# cmdline.txt is a single line. Append the token only if not already present.
if ! grep -qE '(^| )modules-load=[^ ]*dwc2' "$CMDLINE_TXT"; then
  # Read only the first line (safer than tr -d '\n' which removes all newlines)
  read -r current < "$CMDLINE_TXT"
  printf '%s modules-load=dwc2\n' "$current" > "$CMDLINE_TXT"
fi

# ---------------------------------------------------------------------------
log "modules-load.d: autoload g_audio"
cat > /etc/modules-load.d/usb-audio.conf <<'EOF'
g_audio
EOF

# ---------------------------------------------------------------------------
log "modprobe.d: g_audio UAC2 profile (48k / 16-bit / stereo)"
cat > /etc/modprobe.d/g_audio.conf <<'EOF'
options g_audio c_srate=48000 c_ssize=2 p_srate=48000 p_ssize=2 p_chmask=3 c_chmask=3
EOF

# ---------------------------------------------------------------------------
log "systemd: install usb-dac.service (alsaloop bridge)"
cat > /etc/systemd/system/usb-dac.service <<'EOF'
[Unit]
Description=USB Audio gadget -> DAC Pro bridge (alsaloop)
After=sound.target
Requires=sound.target

[Service]
Type=simple
ExecStartPre=/bin/sh -c 'for i in $(seq 1 30); do arecord -l 2>/dev/null | grep -q UAC && aplay -l 2>/dev/null | grep -q IQaudIODAC && exit 0; sleep 1; done; exit 1'
ExecStart=/usr/bin/alsaloop \
  --capture=hw:UAC2Gadget \
  --playback=hw:IQaudIODAC \
  --rate=48000 --channels=2 --format=S16_LE \
  --latency=20000 --sync=none
Restart=always
RestartSec=2
Nice=-10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable usb-dac.service

# ---------------------------------------------------------------------------
log "done"
cat <<EOF

Config staged. Reboot required to load dwc2 + iqaudio-dacplus.

After reboot, verify on the Pi:
  aplay  -l   # expect card IQaudIODAC
  arecord -l  # expect card UAC2Gadget (only when plugged into Mac)
  systemctl status usb-dac.service

Then on the Mac:
  System Settings > Sound > Output  ->  pick the new USB audio device
  Audio MIDI Setup                   ->  16-bit, 48000 Hz, 2ch

Rebooting in 5 seconds. Ctrl-C to abort.
EOF
sleep 5
systemctl reboot
