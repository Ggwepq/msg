# Key-Based Private Messaging App (Flutter)

A lightweight, private 1-on-1 Flutter messaging application designed for personal use after deactivating social media accounts. Hand out unique access keys to selected friends so they can log in, enter their nickname, and start messaging you directly.

---

## Features

1. **Invite Key Login System**:
   - Friends log in by entering an **Access Key** (e.g. `SECRET-ALICE-123`) + their **Nickname**.
   - No email, phone number, or social media registration required!

2. **Admin Command Center**:
   - App Owner logs in using the Master Admin Key (`ADMIN-MASTER-88`).
   - Generate, copy, or delete access keys for specific friends.
   - View your inbox containing all friends who claimed keys and messaged you.
   - Reply to any friend in direct 1-on-1 real-time threads.

3. **Modern Glassmorphic Dark UI**:
   - Sleek dark theme using Tailwind HSL / indigo palette.
   - Real-time message bubbles, timestamps, read receipts, and user avatars.

4. **Out-of-the-box Ready**:
   - Includes local persistent state (`SharedPreferences`) so you can test it immediately without initial backend configuration.
   - Easy integration points for **Firebase Cloud Firestore** or **Supabase Realtime**.

---

## Quick Start (Running Locally)

```bash
# Navigate to project directory
cd /home/cedjuani/Documents/Projects/quick/msg

# Get dependencies
flutter pub get

# Run on Chrome Web or connected Device/Emulator
flutter run -d chrome
```

---

## Credentials for Testing

- **Sample Friend Keys**:
  - Key: `SECRET-ALICE-123` (Already claimed by Alice)
  - Key: `KEY-BOB-999` (Unclaimed, try logging in with nickname "Bob")
  - Key: `KEY-VIP-FRIEND` (Unclaimed)
- **Master Admin Key**: `ADMIN-MASTER-88` (Switch to Admin mode on login screen)

---

## Free Hosting & Deployment Options

When ready to distribute to your friends:
1. **Firebase Firestore (Free)**: Run `flutterfire configure` to connect live online syncing.
2. **Web Build**: Build web app (`flutter build web`) and host 100% free on **Firebase Hosting**, **Vercel**, or **GitHub Pages**.
3. **Android APK**: Build standard APK (`flutter build apk --release`) to send directly via email or messaging app.
