<div align="center">

# Solace

### Reclaim your focus.

*Willpower is unreliable. Physical friction isn't.*

[![Platform](https://img.shields.io/badge/platform-iOS-black?style=flat-square)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?style=flat-square&logo=swift&logoColor=white)](https://www.swift.org)
[![iOS](https://img.shields.io/badge/iOS-17%2B-blue?style=flat-square)](https://developer.apple.com/ios/)
[![AlarmKit](https://img.shields.io/badge/AlarmKit-iOS%2026%2B-red?style=flat-square)](https://developer.apple.com/documentation/alarmkit)
[![License](https://img.shields.io/badge/license-Proprietary-lightgrey?style=flat-square)](#license)

</div>

---

## What is Solace?

Solace is an iOS focus app that blocks distracting apps and websites during a "focus session" — and the only way to end it is to physically scan an NFC tag. No sneaky exits. No "just one more scroll."

The core thesis: **physical friction beats willpower**. If ending a session requires you to get up, find the tag, and tap it against your phone, you'll think twice before breaking your focus for a dopamine hit.

Solace also ships an **NFC-gated alarm** (iOS 26+): a wake-up alarm you literally cannot turn off without scanning your tag. No snooze. No dismiss button. Just physics.

---

## Features

| | |
|---|---|
| **NFC-gated focus sessions** | Start with a scan, or start without the tag — but you'll always need it to end. |
| **OS-level app blocking** | Uses Apple's FamilyControls + ManagedSettings. Shield is applied at the system level, not in-app. |
| **Multiple focus modes** | Create presets for Work, Study, Sleep, etc. Each with its own app/website selection. |
| **NFC-gated alarm** *(iOS 26+)* | Schedule a wake-up alarm that only your tag can silence. |
| **Session-scoped privacy** | Optionally block adult websites, explicit media, and in-app purchases — only while focused. |
| **Live focus stats** | Today, 7-day, 30-day, and lifetime totals. Restored across app kills. |
| **Emergency unblock** | 3 emergency uses per install, for when things go wrong. No more. |
| **100% local** | No accounts. No tracking. No backend. Your data stays on your device. |

---

## The flow

```
  ┌──────────┐    pick a   ┌──────────┐   scan to   ┌──────────┐
  │  Home    │  ─ mode  ─► │  Modes   │  ─ start ─► │  Focus   │
  │ (ready)  │             │  Sheet   │             │  Active  │
  └──────────┘             └──────────┘             └─────┬────┘
        ▲                                                 │
        │                                                 │ scan to end
        │                                                 ▼
        │                                          ┌──────────┐
        └──────────────────────────────────────────│   NFC    │
                                                   │   Tag    │
                                                   └──────────┘
```

For the alarm: scheduled via AlarmKit → rings at wall-clock time → "Dismiss" button opens Solace (does **not** stop the sound) → full-screen `AlarmDismissView` takes over audio with a looping siren → only a successful NFC scan silences it. Force-quit won't help — the pending dismiss ID persists in `UserDefaults` and the view re-appears on next launch.

---

## Tech stack

- **SwiftUI** — all UI
- **FamilyControls** — `FamilyActivityPicker`, `AuthorizationCenter`
- **ManagedSettings** — `ManagedSettingsStore` for shield + privacy toggles
- **CoreNFC** — `NFCNDEFReaderSession` for tag scanning
- **AlarmKit** (iOS 26+) — custom alarms with stop-intent bridge
- **AppIntents** — `LiveActivityIntent` drives the alarm stop button
- **AVFoundation / AudioToolbox** — in-app siren, overrides silent mode

Zero third-party dependencies. Persistence via `@AppStorage` and versioned JSON blobs in `UserDefaults`.

---

## Architecture

```
SolaceApp
├── OnboardingView            — first-launch flow (welcome, tag purchase, permissions)
└── ContentView (TabView)
    ├── HomeView              — start/end focus, manage modes, live stats
    ├── AlarmView             — wake-time picker, sound, save button
    ├── StatsView             — today / 7d / 30d / lifetime
    └── SettingsView          — emergency unblock, privacy toggles, contact

Helpers/
├── FocusSessionManager       — single source of truth for session state
├── ShieldManager             — only thing that touches ManagedSettingsStore
├── NFCManager                — one-shot NDEF read wrapper
├── AlarmScheduler            — AlarmKit wrapper (iOS 26+)
├── AlarmSiren                — in-app audio that takes over after AlarmKit alert
├── AlarmSound                — sound catalog
├── DismissAlarmIntent        — LiveActivityIntent for the alarm stop button
├── FocusMode                 — {id, name, selection}
└── FocusModesPersistence     — versioned JSON under "focus_modes_v1"
```

---

## Building locally

### Requirements

- Xcode 16+
- iOS 17+ deployment target (iOS 26+ for the alarm feature)
- **A physical device.** NFC, FamilyControls, and AlarmKit do not work in the simulator.
- An NFC-capable iPhone (iPhone 7 or newer)
- Any NDEF-compatible NFC tag for testing

### Setup

```bash
git clone <your remote>
cd Solace
open Solace.xcodeproj
```

Then in Xcode:

1. Select the Solace target → **Signing & Capabilities**
2. Set your team
3. Add the **Family Controls** capability (requires Apple approval — see `PUBLISHING.md`)
4. Add the **Near Field Communication Tag Reading** capability (select NDEF)
5. Build & run on a physical device

First launch walks you through onboarding and permission grants.

---

## Publishing

See [`PUBLISHING.md`](./PUBLISHING.md) for the full App Store submission checklist, including the Family Controls entitlement request form answers, Info.plist strings, privacy policy requirements, and asset specs.

---

## Project conventions

- **Never call `ManagedSettingsStore` directly** outside `ShieldManager`
- **Never call `AlarmManager.shared`** outside `AlarmScheduler` and `DismissAlarmIntent`
- **Every `ObservableObject` is `@MainActor`** if it touches UI, `UserDefaults`, `ManagedSettings`, or `AlarmKit`
- **SwiftUI state ownership**: `@StateObject` at the root, `@ObservedObject` when passed down, `@EnvironmentObject` only for `FocusSessionManager`
- **Dark UI**: background `Color.black`, cards `Color.white.opacity(0.08)`, primary `.blue`, destructive/active `.red`, success `.green`

---

## License

© 2026 Solace. All rights reserved. Proprietary software — not open source.

---

<div align="center">

**Built by [Lev](https://github.com/levmalkhasian) · Reclaim your focus.**

</div>
