<h1 align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:22c55e,100:14b8a6&height=180&section=header&text=Raspberry%20Pi%20USB%20DAC&fontSize=48&animation=fadeIn&fontAlignY=35" width="100%" />
</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Raspberry%20Pi-000000?style=flat-square&logo=raspberry-pi" />
  <img src="https://img.shields.io/badge/Linux-FCC624?style=flat-square&logo=linux" />
  <img src="https://img.shields.io/badge/Shell-4EAA25?style=flat-square&logo=gnu-bash" />
  <img src="https://img.shields.io/badge/Audio-FF6B6B?style=flat-square" />
</p>

<p align="center">
  <strong>Turn a Raspberry Pi Zero W + DAC Pro into a USB Audio Class gadget for your Mac mini</strong>
</p>

---

## 🎯 What This Does

Transform your **Raspberry Pi Zero W + IQAudio DAC Pro** into a high-fidelity USB audio device (UAC2) that your Mac recognizes natively. Get pristine audio passthrough from Mac → Pi → external speakers or amplifier.

```
Mac (USB-A) ──▶ Pi Zero W + DAC Pro ──▶ Speakers/AMP
```

---

## ⚡ Features

| Feature | Description |
|---------|-------------|
| 🔌 **USB Audio Class 2** | 48kHz / 16-bit stereo out of the box |
| 🎚️ **ALSA Loopback** | Real-time audio bridging via `alsaloop` |
| 🔄 **Idempotent** | Run `setup.sh` multiple times safely |
| 💾 **Auto-Backups** | Every config edit creates timestamped backups |
| 🔧 **Tunable** | Adjust latency, bit-depth, sample rate |
| 🚀 **Systemd Service** | Auto-starts on Pi boot |

---

## 🚀 Quick Start

```bash
# 1. Copy setup script to Pi
scp pi-usb-dac/setup.sh shahid@pidac.local:/tmp/

# 2. Run the bootstrapper (requires sudo)
ssh shahid@pidac.local 'sudo bash /tmp/setup.sh'

# 3. Wait ~30 seconds for reboot, then:
#    - Plug Pi's middle micro-USB into Mac's USB-A port
#    - Select "UAC2Gadget" in Mac's Sound Settings
```

---

## 🔧 Tuning

Edit `/etc/systemd/system/usb-dac.service` on the Pi:

| Issue | Fix |
|-------|-----|
| Clicks/pops | Increase `--latency` to `40000` |
| Too much latency | Drop to `10000` if stable |
| Want 24-bit | Change `p_ssize=2` → `p_ssize=3` |

Then: `sudo systemctl daemon-reload && sudo systemctl restart usb-dac`

---

## 📊 Verify It Works

**On the Pi:**
```bash
aplay -l        # Should show: card 0: IQaudIODAC
arecord -l      # Should show: card 0: UAC2Gadget
systemctl status usb-dac.service
```

**On the Mac:**
- **System Settings → Sound → Output** → Select USB audio device
- **Audio MIDI Setup** → Set to **16-bit, 48000 Hz, 2ch**

---

## ⚠️ Important Notes

- **Middle micro-USB** on Pi Zero W = data/OTG port (required)
- **Outer micro-USB** = power only (won't enumerate as gadget)
- If Mac's 500mA browns out Pi + DAC → use powered hub or Y-cable
- **Don't use 192kHz** on Zero W (single-core ARM11 can't keep up)

---

## 🔙 Rollback

```bash
ls /boot/firmware/*.bak.*
# Restore desired backup:
sudo cp /boot/firmware/config.txt.bak.20250101T000000Z /boot/firmware/config.txt
sudo cp /boot/firmware/cmdline.txt.bak.20250101T000000Z /boot/firmware/cmdline.txt
sudo systemctl disable --now usb-dac.service
sudo reboot
```

---

<p align="center">
  <img src="https://komarev.com/ghpvc/?repo=pi-usb-dac&label=Clones&color=22c55e&style=flat" />
</p>

<div align="center">
  Built with 🔊 for audiophiles who repurpose hardware
</div>
