# Penguin App - Quick Start Guide

## ✅ What's Already Done

- ✅ Flutter app with all features
- ✅ Firebase configured (project: penguin-af5d8)
- ✅ Cloud Functions code created
- ✅ Dependencies installed

## 🚀 Deploy Cloud Functions (One Command)

```bash
cd E:\flutter_projects\penguin_app
firebase deploy --only functions
```

That's it! Push notifications will work after this.

## 📱 Test the App

1. **Run the app:**
   ```bash
   cd E:\flutter_projects\penguin_app
   flutter run
   ```

2. **Enable Firebase Services** (if not done yet):
   - Go to https://console.firebase.google.com/project/penguin-af5d8
   - **Authentication** → Enable Email/Password
   - **Firestore Database** → Create database (test mode)
   - **Storage** → Get started (test mode)

3. **Test Push Notifications:**
   - Sign up two accounts
   - Grant notification permissions
   - Send a friend request → Should see notification
   - Close app → Send another request → Should get push notification!

## 📋 Features

- ✅ Anonymous gender-based matching
- ✅ Anonymous chat (black/purple theme)
- ✅ Friends chat (white/purple theme)
- ✅ Friend requests (after 6+ messages)
- ✅ Posts feed with 60s videos
- ✅ Likes and comments
- ✅ Profile with one-time name change
- ✅ Push notifications (foreground + background)
- ✅ In-app notifications

## 🎨 Theme

- Purple (#7C3AED) primary color
- Dark background
- Penguin branding

## 📁 Project Structure

```
penguin_app/
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── screens/
│   └── services/
├── functions/
│   ├── index.js (Cloud Function)
│   └── package.json
└── firebase.json
```

## 🔧 Troubleshooting

**App won't run?**
- Run `flutter pub get`
- Check Firebase services are enabled

**Push notifications not working?**
- Deploy functions: `firebase deploy --only functions`
- Check FCM tokens are saved in user documents
- Check notification permissions are granted

**Functions won't deploy?**
- Make sure you're logged in: `firebase login`
- Check Node.js is installed: `node -v`

## 📚 More Info

- See `DEPLOY_FUNCTIONS.md` for detailed function setup
- See `PUSH_NOTIFICATIONS_SETUP.md` for notification details

