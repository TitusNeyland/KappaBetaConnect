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

    // Send notification to post author
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

    // Send notifications to users who previously commented on this post
    const previousCommenters = new Set(before.comments.map(c => c.authorId));
    // Remove the post author and the new commenter from the set
    previousCommenters.delete(after.authorId);
    previousCommenters.delete(newComment.authorId);

    // Get FCM tokens for all previous commenters
    const commenterSnaps = await Promise.all(
        Array.from(previousCommenters).map(id => db.collection('users').doc(id).get())
    );

    const commenterTokens = commenterSnaps
        .map(snap => snap.data())
        .filter(user => user && user.fcmToken)
        .map(user => user.fcmToken);

    if (commenterTokens.length > 0) {
        const commenterMessage = {
            notification: {
                title: '💬 New Comment!',
                body: `${commenterName} commented on the same post.`,
            },
            tokens: commenterTokens,
            apns: {
                payload: {
                    aps: {
                        alert: {
                            title: '💬 New Comment!',
                            body: `${commenterName} commented on the same post.`
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
        await messaging.sendEachForMulticast(commenterMessage);
    }

    // --- Mention Notification Logic ---
    if (Array.isArray(newComment.mentions)) {
        for (const mention of newComment.mentions) {
            const mentionedUserId = mention.userId;
            // Don't notify the commenter or the post author again
            if (mentionedUserId === newComment.authorId || mentionedUserId === after.authorId) continue;
            const mentionedUserSnap = await db.collection('users').doc(mentionedUserId).get();
            const mentionedUser = mentionedUserSnap.data();
            if (!mentionedUser || !mentionedUser.fcmToken) continue;

            const mentionMessage = {
                notification: {
                    title: '🔔 You were mentioned!',
                    body: `${commenterName} mentioned you in a comment: "${newComment.content}"`,
                },
                data: {
                    type: 'mention',
                    postId: event.params.postId,
                },
                token: mentionedUser.fcmToken,
                apns: {
                    payload: {
                        aps: {
                            alert: {
                                title: '🔔 You were mentioned!',
                                body: `${commenterName} mentioned you in a comment: "${newComment.content}"`
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
            await messaging.send(mentionMessage);
        }
    }
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
        .filter(doc => doc.id !== authorId && doc.data().fcmToken)
        .map(doc => doc.data().fcmToken);

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

export const sendNewEventNotification = onDocumentCreated("events/{eventId}", async (event) => {
    const newEvent = event.data.data();
    const eventId = event.params.eventId;

    console.log('=== New Event Document Created ===');
    console.log('Event ID:', eventId);
    console.log('Event Data:', newEvent);

    if (!newEvent.title) {
        console.log('❌ Missing title field. Skipping notification.');
        return;
    }

    try {
        // Get the creator's name
        const creatorDoc = await db.collection('users').doc(newEvent.createdBy).get();
        const creator = creatorDoc.data();
        const creatorName = creator ? `${creator.firstName} ${creator.lastName}` : 'Someone';

        // Format the date
        const eventDate = newEvent.date.toDate(); // Convert Firestore Timestamp to Date
        const formatter = new Intl.DateTimeFormat('en-US', {
            weekday: 'long',
            month: 'long',
            day: 'numeric',
            hour: 'numeric',
            minute: 'numeric'
        });
        const formattedDate = formatter.format(eventDate);

        // Get all users except the creator
        const usersSnap = await db.collection('users').get();
        const tokens = usersSnap.docs
            .filter(doc => doc.id !== newEvent.createdBy && doc.data().fcmToken)
            .map(doc => doc.data().fcmToken);

        if (tokens.length === 0) return;

        const message = {
            notification: {
                title: '📅 New Event: ' + newEvent.title,
                body: `${creatorName} created a new event for ${formattedDate} at ${newEvent.location}`,
            },
            data: {
                type: 'newEvent',
                eventId: eventId,
            },
            tokens: tokens,
            apns: {
                payload: {
                    aps: {
                        alert: {
                            title: '📅 New Event: ' + newEvent.title,
                            body: `${creatorName} created a new event for ${formattedDate} at ${newEvent.location}`
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
        const response = await messaging.sendEachForMulticast(message);
        console.log('✅ Event notification sent successfully:', response);
    } catch (error) {
        console.error('❌ Error sending event notification:', error);
        console.error('Error stack:', error.stack);
    }
});

export const sendCommentLikeNotification = onDocumentUpdated("posts/{postId}", async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const postId = event.params.postId;
    const db = (await import("firebase-admin/firestore")).getFirestore();

    // Helper to check for new likes on comments or replies
    function findNewLikes(beforeComments, afterComments, parentAuthorId = null) {
        let notifications = [];
        for (let i = 0; i < afterComments.length; i++) {
            const beforeComment = beforeComments[i] || {};
            const afterComment = afterComments[i];
            // Check likes on the comment itself
            const beforeLikes = beforeComment.likes || [];
            const afterLikes = afterComment.likes || [];
            if (afterLikes.length > beforeLikes.length) {
                // Find the new liker
                const newLiker = afterLikes.find(liker => !beforeLikes.includes(liker));
                if (newLiker && afterComment.authorId !== newLiker) {
                    notifications.push({
                        recipientId: afterComment.authorId,
                        likerId: newLiker,
                        commentId: afterComment.id,
                        isReply: !!parentAuthorId,
                    });
                }
            }
            // Check replies recursively
            if (afterComment.replies && afterComment.replies.length > 0) {
                const beforeReplies = beforeComment.replies || [];
                notifications = notifications.concat(
                    findNewLikes(beforeReplies, afterComment.replies, afterComment.authorId)
                );
            }
        }
        return notifications;
    }

    if (!before.comments || !after.comments) return;
    const notifications = findNewLikes(before.comments, after.comments);

    for (const notif of notifications) {
        // Get liker info
        const likerSnap = await db.collection("users").doc(notif.likerId).get();
        const liker = likerSnap.data();
        if (!liker) continue;

        // Get recipient info
        const recipientSnap = await db.collection("users").doc(notif.recipientId).get();
        const recipient = recipientSnap.data();
        if (!recipient || !recipient.fcmToken) continue;

        const likerName = liker.firstName && liker.lastName ? `${liker.firstName} ${liker.lastName}` : "Someone";
        const message = {
            notification: {
                title: "❤️ New Like!",
                body: `${likerName} liked your comment`,
            },
            data: {
                type: "comment_like",
                postId,
                commentId: notif.commentId,
            },
            token: recipient.fcmToken,
            apns: {
                payload: {
                    aps: {
                        alert: {
                            title: "❤️ New Like!",
                            body: `${likerName} liked your comment`
                        },
                        sound: "default",
                        badge: 1,
                        "mutable-content": 1,
                        "content-available": 1
                    }
                },
                headers: {
                    "apns-priority": "10"
                }
            }
        };
        const { getMessaging } = await import("firebase-admin/messaging");
        const messaging = getMessaging();
        await messaging.send(message);
    }
    return null;
}); 