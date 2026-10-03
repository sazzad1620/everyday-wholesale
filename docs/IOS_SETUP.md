# iOS Setup — What's Blocked Until You Have a Mac

Everything iOS-related has been written in the Dart code (Firebase Auth, Firestore, Phone Auth, Google Sign-In all work identically across platforms at the code level), but **none of it has ever been built, run, or tested on iOS** (including the push-notification setup in Step 4, which was written blind) — that fundamentally requires Xcode, which only runs on macOS. This doc is the exact checklist for when you get Mac access, ordered so the important stuff comes first.

> Companion docs: [BACKEND_SETUP.md](BACKEND_SETUP.md) (the full backend setup this continues), [PLAN.md](PLAN.md) (current build status — §7 Roadmap & Status).

---

## Prerequisites (on the Mac, before touching this project)

- **Xcode** installed from the App Store (free).
- **CocoaPods** is not required by the current plugin set (they all use Swift Package Manager), but install it anyway (`brew install cocoapods`) in case a future plugin only supports Pods.
- A free **Apple ID** signed into Xcode — sufficient for Simulator testing. A **paid Apple Developer Program** membership ($99/year) is only needed later, for physical-device testing, TestFlight, and App Store submission — not for anything in this checklist below Step 3.

---

## Step 1 — First build, baseline sanity check

Before touching anything Google-Sign-In-specific, confirm the basics actually work on iOS at all — this has never been verified:

```bash
flutter pub get
flutter run -d "iPhone 15"   # or whatever Simulator you have
```

Watch for:
- The first build resolving all native dependencies without errors. This project uses **Swift Package Manager** for its iOS plugins (every plugin in use supports it), so there is **no `Podfile` and no `pod install` step** — Flutter resolves the packages itself on the first build, which can take a few minutes and needs internet. The iOS deployment target is already **15.0** (all Firebase plugins require it — see Step 4); if you see *requires minimum platform version 15.0*, that setting was lost.
- The app boots, and **email/password sign-in works** — this alone confirms `firebase_options.dart` (already generated for iOS) is wired correctly, since email/password doesn't depend on anything else in this doc.

If this step has problems, nothing below will work either — fix this first.

## Step 2 — Google Sign-In: add the required `Info.plist` keys

This is the main known gap. `ios/Runner/GoogleService-Info.plist` already exists in the repo with real values (downloaded earlier), but Google Sign-In needs two of those values copied into `ios/Runner/Info.plist` — the plist file alone isn't enough, per `google_sign_in_ios`'s own setup instructions.

Open `ios/Runner/Info.plist` and add these two entries inside the outer `<dict>` (anywhere is fine, e.g. right after `<key>CFBundleIdentifier</key>...`):

```xml
<key>GIDClientID</key>
<string>339861351370-butadsni3dkknsdmtgdregbsc05veo8o.apps.googleusercontent.com</string>

<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleTypeRole</key>
		<string>Editor</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>com.googleusercontent.apps.339861351370-butadsni3dkknsdmtgdregbsc05veo8o</string>
		</array>
	</dict>
</array>
```

These two values come straight from `ios/Runner/GoogleService-Info.plist`'s `CLIENT_ID` and `REVERSED_CLIENT_ID` keys respectively — already extracted above, no need to re-open that file. After adding, rebuild (`flutter run`) and test the "Continue with Google" button on Simulator.

## Step 3 — (Recommended) Add `GoogleService-Info.plist` to the Xcode project properly

The file already sits at `ios/Runner/GoogleService-Info.plist`, but it isn't yet referenced inside the Xcode project itself (a plain file in the folder isn't automatically bundled — Xcode needs an explicit reference). Not required for anything working today (Auth/Firestore use `firebase_options.dart` instead, and Google Sign-In only needed the `Info.plist` copy-paste above), but do this now anyway so any future native Firebase feature (Crashlytics, Analytics, Storage) doesn't silently break:

