# Deploy Cloud Functions for Push Notifications

## Quick Setup (3 Steps)

### 1. Install Dependencies

```bash
cd E:\flutter_projects\penguin_app\functions
npm install
```

### 2. Deploy Functions

```bash
cd E:\flutter_projects\penguin_app
firebase deploy --only functions
```

### 3. Test It!

1. Run your Flutter app
2. Sign up two accounts
3. Close the app on one device
4. Send a friend request from the other account
5. You should receive a push notification! 🎉

## What Gets Deployed

- **sendPushNotification**: Automatically sends FCM push notifications when documents are created in `push_notifications` collection
- **cleanupOldNotifications**: Runs daily to clean up old notification documents (optional)

## How It Works

1. Your Flutter app creates a document in `push_notifications` collection
2. Cloud Function detects the new document
3. Function sends FCM push notification to the user's device
4. Document is marked as `sent: true`

## Troubleshooting

### "Functions directory not found"
- Make sure you're in the project root: `E:\flutter_projects\penguin_app`
- Check that `functions/` folder exists

### "npm not found"
- Install Node.js from https://nodejs.org
- Restart your terminal

### "Permission denied"
- Make sure you're logged in: `firebase login`
- Check you have the right project: `firebase use penguin-af5d8`

### Functions not triggering
- Check Firebase Console → Functions → Logs
- Verify documents are being created in `push_notifications` collection
- Check that FCM tokens are saved in user documents

## Free Tier Limits

- **2 million invocations/month** (free)
- **400,000 GB-seconds compute time/month** (free)
- This is plenty for a dating app starting out!

## Monitoring

View function logs:
```bash
firebase functions:log
```

Or in Firebase Console:
- Go to Functions → Logs

## Next Steps

After deployment, your push notifications will work in the background! Users will receive notifications even when the app is closed.

