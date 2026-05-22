# Fix: `CONFIGURATION_NOT_FOUND` (Firebase Auth)

This error means **Firebase Authentication is not enabled** for project **medicvoice-a1047**, not a bug in your Flutter UI code.

## Step 1 — Enable Email/Password (required)

1. Open: https://console.firebase.google.com/project/medicvoice-a1047/authentication
2. Click **Get started** (if you see it).
3. Open the **Sign-in method** tab.
4. Click **Email/Password** → turn **Enable** ON → **Save**.

## Step 2 — Add Android SHA fingerprints (required on real devices)

1. Firebase Console → ⚙️ **Project settings** → **Your apps** → Android app `com.medivoice.medic`
2. Add these **debug** fingerprints:

| Type | Value |
|------|--------|
| SHA-1 | `AE:50:56:D9:4D:40:48:B9:D7:95:33:65:07:F9:3F:6D:C7:FB:4B:80` |
| SHA-256 | `A5:C3:CC:A8:7B:6C:E6:EC:3B:20:1D:2E:75:41:EE:B6:82:28:FC:9E:A2:3D:A8:F1:4A:E3:A1:7F:F4:4E:38:E7` |

3. Download the **new** `google-services.json` and replace `android/app/google-services.json`.

## Step 3 — Rebuild the app

```bash
flutter clean
flutter pub get
flutter run
```

## Step 4 — If email already exists

Use **Sign in** on the login screen with the same email/password instead of registering again.

## Verify package name

Your app must use: `com.medivoice.medic` (already set in `android/app/build.gradle.kts`).
