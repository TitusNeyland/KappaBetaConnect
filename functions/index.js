const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendNewUserNotification = functions.firestore
    .document('users/{userId}')
    .onCreate(async (snap, context) => {
        const newUser = snap.data();
        const userId = context.params.userId;

        console.log('=== New User Document Created ===');
        console.log('User ID:', userId);
        console.log('User Data:', newUser);

        if (!newUser.firstName || !newUser.lastName) {
            console.log('❌ Missing name fields. Skipping notification.');
            return null;
        }

        try {
            const message = {
                notification: {
                    title: '🦍❄️ New Member Alert!',
                    body: `Welcome ${newUser.firstName} ${newUser.lastName} to Kappa Beta!`,
                },
                data: {
                    type: 'newMember',
                    userId: userId,
                },
                topic: 'allUsers',
                apns: {
                    payload: {
                        aps: {
                            alert: {
                                title: '🦍❄️ New Member Alert!',
                                body: `Welcome ${newUser.firstName} ${newUser.lastName} to Kappa Beta!`
                            },
                            sound: 'default',
                            badge: 1,
                            'content-available': 1
                        }
                    }
                }
            };

            console.log('Message payload:', JSON.stringify(message, null, 2));
            
            const response = await admin.messaging().send(message);
            console.log('✅ Notification sent successfully:', response);
            return null;
        } catch (error) {
            console.error('❌ Error sending push notification:', error);
            console.error('Error stack:', error.stack);
            return null;
        }
    }); 