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
┌─────────────┐    USB-A OTG     ┌─────────────┐    3.5mm/I²S    ┌─────────────┐
│   Mac mini  │ ───────────────▶ │  Pi Zero W  │ ──────────────▶ │  DAC Pro    │
│  (Source)   │    (Data Port)    │ + g_audio   │                 │ (Output)    │
└─────────────┘                  └─────────────┘                 └─────────────┘
                                                                    │
                                                                    ▼
                                                            ┌─────────────┐
                                                            │  Speakers   │
                                                            │     or     │
                                                            │   AMP      │
                                                            └─────────────┘
```

## 🎧 Why This Project?

| Problem | Solution |
|---------|----------|
| Mac mini has no optical/audio out | Create a USB audio device the Mac sees natively |
| Want better DAC than Mac's headphone jack | Route through any USB DAC you own |
| Audiophile-grade volume control | Use your existing amplifier's volume knob |
| Budget solution < $50 | Pi Zero W + DAC Pro ≈ $40 |

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

## 🛠️ Hardware Requirements

| Component | What You Need | Approx Cost |
|-----------|---------------|-------------|
| **Pi Zero W** | Single-core ARM11, WiFi built-in | $15 |
| **IQAudio DAC Pro** | HAT-style DAC, 192kHz/32-bit | $25 |
| **MicroSD Card** | 8GB+ for OS | $5 |
| **Power Supply** | 5V 2A micro-USB | $5 |
| **Micro-USB Cable** | For data (not power-only) | $3 |

### ⚠️ Important Notes

- **Middle micro-USB** on Pi Zero W = data/OTG port (required)
- **Outer micro-USB** = power only (won't enumerate as gadget)
- If Mac's 500mA browns out Pi + DAC → use powered hub or Y-cable
- **Don't use 192kHz** on Zero W (single-core ARM11 can't keep up)

---

## 🔧 Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Pi doesn't appear as USB device | Using power-only micro-USB port | Use the **middle** micro-USB port |
| No audio output | DAC not detected | Run `aplay -l` to verify card 0 exists |
| Crackling/popping | Buffer underrun | Increase latency in systemd service |
| Mac doesn't see device | Driver issue | Check System Report → USB for "UAC2Gadget" |
| WiFi drops after gadget enable | USB bandwidth conflict | Use Ethernet or accept limited WiFi performance |

```bash
# Diagnostic commands
lsusb                              # Look for "Linux Foundation" audio device
dmesg | grep -i audio              # Kernel audio module messages
systemctl status usb-dac.service   # Service health check
```

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

---
## 📈 Stats

![GitHub stars](https://img.shields.io/github/stars/shahidstermain/pi-usb-dac?style=flat&color=22c55e)
![GitHub forks](https://img.shields.io/github/forks/shahidstermain/pi-usb-dac?style=flat&color=14b8a6)
![Last updated](https://img.shields.io/github/last-commit/shahidstermain/pi-usb-dac?style=flat&color=22c55e)

<div align="center">
  Built with 🔊 for audiophiles who repurpose hardware
</div>
