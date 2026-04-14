# CLAUDE.md

Guidance for Claude Code when working in this repo. Keep this file updated as the project evolves.

## What Solace is

iOS focus app that blocks distracting apps/websites during a "focus session." Sessions are gated behind an NFC tag scan — the user physically taps an NFC tag to start and end a session, which makes ending deliberately inconvenient. Also ships an NFC-gated alarm (iOS 26+) using AlarmKit: the alarm cannot be dismissed without scanning the tag.

Target platform: iOS (SwiftUI). Deployment floor is TBD for the rest of the app, but the alarm feature is gated behind `@available(iOS 26.0, *)` (AlarmKit requirement).

## Tech stack

- **SwiftUI** for all UI.
- **FamilyControls** — `FamilyActivitySelection`, `AuthorizationCenter` for picking apps/categories/web domains.
- **ManagedSettings** — `ManagedSettingsStore` to actually apply the shield. Used for `shield.applications`, `shield.applicationCategories`, `shield.webDomains`, `media.denyExplicitContent`, `webContent.blockedByFilter` (Apple's auto adult-website filter — `.auto([], except: [])`), `appStore.denyInAppPurchases`.
- **CoreNFC** — `NFCNDEFReaderSession` wrapped in `NFCManager`. Any NDEF-capable tag counts as success; tag UID is not validated yet.
- **AlarmKit** (iOS 26+) — custom alarms with NFC-gated dismiss. See Alarm flow below.
- **AppIntents** — custom `LiveActivityIntent`s drive the alarm's stop button.

No third-party dependencies. No SwiftData yet (persistence is `@AppStorage` + `UserDefaults` JSON blobs).

## Architecture

```
SolaceApp (injects FocusSessionManager as EnvironmentObject, restores session on launch)
└── ContentView (TabView)
    ├── HomeView       — start/end focus, pick focus mode, live session stats
    ├── AlarmView      — wake-time picker, schedule/cancel NFC-gated alarm
    ├── StatsView      — today/7d/30d/lifetime focus totals
    └── SettingsView   — Login (stub), Emergency Unblock, privacy toggles
```

### Core types

- **`FocusSessionManager`** (`Helpers/FocusSessionManager.swift`, `@MainActor`, `ObservableObject`). Owns `isFocused`, `timeElapsed`, today/lifetime totals, daily history. Splits cross-midnight sessions across day boundaries in `endFocus()`. Prunes daily history beyond 30 days and rolls pruned totals into `lifetimeFocusDaysBeforeHistory`. **Single source of truth for session state — don't duplicate this anywhere.**
- **`ShieldManager`** (`Helpers/ShieldManager.swift`, `@MainActor`). Owns `selection` (the apps to block), `alwaysAllowed`, and the emergency unblock counter. `applyShield()` / `clearShield()` are the only things that should touch `ManagedSettingsStore`.
- **`NFCManager`** (`Helpers/NFCManager.swift`). One-shot NDEF read. `startScan(prompt:onResult:)` → callback fires on success/failure. Not `@MainActor`; callback is dispatched to main.
- **`FocusMode`** (`Helpers/FocusMode.swift`). `{id, name, selection}`. Persisted via `FocusModesPersistence` (JSON under key `focus_modes_v1`).
- **`AlarmScheduler`** (planned, `Helpers/AlarmScheduler.swift`, `@available(iOS 26.0, *)`). Wraps `AlarmManager.shared` for Solace's one-alarm model. See Alarm flow.

### Persistence keys

All via `UserDefaults`, mostly through `@AppStorage`:

- `focusStartTimestamp` / `isFocusedPersisted` — live session restore across app kills.
- `timeElapsedToday` / `timeElapsedTodayAnchor` — today's accumulated focus + the `startOfDay` it was anchored to. On day rollover, yesterday's total is moved into `dailyFocusHistory`.
- `dailyFocusHistory` — `[dateKey: Int]` JSON, pruned to last 30 days.
- `lastSessionTime`, `lifetimeFocusSeconds`, `lifetimeFocusDaysBeforeHistory`.
- `focus_modes_v1` — `[FocusMode]` JSON.
- `selectedFocusModeID` — string form of the active mode's UUID.
- `unblockme` — emergency unblocks remaining.
- `hideSensitiveContent`, `blockInAppPurchases` — privacy toggles (applied only while a focus session is active).
- `wakeAlarmHour`, `wakeAlarmMinute`, `wakeAlarmEnabled`, `wakeAlarmID` — alarm state.

When adding a new persisted value, prefer `@AppStorage` for scalars and the `FocusModesPersistence` pattern (JSON under a versioned key) for structured data.

## Focus session flow

1. User picks a focus mode from `FocusModesSheetView`. `selectedFocusModeID` stored.
2. User taps "Start Focus" → `NFCManager.startScan(prompt: "Scan to Start Focus")`.
3. On successful scan: `ShieldManager.applyShield()` → `FocusSessionManager.startFocus()`.
4. During session: if `hideSensitiveContent` is on, `ShieldManager` also applies `media.denyExplicitContent` **and** `webContent.blockedByFilter = .auto([], except: [])` (adult websites). If `blockInAppPurchases` is on, it applies `appStore.denyInAppPurchases`. All three are cleared in `clearShield()`.
5. User taps "End Focus" → `NFCManager.startScan(prompt: "Scan to End Focus Mode")`.
6. On successful scan: `ShieldManager.clearShield()` → `FocusSessionManager.endFocus()`.

Privacy toggles in Settings (`hideSensitiveContent`, `blockInAppPurchases`) are **locked** (disabled UI) while `vm.isFocused`. They only take effect as part of a focus session, not persistently.

Emergency Unblock is the only way out of a session without the NFC tag. Pool is `unblockme` (default 5). When `emergencyUnblock()` succeeds it calls `clearShield()` and decrements; the caller then ends the session.

## Alarm flow (iOS 26+)

Goal: the alarm rings at a wall-clock time. The only way to dismiss it is to scan the NFC tag.

1. **Schedule.** `AlarmScheduler.schedule(hour:minute:)` cancels any existing Solace alarm, then schedules a new `AlarmManager.AlarmConfiguration` with:
   - `schedule: .relative(...)` — daily recurrence across all 7 weekdays.
   - `attributes: AlarmAttributes(presentation: AlarmPresentation(alert: Alert(title:, stopButton:)), metadata:, tintColor:)`. No `Countdown` / `Paused` presentations → no snooze UI.
   - `stopIntent: DismissAlarmIntent(alarmID:)` — custom `LiveActivityIntent` with `openAppWhenRun = true`.
   - `sound: .default`.
   The alarm UUID is persisted in `wakeAlarmID`.
2. **Fire.** iOS shows the alert. The single "Dismiss" button invokes `DismissAlarmIntent`.
3. **Intent.** `DismissAlarmIntent.perform()` does **not** call `AlarmManager.shared.stop(id:)`. It writes `pendingAlarmDismissID` to `UserDefaults` and returns (`openAppWhenRun = true` brings Solace to the foreground). The alarm keeps ringing.
4. **In-app dismiss.** On launch / foreground, `SolaceApp` checks `pendingAlarmDismissID`. If set, it presents a full-screen `AlarmDismissView` that auto-starts an NFC scan.
5. **NFC success.** `AlarmManager.shared.stop(id:)` → clear `pendingAlarmDismissID` → dismiss the view.
6. **NFC failure / cancel.** Re-prompt. The alarm still rings until the scan succeeds. Force-quit is the only OS-level escape — that's intentional.

**Do not** expose a visible "dismiss without scan" button anywhere. Strict is a feature, not a bug. The Emergency Unblock pool is for focus sessions, not alarms.

The entire feature is wrapped in `@available(iOS 26.0, *)`. The Alarm tab in `ContentView` is hidden on older iOS — check with `#available(iOS 26.0, *)` at the `TabView` level.

## Coding conventions

- **SwiftUI state ownership**: `@StateObject` at the root (`SolaceApp`), `@ObservedObject` when passed down, `@EnvironmentObject` for `FocusSessionManager` only. `ShieldManager` is owned by `ContentView` as `@StateObject` and passed as `@ObservedObject`.
- **`@MainActor`** on any `ObservableObject` that touches `ManagedSettingsStore`, `AlarmManager`, or `UserDefaults`-backed `@AppStorage`.
- **Comments**: short and explain *why* when non-obvious. Don't narrate the `what` — names already do that. Existing files have some chatty comments (e.g., `docs.md`); leave them alone but don't add more.
- **Colors**: dark UI. Background `Color.black`, cards `Color.white.opacity(0.08)`, primary action `.blue`, destructive `.red`, success/active `.green`, secondary text `.gray`.
- **Previews**: every preview that uses `ContentView` / `HomeView` must inject `.environmentObject(FocusSessionManager())` or they crash with SIGBPT.
- **Never call `ManagedSettingsStore` directly** outside `ShieldManager`.
- **Never call `AlarmManager.shared`** outside `AlarmScheduler` and the dismiss intent.

## Info.plist requirements

- `NSAlarmKitUsageDescription` — already set.
- `NFCReaderUsageDescription` — required by CoreNFC. Verify before any alarm/focus work.
- `com.apple.developer.family-controls` entitlement — required for FamilyControls.
- `com.apple.developer.nfc.readersession.formats` — NDEF for NFC scanning.

## Open work / in-flight decisions

- **Authentication**: not yet built. Leaning Supabase Auth (email+password, Sign in with Apple required if any social login). Auth gating requirement (required vs. optional) is undecided. See `todo.md`.
- **Strict Mode**: removed. No planned replacement.
- **Leaderboards, Live Activities, Schedules** — post-MVP. See `todo.md`.
- **Stats "today's focus is incorrect"** — known bug in `todo.md`, not yet investigated.

## Things not to do

- Don't re-introduce Strict Mode.
- Don't let the user dismiss the alarm without an NFC scan. No hidden button, no long-press bypass.
- Don't apply `hideSensitiveContent` / `blockInAppPurchases` outside a focus session.
- Don't use `UserDefaults` directly for tokens when auth lands — use Keychain.
- Don't commit unless the user asks.