1. Open `ios/Runner.xcworkspace` in Xcode (not `.xcodeproj` — the workspace is what Flutter keeps wired up).
2. Right-click the **Runner** folder in the project navigator → **Add Files to "Runner"...**
3. Select `GoogleService-Info.plist` → make sure **"Copy items if needed"** is unchecked (it's already in place) and the **Runner** target checkbox is checked → Add.

## Step 4 — Push notifications (Offers) and the APNs key

Phase 6.5 of [PLAN.md](PLAN.md) adds admin-written **offers** that arrive as push notifications. Everything that can be done without a Mac is **already done in the repo** (below); what remains is Mac/Apple-account work. The same APNs key also makes Phone Auth silent (it currently falls back to a reCAPTCHA challenge).

### Already done in the repo (written blind — never built; verify in Xcode, see 4.2)

| What | Where | Why |
|---|---|---|
| iOS deployment target **13.0 → 15.0** (3 places) | `ios/Runner.xcodeproj/project.pbxproj` | Every Firebase plugin (`firebase_core`, `firebase_messaging`, `cloud_*`, `firebase_auth`…) and `stripe_ios` declare iOS 15 as the minimum. Flutter builds the plugin Swift package with the *app's* target, so at 13.0 the first build would stop with "requires minimum platform version 15.0" — this blocked iOS even before notifications. Drops iOS 13/14 devices (about 2 % of users). |
| `Runner/Runner.entitlements` with `aps-environment = development` | `ios/Runner/` + `CODE_SIGN_ENTITLEMENTS` in Runner's Debug/Profile/Release configs + file reference in the Runner group | The Push Notifications capability. `development` is right: with automatic signing Xcode switches it to `production` for TestFlight/App Store archives. |
| `SystemCapabilities` → `com.apple.Push`, `com.apple.BackgroundModes` | `project.pbxproj` (Runner `TargetAttributes`) | What Xcode itself writes when you tick the two capabilities, so the **Signing & Capabilities** tab shows them. |
| `UIBackgroundModes → remote-notification` | `ios/Runner/Info.plist` | Lets a push reach the app while it is in the background. |
| iOS `apns` alert in the push | `functions/src/index.ts` (`sendOffer`) | Android gets a data-only message the app draws itself; iOS can't run app code for a closed app that way, so it gets a normal alert (title, body, sound) plus `type: offer` / `offerId` data. |
| iOS-safe Dart | `lib/core/notifications/push_notification_service.dart` | (a) The Android-only notification plugin is **never initialised on iOS** — doing so throws and would also have stopped the tap listeners from registering. (b) On Apple platforms the topic subscription **waits for the APNs token** and retries (6 times, growing delay); without that, `subscribeToTopic` fails with `apns-token-not-set` once and never recovers. (c) Language switches leave the old topic in a separate retried step, so a device can't end up on both languages. (d) Foreground banners via `setForegroundNotificationPresentationOptions`. |

There is **no `Podfile`** on purpose: all plugins in use support Swift Package Manager, so Flutter doesn't need CocoaPods. If a plugin without SwiftPM support is ever added, Flutter will generate a Podfile — then set `platform :ios, '15.0'` in it.

### 4.1 Needs the Apple Developer account ($99/year) — blocked until you have it

1. **Create an APNs Auth Key.** developer.apple.com → Certificates, Identifiers & Profiles → **Keys** → `+` → tick **Apple Push Notifications service (APNs)** → download the `.p8` (one-time download!). Note the **Key ID** and your **Team ID** (top-right of the portal).
2. **Upload it to Firebase.** Firebase console → Project settings → **Cloud Messaging** → *Apple app configuration* → **APNs Authentication Key** → upload the `.p8`, enter Key ID + Team ID. One key covers both development and production, so you won't redo this for TestFlight/App Store.
3. **Bundle ID must match everywhere**: the Xcode target, the Apple App ID and the iOS app registered in Firebase are all `com.example.everydayWholesale` right now. If you change it (Step 5), update all three and re-run `flutterfire configure`; the APNs key stays valid.

A **free Apple ID** can run the app on a Simulator, but **cannot sign an app with the Push Notifications capability for a real device** ("Personal development teams do not support the Push Notifications capability"). If you only have a free account for now, remove the three `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;` lines from `project.pbxproj` (or untick the capability in Xcode) to build, and put them back later.

### 4.2 First time on the Mac — verify the hand-edited project (about 10 minutes)

1. `flutter pub get`, then open **`ios/Runner.xcworkspace`** (not `.xcodeproj`).
2. Runner target → **General**: *Minimum Deployments* should read **iOS 15.0**.
3. Runner target → **Signing & Capabilities**: select your **Team**; you should see **Push Notifications** and **Background Modes → Remote notifications** with no red errors. If either is missing, or Xcode complains about the project file, click **+ Capability** and add them by hand — Xcode then rewrites the entitlements/pbxproj itself. (The repo's version is a best-effort head start written without a Mac. If the project file ever fails to open, `git checkout` it, re-add the two capabilities in the UI, and re-apply the 13.0 → 15.0 target change.)
4. `flutter run` on a **real iPhone** (a Simulator can't get an APNs token for FCM).

### 4.3 Test checklist (real iPhone, after 4.1 and 4.2)

Send offers from **Admin → Offers** (English + Japanese text) and check each row:

| # | Scenario | Expected |
|---|---|---|
| 1 | First launch | iOS permission prompt appears; tap **Allow** |
| 2 | App in background → send offer | Banner with the app icon, title and body; tap opens the **Offers** page |
| 3 | App open (foreground) → send offer | Banner still appears on top of the app; the bell shows the "new" dot |
| 4 | App swiped away (killed) → send offer | Banner appears; tap cold-starts the app, lands on Home, then opens **Offers** |
| 5 | Switch the app to 日本語 → send an offer with Japanese text | Notification is in Japanese; switch back → English again; never both |
| 6 | Signed out / signed in | Same result (topics don't depend on login) |
| 7 | Offer **with** a photo | Still text-only on iOS (see 4.5) — the photo shows on the Offers page |
| 8 | Release/TestFlight build | Same as above (the production APNs environment is used automatically) |

**Display-only check on a Simulator (Apple-silicon Mac, iOS 16+ simulator, no Firebase involved):** boot the Simulator, run the app once, then
`xcrun simctl push booted com.example.everydayWholesale docs/ios_push_test.apns` — a banner should appear, and tapping it should open Offers. This tests the tap routing only, not delivery.

### 4.4 Troubleshooting

| Symptom | Likely cause |
|---|---|
| Build stops: *requires minimum platform version 15.0 … but this target supports 13.0* | Deployment target is not 15.0 (see the table above) |
| Build: *Personal development teams do not support the Push Notifications capability* | Free Apple ID — see the note in 4.1 |
| Build: *Provisioning profile doesn't include the aps-environment entitlement* | Capability not enabled for the App ID, or the wrong Team is selected |
| Log: `[firebase_messaging/apns-token-not-set]` | Running on a Simulator, push permission/capability missing, or the APNs key isn't uploaded. The app retries for about two minutes, then stops until the next language change or relaunch |
| Android works but the iPhone gets nothing | APNs key missing or wrong Key ID/Team ID in Firebase, or a bundle ID mismatch; also check iPhone Settings → Notifications → Everyday Wholesale is allowed and Focus is off |
| Works in debug, not in TestFlight | Almost always a key problem; the single `.p8` covers both environments, so recheck the Team ID/Key ID typed into Firebase |
| Tap opens the app but not the Offers page | Check `type: offer` is in the push data (`sendOffer`) and look for `PushNotificationService` lines in the Xcode console |

### 4.5 Known limits on iOS (by design, for now)

- **Text only.** iOS shows the app icon beside the notification automatically — there is no separate "large logo" — and the offer's **photo banner is not shown**. Showing a photo needs a *Notification Service Extension* (a second Xcode target that downloads the image; the push must also set `mutable-content: 1`). It can only be created and signed on the Mac; do it later if the client wants it.
- The default notification sound and the app icon are used; no custom sound or icon work was done.
- An iOS Simulator cannot receive real FCM pushes; use a physical device.

### 4.6 What was learned on Android and applied here

| Android lesson | iOS handling |
|---|---|
| Firebase's own notification payload can only add a big picture, so the app draws the notification | iOS can't run app code for a killed app, so it keeps a plain `apns` alert |
| Release builds strip resources used only by name (`keep.xml`) | Not applicable on iOS, but always test a **Release** build before shipping |
| Old app builds ignore the new message format | The iOS message still carries a normal alert, so older iOS builds keep working |
| A failed setup step must not break unrelated listeners | Listeners are registered first, in their own `try` |
| Topic subscription can fail early | APNs-token wait and retry, plus a separate retry for leaving the old topic |

## Step 5 — (Later, before App Store submission) Things to decide, not to build yet

- **Real Bundle ID.** Still the `com.example.everydayWholesale` placeholder from `flutter create` (same situation as Android's `com.example.everyday_wholesale` — see [BACKEND_SETUP.md](BACKEND_SETUP.md) Phase A3). Needs to be finalized before any App Store submission; changing it means re-registering the iOS app in Firebase (`flutterfire configure` again).
- **Apple's "Sign in with Apple" requirement.** Apple's App Store Review Guidelines require offering an equivalent "Sign in with Apple" option in any app that includes a third-party login like Google Sign-In. Not a technical blocker today, but a real requirement to plan for before submitting to the App Store — would mean adding a fourth auth method (`sign_in_with_apple` package) alongside email/phone/Google.
- **Apple Developer Program enrollment** ($99/year) — needed for physical-device testing, TestFlight, and App Store submission itself. Not needed for anything in Steps 1–3 above (Simulator-only).

---

## Quick-reference values

Pulled from `ios/Runner/GoogleService-Info.plist`, so you don't need to re-open it:

| Key | Value |
|---|---|
| `CLIENT_ID` (→ `GIDClientID`) | `339861351370-butadsni3dkknsdmtgdregbsc05veo8o.apps.googleusercontent.com` |
| `REVERSED_CLIENT_ID` (→ URL scheme) | `com.googleusercontent.apps.339861351370-butadsni3dkknsdmtgdregbsc05veo8o` |
| `BUNDLE_ID` | `com.example.everydayWholesale` (placeholder — see Step 5) |
| `PROJECT_ID` | `everyday-wholesale` |

---

## Recap checklist

- [ ] Step 1 — first `flutter run` on Simulator (Swift packages resolve on their own; no `pod install`), confirm email/password sign-in works
- [ ] Step 2 — Add `GIDClientID` + `CFBundleURLTypes` to `Info.plist`, confirm Google Sign-In works
- [ ] Step 3 — Add `GoogleService-Info.plist` to the Xcode project properly (recommended, not blocking)
- [ ] Step 4 — Push notifications: APNs key uploaded to Firebase (needs paid Apple Developer account), Xcode capabilities verified (4.2), real-iPhone test checklist (4.3). Code and project config are already in the repo
- [ ] Step 5 — Real Bundle ID, Sign in with Apple, Developer Program enrollment (before App Store submission)
