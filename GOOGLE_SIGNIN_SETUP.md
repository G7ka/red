# Google Sign-In Setup Guide

## ✅ What's Implemented

- ✅ Google Sign-In button on welcome screen
- ✅ Full Google authentication flow
- ✅ Automatic user profile creation from Google account
- ✅ Profile image from Google account

## 🔧 Firebase Console Setup

### 1. Enable Google Sign-In Provider

1. Go to [Firebase Console](https://console.firebase.google.com/project/penguin-af5d8/authentication/providers)
2. Click **Authentication** → **Sign-in method**
3. Click **Google** → **Enable**
4. Set **Support email**: `selenakara54@gmail.com`
5. Set **Project public-facing name**: `project-979631219036` (or any name you want)
6. Click **Save**

### 2. Add SHA-1 Fingerprint (Required for Android)

You need to add your app's SHA-1 fingerprint to Firebase:

#### Get Debug SHA-1:
```bash
cd E:\flutter_projects\penguin_app\android
gradlew signingReport
```

Look for the SHA-1 in the output (under `Variant: debug`).

#### Or use keytool:
```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

#### Add to Firebase:
1. Go to Firebase Console → **Project Settings** → **Your apps**
2. Find your Android app (`com.example.penguin_app`)
3. Click **Add fingerprint**
4. Paste your SHA-1
5. Click **Save**

### 3. For Release Builds

When you build a release APK, you'll need to add the release SHA-1 too:
```bash
keytool -list -v -keystore YOUR_RELEASE_KEYSTORE -alias YOUR_KEY_ALIAS
```

## 📱 Testing

1. **Run the app:**
   ```bash
   cd E:\flutter_projects\penguin_app
   flutter run
   ```

2. **Click "Continue with Google"**
   - Should open Google sign-in dialog
   - After signing in, creates user profile automatically
   - Navigates to home screen

3. **Check Firebase Console:**
   - Go to **Authentication** → **Users**
   - Should see the Google user
   - Go to **Firestore** → **users** collection
   - Should see user document with Google profile data

## 🔍 How It Works

1. User taps "Continue with Google"
2. Google Sign-In dialog appears
3. User selects Google account
4. App receives Google credentials
5. Signs in to Firebase with Google credential
6. Creates user document in Firestore if new user
7. Uses Google profile picture and name
8. Navigates to home screen

## ⚠️ Important Notes

- **New Google users** get a default profile (gender: male, age: 25)
- They can edit their profile later in the Profile tab
- **Existing Google users** (who signed in before) will use their existing profile
- Profile image is automatically set from Google account

## 🐛 Troubleshooting

### "Sign in failed"
- Check SHA-1 is added in Firebase Console
- Make sure Google Sign-In is enabled in Firebase
- Check internet connection

### "PlatformException"
- Make sure `google-services.json` is in `android/app/`
- Run `flutter clean` and `flutter pub get`
- Rebuild the app

### "User canceled"
- This is normal - user closed the Google sign-in dialog
- No error, just returns to welcome screen

## 📚 Next Steps

After Google Sign-In works, users can:
- Complete their profile (gender, DOB, interests) in Profile tab
- Start using all app features
- Sign in again later with same Google account

