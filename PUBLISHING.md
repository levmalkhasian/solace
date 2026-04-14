# Publishing Solace to the App Store

This doc is the operational checklist for getting Solace from "builds on my device" to "live in the App Store." Work it top to bottom.

---

## 1. Family Controls Entitlement Request

**This is the slowest gate. Start it before anything else.** Apple manually reviews every app that requests the Family Controls capability. Historically they reject apps that use it for tracking, advertising, or anything that isn't clearly parental/self-control. Expected turnaround: 1–3 weeks, sometimes longer.

### How to request

1. Go to [developer.apple.com/contact/request/family-controls-distribution](https://developer.apple.com/contact/request/family-controls-distribution)
2. Sign in with your Apple Developer account
3. Fill out the form (fields below)

### Answers to use

**App name:** Solace

**Bundle ID:** `com.<yourteam>.Solace` (match your Xcode project)

**Platform:** iOS

**What category best describes your app?**
> Self-control / digital wellbeing productivity app

**Describe how your app will use the Family Controls framework:**
> Solace is a self-control app that helps users break compulsive phone-checking habits. Users voluntarily select apps, app categories, and websites to block during a focus session. The selected items are shielded via `ManagedSettingsStore` (shield.applications, shield.applicationCategories, shield.webDomains). A focus session can only be ended by physically scanning an NFC tag the user owns — this physical-friction model is the core product thesis. Solace also uses `media.denyExplicitContent` and `webContent.blockedByFilter = .auto([], except: [])` as optional, session-scoped privacy toggles, and `appStore.denyInAppPurchases` to prevent impulse purchases during focus. All blocking is self-applied by the account holder; Solace is not used for parental monitoring and collects no usage data from the user's device.

**How does the user interact with the Family Controls UI?**
> The user picks apps/websites through Apple's standard `FamilyActivityPicker` inside Solace. Their selection is stored locally (no server), and applied only while the user is in an active focus session they started themselves. The user can create multiple "focus modes" (e.g., Work, Study, Sleep) and switch between them.

**Do you use DeviceActivityMonitor extensions?**
> No. Solace uses `ManagedSettingsStore` directly; no `DeviceActivity` extensions are used.

**Will your app display information about other people's device usage?**
> No. Solace is a single-user self-control tool. It never reads or transmits usage data.

### After approval

- Add the `com.apple.developer.family-controls` entitlement to the app target in Xcode
- In App Store Connect → App → Signing & Capabilities, add the capability
- Rebuild & re-sign

---

## 2. Required Info.plist Strings

Verify these are all present. Reviewers read them verbatim. Be specific — generic strings get rejected.

| Key | Value |
|---|---|
| `NSFamilyControlsUsageDescription` | *"Solace uses Screen Time to block distracting apps and websites during your focus sessions. You stay in control — Solace never sees what you're doing."* |
| `NFCReaderUsageDescription` | *"Solace reads your NFC tag to start and end focus sessions. The tag acts as a physical key to your focus."* |
| `NSAlarmKitUsageDescription` | *"Solace schedules wake-up alarms that can only be dismissed by scanning your NFC tag, so you have to physically get up to turn them off."* |

---

## 3. Required Capabilities / Entitlements

In the Xcode target's **Signing & Capabilities** tab:

- [ ] **Family Controls** (requires Apple approval — see §1)
- [ ] **Near Field Communication Tag Reading** — adds `com.apple.developer.nfc.readersession.formats`
- [ ] Verify `com.apple.developer.nfc.readersession.formats` in the entitlements plist includes `NDEF`

AlarmKit does NOT need a separate capability — it's gated by `NSAlarmKitUsageDescription` and the user's runtime authorization prompt.

---

## 4. App Store Connect Setup

### Create the app record

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps → `+` → New App
2. Platform: iOS
3. Name: **Solace**
4. Primary language: English (US)
5. Bundle ID: pick the one matching your Xcode project
6. SKU: `solace-ios-001` (or whatever)

### Category

- Primary: **Productivity**
- Secondary: **Health & Fitness** (optional)

### Age rating

Run through the questionnaire. Solace should end up **4+**.

### Pricing & availability

Free (or freemium later). Available in all territories unless you have a reason to restrict.

---

## 5. Privacy Nutrition Label

Go to App Store Connect → App Privacy. Fill this in **before** your first submission.

As of today Solace stores everything locally via `UserDefaults` / `@AppStorage` and makes zero network calls. So the answer to "Do you collect data?" is **No** — which gives you the cleanest possible privacy label.

**This changes the moment you add auth or a backend.** When you add Supabase/Firebase/etc, update this to reflect what you store server-side (email, user ID, focus history, etc.).

---

## 6. Privacy Policy (Required)

Apps using FamilyControls, NFC, or AlarmKit **must** have a privacy policy URL in App Store Connect. Host one at `solaceapp.com/privacy` (or any stable URL). Minimum content:

- What data you collect (answer: none today)
- What you do with it (answer: nothing today)
- How users can contact you
- How users can delete their data

Even though you collect no data today, Apple still wants a policy URL on file.

---

## 7. App Store Assets

### App icon
- 1024×1024 PNG, no alpha, no rounded corners (Apple rounds them)
- Use `solace_app_store_1024.png` from the brand pack

### Screenshots (required)
- **6.9" iPhone display** (iPhone 16 Pro Max): 1320×2868 — required
- **6.5" iPhone display** (iPhone 11 Pro Max): 1242×2688 — required for older App Store listings
- 2–10 screenshots per device size
- Capture: Home (ready), Home (focused), Alarm set, Alarm firing (dismiss view), Stats

### App preview video (optional, recommended)
- 15–30 seconds
- Show the full loop: scan tag → focus session → alarm → scan to dismiss

### Description (copy to tune later)

> **Solace. Reclaim your focus.**
>
> Willpower is unreliable. Physical friction isn't. Solace is a focus app that blocks distracting apps and websites during a session — and the only way to end it is to physically scan your NFC tag. No sneaky exits, no "just one more scroll."
>
> **Features**
> • Block any app, category, or website during focus sessions
> • NFC-gated start and end — or start without the tag if you're feeling brave
> • NFC-gated wake-up alarms that force you out of bed
> • Live focus stats: today, 7 days, 30 days, lifetime
> • Multiple focus modes: Work, Study, Sleep, Deep Work
> • 100% local — no accounts, no tracking, no data collection

### Keywords (100 char max, comma-separated)
> focus,concentration,screen time,block apps,productivity,deep work,nfc,distraction,attention,dopamine

---

## 8. Technical Pre-Submission Checklist

Work through these on a real device (not simulator — NFC/FamilyControls/AlarmKit don't work in simulator):

- [ ] First-launch onboarding renders correctly
- [ ] All three permissions can be granted from onboarding
- [ ] Denying Family Controls shows the "Open Settings" recovery alert
- [ ] Starting a focus session with "Scan Tag" works
- [ ] Starting a focus session with "Start Without Tag" works
- [ ] Ending a focus session without a tag is impossible
- [ ] Emergency Unblock decrements correctly and clears the shield
- [ ] Alarm schedules successfully (test with time 2 minutes out)
- [ ] Alarm fires at the scheduled time
- [ ] Alarm dismiss button opens the app to `AlarmDismissView`
- [ ] Siren continues playing until NFC scan
- [ ] Force-quitting the app during `AlarmDismissView` still shows it on re-launch (pending ID persists)
- [ ] NFC scan successfully stops the alarm
- [ ] Stats show correct today/7d/30d totals after a real session
- [ ] Every screen is legible in light AND dark mode (or explicitly lock to dark)
- [ ] App works on smallest supported screen (iPhone SE 3rd gen)
- [ ] App works on largest supported screen (iPhone 16 Pro Max)
- [ ] No console warnings about missing localizations
- [ ] App icon shows up correctly on home screen

---

## 9. Submission Steps

1. Archive in Xcode (Product → Archive)
2. Validate the archive (Distribute App → App Store Connect → Validate)
3. Upload the archive
4. In App Store Connect, attach the build to your version record
5. Fill in the "What's New" field for your first release: "Initial release. Reclaim your focus."
6. Submit for review
7. Expect 24–72 hour review time for the first submission

---

## 10. Likely Review Feedback

Things Apple will probably ask about:

- **"Why does your app need Family Controls?"** — Answer with the Section 1 description verbatim.
- **"How does a user get an NFC tag?"** — Point them to your purchase flow in onboarding + the buy link in Settings.
- **"What happens if the user loses their tag?"** — Emergency Unblock pool (3 uses) covers this, plus any NDEF-capable tag works (not locked to a specific UID).
- **"Show us the NFC tag UX working"** — Include a screenshot of the scan prompt and/or a video preview.

Be ready with a short written response to each. Having these pre-written in a `review-responses.md` file saves hours.

---

## 11. Post-Launch (v1.1 roadmap)

Stuff to ship in a follow-up, not a hard blocker:

- Live Activity for scheduled alarms
- Authentication (Supabase or Firebase)
- Backend-synced stats
- Leaderboards / social
- VoiceOver + Dynamic Type polish
- Localization beyond English
- iPad support
