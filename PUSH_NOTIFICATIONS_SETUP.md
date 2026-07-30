# Push Notifications Setup Guide

## Current Status

✅ **Foreground Notifications**: Working! When the app is open, you'll see local notifications for new messages, likes, comments, and friend requests.

⚠️ **Background Push Notifications**: Requires Cloud Functions setup (see below).

## How It Works

1. **FCM Token Registration**: When a user logs in, their FCM token is saved to their user document in Firestore.

2. **Notification Creation**: When events happen (friend request, like, comment), the app:
   - Creates a Firestore notification document
   - Adds a document to `push_notifications` collection (to trigger Cloud Function)

3. **Cloud Function**: Listens to `push_notifications` and sends actual FCM push notifications.

## Setup Cloud Functions (Required for Background Push)

### Option 1: Firebase Cloud Functions (Recommended)

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Initialize Functions**:
   ```bash
   cd E:\flutter_projects\penguin_app
   firebase init functions
   ```
   - Choose JavaScript or TypeScript
   - Install dependencies

3. **Create the Function**:

   Create `functions/index.js`:
   ```javascript
   const functions = require('firebase-functions');
   const admin = require('firebase-admin');
   admin.initializeApp();

   exports.sendPushNotification = functions.firestore
     .document('push_notifications/{notificationId}')
     .onCreate(async (snap, context) => {
       const data = snap.data();
       
       // Skip if already sent
       if (data.sent) return null;

       const message = {
         notification: {
           title: data.title,
           body: data.body,
         },
         data: data.data || {},
         token: data.fcmToken,
       };

       try {
         await admin.messaging().send(message);
         
         // Mark as sent
         await snap.ref.update({ sent: true });
         console.log('Push notification sent successfully');
       } catch (error) {
         console.error('Error sending push notification:', error);
       }
     });
   ```

4. **Deploy**:
   ```bash
   firebase deploy --only functions
   ```

### Option 2: Use a Backend Server

If you have a Node.js/Python backend, you can:
- Listen to Firestore `push_notifications` collection
- Use Firebase Admin SDK to send FCM messages
- This gives you more control but requires hosting

## Testing

1. **Foreground (App Open)**:
   - Send a friend request → Should see local notification immediately
   - Like a post → Should see notification
   - Comment on post → Should see notification

2. **Background (App Closed)**:
   - After Cloud Functions setup, close the app
   - Have another user send a friend request
   - You should receive a push notification

## Android Configuration

The app is already configured with `google-services.json`. For production, you may need to:
- Add SHA-1 fingerprint for release builds
- Configure notification channels (already done in code)

## iOS Configuration

For iOS, you need to:
1. Enable Push Notifications capability in Xcode
2. Upload APNs certificate to Firebase Console
3. Update `Info.plist` with notification permissions

## Free Tier Limits

- Firebase Cloud Messaging: **Unlimited** (free)
- Cloud Functions: **2 million invocations/month** (free tier)
- This should be plenty for a dating app starting out!

## Troubleshooting

- **No notifications in background**: Cloud Functions not deployed yet
- **No notifications in foreground**: Check if permissions were granted
- **Token not saving**: Check Firebase Auth is working
- **Notifications not appearing**: Check device notification settings

