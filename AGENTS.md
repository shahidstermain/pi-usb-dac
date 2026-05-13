# AI Agent & Copilot Instructions

## Scope
This document provides repository-specific context, conventions, and constraints for AI agents (Cursor, Copilot, Claude, Hermes, OpenCode, etc.) operating in this codebase. Read this before proposing architectural changes or refactoring.

## Project Summary
- **pi-usb-dac**: A bootstrap script to convert a Raspberry Pi Zero W + Raspberry Pi DAC Pro into a USB Audio Class (UAC2) gadget for Mac mini.
- **Goal**: Enable high-fidelity audio pass-through from a Mac to external speakers using a Raspberry Pi as a hardware bridge.
- **Platform**: Raspberry Pi OS / DietPi.

## Tech Stack
- Bash (Shell Scripting)
- ALSA (`alsa-utils`, `alsaloop`)
- systemd (`g_audio` module, custom services)
- Raspberry Pi boot overlays (`config.txt`, `cmdline.txt`)

## Important Paths
- `setup.sh`: The idempotent core deployment script.
- `README.md`: Primary user documentation and rollback guide.

## Commands / Workflow
- **Deploy**: `scp setup.sh user@pi.local:/tmp/ && ssh user@pi.local 'sudo bash /tmp/setup.sh'`
- **Verify**: `systemctl status usb-dac.service`

## Architectural Constraints & Conventions
- **Idempotency**: `setup.sh` must be strictly idempotent. If run twice, it should not duplicate configuration lines in `/boot/firmware/config.txt` or systemd service files.
- **Backups**: Before modifying any system file, an agent must create a timestamped backup copy (e.g., `.bak.$(date +%s)`). 
- **Hardware Limitations**: Do not attempt to configure sample rates higher than 48kHz (or 96kHz max). The ARM11 single-core on the Pi Zero W cannot handle 192kHz audio processing without buffer underruns.
- **Gadget Constraints**: The `g_audio` kernel module requires strict parameter matching between the Mac's Audio MIDI Setup and the `p_srate`/`c_srate` configuration.

## Security & Environment
- **Root execution**: The script requires `sudo` privileges to modify `/boot/` and `/etc/systemd/`.
- Do not commit SSH keys or hardcode IP addresses.
