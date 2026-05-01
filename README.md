# pi-usb-dac

Bootstrap for turning a **Raspberry Pi Zero W + Raspberry Pi DAC Pro** into a USB Audio Class gadget for the Mac mini. Implements the plan at `~/.windsurf/plans/pi-zero-w-usb-dac-*.md`.

## What `setup.sh` does

Idempotent, reboots once at the end.

1. `apt install alsa-utils` (provides `alsaloop`, `aplay`, `arecord`).
2. Edits `/boot/firmware/config.txt`:
   - disables onboard audio (`dtparam=audio=off`)
   - loads the DAC Pro overlay (`dtoverlay=iqaudio-dacplus`)
   - enables the USB OTG controller (`dtoverlay=dwc2`)
3. Appends `modules-load=dwc2` to `/boot/firmware/cmdline.txt` (single-line safe).
4. Autoloads `g_audio` on boot with UAC2 at **48 kHz / 16-bit / stereo**.
5. Installs `usb-dac.service` — an `alsaloop` bridge from `hw:UAC2Gadget` (capture from Mac) to `hw:IQaudIODAC` (I²S playback to DAC Pro).
6. Reboots.

All edited files get a `.bak.<timestamp>` copy next to the original.

## Usage

From the Mac, with the Pi reachable over WiFi (hostname `pidac.local` per the plan):

```bash
scp pi-usb-dac/setup.sh shahid@pidac.local:/tmp/
ssh shahid@pidac.local 'sudo bash /tmp/setup.sh'
# Pi reboots. Wait ~30s, then physically move the Pi's middle micro-USB to the Mac.
```

## Verify

On the Pi (after reboot + USB plugged into Mac's USB-A):

```bash
aplay  -l                       # card: IQaudIODAC, device 0
arecord -l                      # card: UAC2Gadget (only when Mac-connected)
systemctl status usb-dac.service
journalctl -u usb-dac.service -n 50 --no-pager
```

On the Mac:

- **System Settings → Sound → Output** — pick the new USB audio device.
- **Audio MIDI Setup** — set it to **16-bit, 48000 Hz, 2ch** (must match `g_audio` opts or you get resampling + glitches).

## Tuning

Edit `/etc/systemd/system/usb-dac.service` on the Pi, then `sudo systemctl daemon-reload && sudo systemctl restart usb-dac`.

- **Clicks/pops** → raise `--latency` to `40000`.
- **Latency too high** → drop to `10000` if stable.
- **24-bit** → change `p_ssize=2` to `p_ssize=3` in `/etc/modprobe.d/g_audio.conf` *and* `--format=S16_LE` to `--format=S24_LE` in the service file. Reboot.

## Rollback

```bash
ls /boot/firmware/*.bak.*
# restore the backup you want, e.g.:
sudo cp /boot/firmware/config.txt.bak.20250101T000000Z /boot/firmware/config.txt
sudo cp /boot/firmware/cmdline.txt.bak.20250101T000000Z /boot/firmware/cmdline.txt
sudo systemctl disable --now usb-dac.service
sudo rm /etc/systemd/system/usb-dac.service \
        /etc/modules-load.d/usb-audio.conf \
        /etc/modprobe.d/g_audio.conf
sudo reboot
```

## Notes

- Middle micro-USB on the Pi Zero W is the data/OTG port. Outer `PWR` port is power-only; the gadget will not enumerate from it.
- If the Mac's 500 mA USB-A browns out the Pi + DAC Pro, use a powered USB hub or a Y-cable (data → Mac, power → 5 V PSU).
- Don't try 192 kHz on a Zero W — single-core ARM11 can't keep up. Use a Zero 2 W if you need it.
