# Kıpır

**Telefonun, faren. / Your phone, your mouse.**

Kıpır turns an iPhone into a wireless trackpad and air mouse for macOS. It is developed as a Computer Engineering graduation project at İskenderun Teknik Üniversitesi (İSTE).

Kıpır, iPhone'u Mac için kablosuz bir trackpad ve "air mouse"a dönüştürür. İskenderun Teknik Üniversitesi Bilgisayar Mühendisliği bitirme projesi olarak geliştirilmektedir.

---

## Features / Özellikler

| Feature | Status |
| --- | --- |
| Automatic Mac discovery (Bonjour) | 🔲 Planned |
| Trackpad mode: move, click, right-click, scroll | 🔲 Planned |
| Sensitivity and acceleration settings | 🔲 Planned |
| Air mouse mode (gyroscope) with filter comparison | 🔲 Planned |
| QR code pairing and encrypted connection | 🔲 Planned |
| Latency measurement mode | 🔲 Planned |

## How it works / Nasıl çalışır

```
iPhone (Kipir)                          Mac (KipirMac)
┌──────────────────────┐   UDP/Wi-Fi   ┌──────────────────────┐
│ Touch / CoreMotion   │ ────────────▶ │ Message decoder      │
│ Filters, sensitivity │               │ CGEvent → cursor     │
│ Message encoder      │ ◀──────────── │ Pairing (TCP)        │
└──────────────────────┘   TCP control └──────────────────────┘
```

- **Kipir (iOS):** Captures touch gestures and motion data, applies filtering, sends cursor deltas.
- **KipirMac (macOS):** Menu bar app that receives messages and injects mouse events via `CGEvent`.
- **Shared:** Swift package with the message format and encryption, used by both apps.

## Tech stack / Teknolojiler

Swift · SwiftUI · CoreMotion · Network framework · Bonjour · CryptoKit · CoreGraphics

## Requirements / Gereksinimler

- macOS 14+ with Xcode 16+
- iPhone with iOS 17+
- Both devices on the same local network
- macOS Accessibility permission for KipirMac

## Project structure / Proje yapısı

```
kipir/
├── Kipir/          # iOS app
├── KipirMac/       # macOS menu bar app
├── Shared/         # Shared Swift package (protocol, crypto)
└── docs/           # Design notes, experiment results
```

## Getting started / Başlangıç

```bash
git clone https://github.com/MaydinKanadasi/kipir.git
cd kipir
open Kipir.xcodeproj
```

1. Select the **KipirMac** scheme and run it on your Mac. Grant Accessibility permission when prompted.
2. Select the **Kipir** scheme, connect your iPhone and run it (Developer Mode must be enabled on the iPhone).
3. Open Kıpır on the iPhone and pick your Mac from the list.

## Author / Geliştirici

**Muhammet Aydın Kanadaşı**
[GitHub](https://github.com/MaydinKanadasi) · [LinkedIn](https://linkedin.com/in/muhammetaydinkanadasi)

## License / Lisans

MIT
