import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();

export const sendNewUserNotification = onDocumentCreated("users/{userId}", async (event) => {
    const newUser = event.data.data();
    const userId = event.params.userId;

    console.log('=== New User Document Created ===');
    console.log('User ID:', userId);
    console.log('User Data:', newUser);

    if (!newUser.firstName || !newUser.lastName) {
        console.log('❌ Missing name fields. Skipping notification.');
        return;
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
                        'mutable-content': 1,
                        'content-available': 1
                    }
                },
                headers: {
                    'apns-priority': '10'
                }
            }
        };

        console.log('Message payload:', JSON.stringify(message, null, 2));
        const { getMessaging } = await import("firebase-admin/messaging");
        const messaging = getMessaging();
        const response = await messaging.send(message);
        console.log('✅ Notification sent successfully:', response);
    } catch (error) {
        console.error('❌ Error sending push notification:', error);
        console.error('Error stack:', error.stack);
    }
});

export const sendLikeNotification = onDocumentUpdated("posts/{postId}", async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // If likes array didn't change, exit
    if (!before.likes || !after.likes || before.likes.length >= after.likes.length) {
        return;
    }

    // Find the new liker (the userId that is in after.likes but not in before.likes)
    const newLikerId = after.likes.find(id => !before.likes.includes(id));
    if (!newLikerId) return;

    // Don't notify if the author liked their own post
    if (after.authorId === newLikerId) return;

    // Get the post author
    const authorSnap = await db.collection('users').doc(after.authorId).get();
    const author = authorSnap.data();
    if (!author || !author.fcmToken) return;

    // Get the liker's name
    const likerSnap = await db.collection('users').doc(newLikerId).get();
    const liker = likerSnap.data();
    const likerName = liker ? `${liker.firstName} ${liker.lastName}` : 'Someone';

    // Send notification
    const message = {
        notification: {
            title: '👍 New Like!',
            body: `${likerName} liked your post.`,
        },
        token: author.fcmToken,
        apns: {
            payload: {
                aps: {
                    alert: {
                        title: '👍 New Like!',
                        body: `${likerName} liked your post.`
                    },
                    sound: 'default',
                    badge: 1,
                    'mutable-content': 1,
                    'content-available': 1
                }
            },
            headers: {
                'apns-priority': '10'
            }
        }
    };

    const { getMessaging } = await import("firebase-admin/messaging");
    const messaging = getMessaging();
    await messaging.send(message);
});

export const sendCommentNotification = onDocumentUpdated("posts/{postId}", async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // If comments array didn't change, exit
    if (!before.comments || !after.comments || before.comments.length >= after.comments.length) {
        return;
    }

    // Find the new comment (the one in after.comments but not in before.comments)
    const newComment = after.comments.find(
        c => !before.comments.some(bc => bc.id === c.id)
    );
    if (!newComment) return;

    // Don't notify if the author commented on their own post
    if (after.authorId === newComment.authorId) return;

    // Get the post author
    const authorSnap = await db.collection('users').doc(after.authorId).get();
    const author = authorSnap.data();
    if (!author || !author.fcmToken) return;

    // Get the commenter's name
    const commenterName = newComment.authorName || 'Someone';

    // Send notification
    const message = {
        notification: {
            title: '💬 New Comment!',
            body: `${commenterName} commented on your post.`,
        },
        token: author.fcmToken,
        apns: {
            payload: {
                aps: {
                    alert: {
                        title: '💬 New Comment!',
                        body: `${commenterName} commented on your post.`
                    },
                    sound: 'default',
                    badge: 1,
                    'mutable-content': 1,
                    'content-available': 1
                }
            },
            headers: {
                'apns-priority': '10'
            }
        }
    };

    const { getMessaging } = await import("firebase-admin/messaging");
    const messaging = getMessaging();
    await messaging.send(message);
});

export const sendNewPostNotification = onDocumentCreated("posts/{postId}", async (event) => {
    const newPost = event.data.data();
    const postId = event.params.postId;

    // Get the author
    const authorId = newPost.authorId;
    const authorName = newPost.authorName || 'Someone';

    // Get all users except the author
    const usersSnap = await db.collection('users').get();
    const tokens = usersSnap.docs
        .map(doc => doc.data())
        .filter(user => user.fcmToken && user.id !== authorId)
        .map(user => user.fcmToken);

    if (tokens.length === 0) return;

    // Send notification to all users except the author
    const message = {
        notification: {
            title: '📝 New Post!',
            body: `${authorName} just posted something new!`,
        },
        tokens: tokens,
        apns: {
            payload: {
                aps: {
                    alert: {
                        title: '📝 New Post!',
                        body: `${authorName} just posted something new!`
                    },
                    sound: 'default',
                    badge: 1,
                    'mutable-content': 1,
                    'content-available': 1
                }
            },
            headers: {
                'apns-priority': '10'
            }
        }
    };

    const { getMessaging } = await import("firebase-admin/messaging");
    const messaging = getMessaging();
    await messaging.sendEachForMulticast(message);
}); 