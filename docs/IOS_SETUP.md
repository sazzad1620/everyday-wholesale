# iOS Setup — What's Blocked Until You Have a Mac

Everything iOS-related has been written in the Dart code (Firebase Auth, Firestore, Phone Auth, Google Sign-In all work identically across platforms at the code level), but **none of it has ever been built, run, or tested on iOS** — that fundamentally requires Xcode, which only runs on macOS. This doc is the exact checklist for when you get Mac access, ordered so the important stuff comes first.

> Companion docs: [BACKEND_SETUP.md](BACKEND_SETUP.md) (the full backend setup this continues), [IMPLEMENTATION.md](IMPLEMENTATION.md) (current build status).

---

## Prerequisites (on the Mac, before touching this project)

- **Xcode** installed from the App Store (free).
- **CocoaPods** installed: `sudo gem install cocoapods` (or `brew install cocoapods`).
- A free **Apple ID** signed into Xcode — sufficient for Simulator testing. A **paid Apple Developer Program** membership ($99/year) is only needed later, for physical-device testing, TestFlight, and App Store submission — not for anything in this checklist below Step 3.

---

## Step 1 — First build, baseline sanity check

Before touching anything Google-Sign-In-specific, confirm the basics actually work on iOS at all — this has never been verified:

```bash
cd ios && pod install && cd ..
flutter run -d "iPhone 15"   # or whatever Simulator you have
```

Watch for:
- `pod install` completing without errors (it pulls in Firebase's iOS SDKs automatically via the Podfile — should be fully automatic, no manual Podfile edits expected).
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

1. Open `ios/Runner.xcworkspace` in Xcode (not `.xcodeproj` — must be the workspace, since CocoaPods needs it).
2. Right-click the **Runner** folder in the project navigator → **Add Files to "Runner"...**
3. Select `GoogleService-Info.plist` → make sure **"Copy items if needed"** is unchecked (it's already in place) and the **Runner** target checkbox is checked → Add.

## Step 4 — (Later, not urgent) APNs key for smoother Phone Auth

Right now, iOS Phone Auth works via a reCAPTCHA challenge fallback (real SMS still sends, confirmed working) instead of silent verification, because no APNs Authentication Key is configured. This needs a **paid Apple Developer account** (to generate the key in the Apple Developer portal), so it's naturally gated behind that anyway. Steps, when ready:

1. Apple Developer portal → Certificates, Identifiers & Profiles → **Keys** → create a new key with **Apple Push Notifications service (APNs)** enabled → download the `.p8` file.
2. Firebase console → Project Settings → **Cloud Messaging** tab → **Apple app configuration** → upload that key (needs your Team ID and Key ID, both shown on the same Apple portal page).

Skip this until real iOS device testing starts — Simulator testing doesn't need it, and the reCAPTCHA fallback works fine for development either way.

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

- [ ] Step 1 — `pod install` + first `flutter run` on Simulator, confirm email/password sign-in works
- [ ] Step 2 — Add `GIDClientID` + `CFBundleURLTypes` to `Info.plist`, confirm Google Sign-In works
- [ ] Step 3 — Add `GoogleService-Info.plist` to the Xcode project properly (recommended, not blocking)
- [ ] Step 4 — APNs key (later, needs paid Apple Developer account)
- [ ] Step 5 — Real Bundle ID, Sign in with Apple, Developer Program enrollment (before App Store submission)
