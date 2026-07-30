const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Cloud Function that sends push notifications when a document is created
 * in the push_notifications collection.
 * 
 * This function listens to Firestore and sends FCM messages to users.
 */
exports.sendPushNotification = functions.firestore
  .document('push_notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    
    // Skip if already sent
    if (data.sent) {
      console.log('Notification already sent, skipping');
      return null;
    }

    const { toUid, fcmToken, title, body, data: notificationData } = data;

    // Validate required fields
    if (!fcmToken || !title || !body) {
      console.error('Missing required fields:', { fcmToken: !!fcmToken, title: !!title, body: !!body });
      return null;
    }

    // Prepare FCM message
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...notificationData,
        type: notificationData?.type || 'general',
      },
      token: fcmToken,
      android: {
        priority: 'high',
        notification: {
          channelId: 'penguin_channel',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    try {
      // Send the notification
      const response = await admin.messaging().send(message);
      console.log('Successfully sent push notification:', response);

      // Mark as sent
      await snap.ref.update({ 
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, messageId: response };
    } catch (error) {
      console.error('Error sending push notification:', error);
      
      // Mark as failed
      await snap.ref.update({ 
        sent: false,
        error: error.message,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // If token is invalid, remove it from user document
      if (error.code === 'messaging/invalid-registration-token' || 
          error.code === 'messaging/registration-token-not-registered') {
        console.log('Invalid token, removing from user document');
        const userRef = admin.firestore().collection('users').doc(toUid);
        await userRef.update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      }

      return { success: false, error: error.message };
    }
  });

/**
 * Optional: Clean up old push notification documents (older than 7 days)
 * Run this on a schedule to keep Firestore clean
 */
exports.cleanupOldNotifications = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const oldNotifications = await admin.firestore()
      .collection('push_notifications')
      .where('createdAt', '<', admin.firestore.Timestamp.fromDate(sevenDaysAgo))
      .limit(500)
      .get();

    const batch = admin.firestore().batch();
    oldNotifications.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Cleaned up ${oldNotifications.docs.length} old notifications`);
    return null;
  });

