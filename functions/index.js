const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * 1. Push notification for Chat Messages (1-on-1 & Group Chats in /chats/)
 */
exports.onChatMessageCreated = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    if (!message) return null;

    const { chatId } = context.params;
    const { senderId, receiverId, groupId, text, type, reactionEmoji, taggedUserIds } = message;
    if (!senderId) return null;

    // A. If this is a Group Chat message
    if (groupId || (chatId && chatId.startsWith("group_")) || (!receiverId && chatId)) {
      const actualGroupId = groupId || chatId;
      try {
        const [chatDoc, senderDoc] = await Promise.all([
          admin.firestore().collection("chats").doc(actualGroupId).get(),
          admin.firestore().collection("users").doc(senderId).get(),
        ]);

        const chatData = chatDoc.data() || {};
        const senderData = senderDoc.data() || {};
        const isGroup = chatData.isGroup === true || Boolean(groupId);

        if (isGroup) {
          const members = chatData.participants || [];
          const groupName = chatData.groupName || "Nhóm";
          const senderName = senderData.name || senderData.username || "Thành viên";
          const mutedBy = chatData.mutedBy || [];
          const tags = Array.isArray(taggedUserIds) ? taggedUserIds : [];
          const isSystem = type === "system";

          const targetMembers = members.filter((uid) => uid !== senderId);
          if (targetMembers.length === 0) return null;

          // 1. Tagged members: Always notify with mention message
          const taggedMembers = targetMembers.filter((uid) => tags.includes(uid));
          for (const taggedUid of taggedMembers) {
            const userDoc = await admin.firestore().collection("users").doc(taggedUid).get();
            const userData = userDoc.data() || {};
            const tokens = getValidTokens(userData);
            if (tokens.length > 0) {
              const isEn = (userData.language || "").toLowerCase() === "en";
              const body = isEn
                ? `${senderName} mentioned you: "${text || ""}"`
                : `${senderName} đã nhắc đến bạn: "${text || ""}"`;

              const mentionPayload = {
                notification: {
                  title: groupName,
                  body: body,
                },
                data: {
                  type: "group_chat",
                  groupId: actualGroupId,
                  groupName: groupName,
                  isMention: "true",
                  channelId: "chat_messages_channel_v3",
                },
                android: {
                  priority: "high",
                  notification: {
                    channelId: "chat_messages_channel_v3",
                    sound: "meme_sound",
                    defaultSound: false,
                    defaultVibrateTimings: true,
                  },
                },
                apns: {
                  payload: {
                    aps: { sound: "meme_sound.mp3", badge: 1 },
                  },
                },
                tokens: tokens,
              };
              await admin.messaging().sendEachForMulticast(mentionPayload);
            }
          }

          // 2. Normal members (exclude muted members UNLESS message is a system message, and exclude already-tagged members)
          const normalMembers = targetMembers.filter((uid) => {
            if (taggedMembers.includes(uid)) return false;
            if (isSystem) return true; // System messages are never muted
            return !mutedBy.includes(uid);
          });

          for (const normalUid of normalMembers) {
            const userDoc = await admin.firestore().collection("users").doc(normalUid).get();
            const userData = userDoc.data() || {};
            const tokens = getValidTokens(userData);
            if (tokens.length > 0) {
              const isEn = (userData.language || "").toLowerCase() === "en";
              let body = isSystem
                ? text
                : isEn
                ? `${senderName}: ${text || "Sent a message"}`
                : `${senderName}: ${text || "Đã gửi tin nhắn"}`;

              const normalPayload = {
                notification: {
                  title: groupName,
                  body: body,
                },
                data: {
                  type: "group_chat",
                  groupId: actualGroupId,
                  groupName: groupName,
                  channelId: "chat_messages_channel_v3",
                },
                android: {
                  priority: "high",
                  notification: {
                    channelId: "chat_messages_channel_v3",
                    sound: "meme_sound",
                    defaultSound: false,
                    defaultVibrateTimings: true,
                  },
                },
                apns: {
                  payload: {
                    aps: { sound: "meme_sound.mp3", badge: 1 },
                  },
                },
                tokens: tokens,
              };
              await admin.messaging().sendEachForMulticast(normalPayload);
            }
          }

          return null;
        }
      } catch (e) {
        console.error("Error in onChatMessageCreated group branch:", e);
      }
    }

    // B. 1-on-1 Chat message
    if (!receiverId || senderId === receiverId) return null;

    try {
      const [senderDoc, receiverDoc] = await Promise.all([
        admin.firestore().collection("users").doc(senderId).get(),
        admin.firestore().collection("users").doc(receiverId).get(),
      ]);

      const senderData = senderDoc.data() || {};
      const receiverData = receiverDoc.data() || {};
      const tokens = getValidTokens(receiverData);

      if (tokens.length === 0) return null;

      const isEn = (receiverData.language || "").toLowerCase() === "en";
      const senderName = senderData.name || senderData.username || (isEn ? "Friend" : "Bạn bè");
      let bodyText = text || (isEn ? "Sent a message" : "Đã gửi tin nhắn");

      if (type === "reaction") {
        bodyText = isEn
          ? `Reacted: ${reactionEmoji || "❤️"}`
          : `Đã thả cảm xúc: ${reactionEmoji || "❤️"}`;
      } else if (type === "post_reply") {
        bodyText = isEn
          ? `Replied to post: "${text || ""}"`
          : `Đã phản hồi bài viết: "${text || ""}"`;
      } else if (type === "note_reply") {
        bodyText = isEn
          ? `Replied to your note: ${text || "❤️"}`
          : `Đã phản hồi ghi chú của bạn: ${text || "❤️"}`;
      }

      const payload = {
        notification: {
          title: senderName,
          body: bodyText,
        },
        data: {
          type: "chat",
          senderUid: senderId,
          senderName: senderName,
          senderAvatar: senderData.avatarUrl || "",
          channelId: "chat_messages_channel_v3",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "chat_messages_channel_v3",
            sound: "meme_sound",
            defaultSound: false,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "meme_sound",
              badge: 1,
            },
          },
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(payload);
      await cleanupInvalidTokens(receiverId, tokens, response);
      return null;
    } catch (e) {
      console.error("Error sending chat notification:", e);
      return null;
    }
  });

/**
 * 2. Push notification for Legacy group_chats collection
 */
exports.onGroupChatMessageCreated = functions.firestore
  .document("group_chats/{groupId}/messages/{messageId}")
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();
    if (!message) return null;

    const { groupId } = context.params;
    const { senderId, text, taggedUserIds, type } = message;
    if (!groupId || !senderId) return null;

    try {
      const [groupDoc, senderDoc] = await Promise.all([
        admin.firestore().collection("group_chats").doc(groupId).get(),
        admin.firestore().collection("users").doc(senderId).get(),
      ]);

      const groupData = groupDoc.data() || {};
      const senderData = senderDoc.data() || {};
      const members = groupData.members || groupData.participants || [];
      const groupName = groupData.name || "Nhóm";
      const senderName = senderData.name || senderData.username || "Thành viên";
      const mutedBy = groupData.mutedBy || [];
      const tags = Array.isArray(taggedUserIds) ? taggedUserIds : [];
      const isSystem = type === "system";

      const targetMembers = members.filter((uid) => uid !== senderId);
      if (targetMembers.length === 0) return null;

      // 1. Tagged members: Always notify
      const taggedMembers = targetMembers.filter((uid) => tags.includes(uid));
      for (const taggedUid of taggedMembers) {
        const userDoc = await admin.firestore().collection("users").doc(taggedUid).get();
        const userData = userDoc.data() || {};
        const tokens = getValidTokens(userData);
        if (tokens.length > 0) {
          const isEn = (userData.language || "").toLowerCase() === "en";
          const body = isEn
            ? `${senderName} mentioned you: "${text || ""}"`
            : `${senderName} đã nhắc đến bạn: "${text || ""}"`;

          const mentionPayload = {
            notification: {
              title: groupName,
              body: body,
            },
            data: {
              type: "group_chat",
              groupId: groupId,
              groupName: groupName,
              isMention: "true",
              channelId: "chat_messages_channel_v3",
            },
            android: {
              priority: "high",
              notification: {
                channelId: "chat_messages_channel_v3",
                sound: "meme_sound",
                defaultSound: false,
                defaultVibrateTimings: true,
              },
            },
            apns: {
              payload: {
                aps: { sound: "meme_sound.mp3", badge: 1 },
              },
            },
            tokens: tokens,
          };
          await admin.messaging().sendEachForMulticast(mentionPayload);
        }
      }

      // 2. Normal members
      const normalMembers = targetMembers.filter((uid) => {
        if (taggedMembers.includes(uid)) return false;
        if (isSystem) return true;
        return !mutedBy.includes(uid);
      });

      for (const normalUid of normalMembers) {
        const userDoc = await admin.firestore().collection("users").doc(normalUid).get();
        const userData = userDoc.data() || {};
        const tokens = getValidTokens(userData);
        if (tokens.length > 0) {
          const isEn = (userData.language || "").toLowerCase() === "en";
          let body = isSystem
            ? text
            : isEn
            ? `${senderName}: ${text || "Sent a message"}`
            : `${senderName}: ${text || "Đã gửi tin nhắn"}`;

          const normalPayload = {
            notification: {
              title: groupName,
              body: body,
            },
            data: {
              type: "group_chat",
              groupId: groupId,
              groupName: groupName,
              channelId: "chat_messages_channel_v3",
            },
            android: {
              priority: "high",
              notification: {
                channelId: "chat_messages_channel_v3",
                sound: "meme_sound",
                defaultSound: false,
                defaultVibrateTimings: true,
              },
            },
            apns: {
              payload: {
                aps: { sound: "meme_sound.mp3", badge: 1 },
              },
            },
            tokens: tokens,
          };
          await admin.messaging().sendEachForMulticast(normalPayload);
        }
      }

      return null;
    } catch (e) {
      console.error("Error sending group chat notification:", e);
      return null;
    }
  });

/**
 * 3. Push notification for Friend Requests
 */
exports.onFriendRequestCreated = functions.firestore
  .document("users/{userId}/friend_requests/{senderId}")
  .onCreate(async (snapshot, context) => {
    const { userId, senderId } = context.params;

    try {
      const [senderDoc, receiverDoc] = await Promise.all([
        admin.firestore().collection("users").doc(senderId).get(),
        admin.firestore().collection("users").doc(userId).get(),
      ]);

      const senderData = senderDoc.data() || {};
      const receiverData = receiverDoc.data() || {};
      const tokens = getValidTokens(receiverData);

      if (tokens.length === 0) return null;

      const isEn = (receiverData.language || "").toLowerCase() === "en";
      const senderName = senderData.name || senderData.username || (isEn ? "Someone" : "Ai đó");

      const title = isEn ? "New friend request 👋" : "Lời mời kết bạn mới 👋";
      const body = isEn
        ? `${senderName} sent you a friend request!`
        : `${senderName} vừa gửi lời mời kết bạn đến bạn!`;

      const payload = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: "friend_request",
          senderUid: senderId,
          channelId: "friend_requests_channel_v3",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "friend_requests_channel_v3",
            sound: "meme_sound",
            defaultSound: false,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "meme_sound",
              badge: 1,
            },
          },
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(payload);
      await cleanupInvalidTokens(userId, tokens, response);
      return null;
    } catch (e) {
      console.error("Error sending friend request notification:", e);
      return null;
    }
  });

/**
 * 4. Push notification when Friend Request is Accepted
 */
exports.onFriendAccepted = functions.firestore
  .document("users/{userId}/friends/{friendId}")
  .onCreate(async (snapshot, context) => {
    const { userId, friendId } = context.params;

    try {
      const [userDoc, friendDoc] = await Promise.all([
        admin.firestore().collection("users").doc(userId).get(),
        admin.firestore().collection("users").doc(friendId).get(),
      ]);

      const userData = userDoc.data() || {};
      const friendData = friendDoc.data() || {};
      const tokens = getValidTokens(friendData);

      if (tokens.length === 0) return null;

      const isEn = (friendData.language || "").toLowerCase() === "en";
      const userName = userData.name || userData.username || (isEn ? "A friend" : "Bạn bè");

      const title = isEn ? "Friend request accepted 🎉" : "Kết bạn thành công 🎉";
      const body = isEn
        ? `${userName} accepted your friend request!`
        : `${userName} đã chấp nhận lời mời kết bạn của bạn!`;

      const payload = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: "friend_accepted",
          senderUid: userId,
          channelId: "friend_requests_channel_v3",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "friend_requests_channel_v3",
            sound: "meme_sound",
            defaultSound: false,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "meme_sound",
              badge: 1,
            },
          },
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(payload);
      await cleanupInvalidTokens(friendId, tokens, response);
      return null;
    } catch (e) {
      console.error("Error sending friend accepted notification:", e);
      return null;
    }
  });

/**
 * 5. Push notification when someone reacts to your Post
 */
exports.onPostReactionCreated = functions.firestore
  .document("transactions/{postId}/reactions/{reactionId}")
  .onCreate(async (snapshot, context) => {
    const reaction = snapshot.data();
    if (!reaction) return null;

    const { postId } = context.params;
    const reactorId = reaction.userId || reaction.senderId;
    const emoji = reaction.emoji || "❤️";

    try {
      const postDoc = await admin.firestore().collection("transactions").doc(postId).get();
      if (!postDoc.exists) return null;

      const postData = postDoc.data() || {};
      const postOwnerId = postData.userId;

      // Không gửi thông báo nếu tự thả cảm xúc lên bài của chính mình
      if (!postOwnerId || postOwnerId === reactorId) return null;

      // Check if this reactor already has existing reactions on this post to prevent spamming notifications
      const existingReactions = await admin
        .firestore()
        .collection("transactions")
        .doc(postId)
        .collection("reactions")
        .where("userId", "==", reactorId)
        .limit(2)
        .get();

      // If more than 1 reaction exists for this user, this is a repeated/spam reaction -> skip push notification
      if (existingReactions.size > 1) {
        return null;
      }

      const [reactorDoc, postOwnerDoc] = await Promise.all([
        admin.firestore().collection("users").doc(reactorId).get(),
        admin.firestore().collection("users").doc(postOwnerId).get(),
      ]);

      const reactorData = reactorDoc.data() || {};
      const postOwnerData = postOwnerDoc.data() || {};
      const tokens = getValidTokens(postOwnerData);

      if (tokens.length === 0) return null;

      const isEn = (postOwnerData.language || "").toLowerCase() === "en";
      const reactorName =
        reaction.userName ||
        reactorData.name ||
        reactorData.username ||
        (isEn ? "Someone" : "Ai đó");

      const body = isEn
        ? `${reactorName} reacted ${emoji} to your post`
        : `${reactorName} đã thả cảm xúc ${emoji} lên bài viết của bạn`;

      const payload = {
        notification: {
          title: reactorName,
          body: body,
        },
        data: {
          type: "post_reaction",
          postId: postId,
          senderUid: reactorId,
          channelId: "chat_messages_channel_v3",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "chat_messages_channel_v3",
            sound: "meme_sound",
            defaultSound: false,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "meme_sound",
              badge: 1,
            },
          },
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(payload);
      await cleanupInvalidTokens(postOwnerId, tokens, response);
      return null;
    } catch (e) {
      console.error("Error sending post reaction notification:", e);
      return null;
    }
  });

/**
 * 6. Push notification when someone reacts to your Status Note
 */
exports.onNoteReactionWritten = functions.firestore
  .document("users/{userId}/note_reactions/{reactorId}")
  .onWrite(async (change, context) => {
    // Chỉ gửi khi tạo mới hoặc cập nhật cảm xúc
    if (!change.after.exists) return null;

    const reaction = change.after.data();
    if (!reaction) return null;

    const { userId, reactorId } = context.params;
    if (!userId || !reactorId || userId === reactorId) return null;

    const emoji = reaction.emoji || "❤️";

    try {
      const [reactorDoc, ownerDoc] = await Promise.all([
        admin.firestore().collection("users").doc(reactorId).get(),
        admin.firestore().collection("users").doc(userId).get(),
      ]);

      const reactorData = reactorDoc.data() || {};
      const ownerData = ownerDoc.data() || {};
      const tokens = getValidTokens(ownerData);

      if (tokens.length === 0) return null;

      const isEn = (ownerData.language || "").toLowerCase() === "en";
      const reactorName =
        reaction.reactorName ||
        reactorData.name ||
        reactorData.username ||
        (isEn ? "Someone" : "Ai đó");

      const body = isEn
        ? `${reactorName} reacted ${emoji} to your note`
        : `${reactorName} đã thả cảm xúc ${emoji} lên ghi chú của bạn`;

      const payload = {
        notification: {
          title: reactorName,
          body: body,
        },
        data: {
          type: "note_reaction",
          senderUid: reactorId,
          channelId: "chat_messages_channel_v3",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "chat_messages_channel_v3",
            sound: "meme_sound",
            defaultSound: false,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "meme_sound",
              badge: 1,
            },
          },
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(payload);
      await cleanupInvalidTokens(userId, tokens, response);
      return null;
    } catch (e) {
      console.error("Error sending note reaction notification:", e);
      return null;
    }
  });

/**
 * 7. Push notification when you are Mentioned / Tagged in a post
 */
exports.onUserNotificationCreated = functions.firestore
  .document("users/{userId}/notifications/{notificationId}")
  .onCreate(async (snapshot, context) => {
    const notif = snapshot.data();
    if (!notif) return null;

    const { userId } = context.params;
    const type = notif.type;

    if (type !== "mention" && type !== "group_invite") return null;

    try {
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const userData = userDoc.data() || {};
      const tokens = getValidTokens(userData);

      if (tokens.length === 0) return null;

      const isEn = (userData.language || "").toLowerCase() === "en";
      let title = notif.senderName || "Meme";
      let body = notif.body || (isEn ? "You have a new notification" : "Bạn có thông báo mới");

      if (type === "mention") {
        const senderName = notif.senderName || (isEn ? "Someone" : "Ai đó");
        const caption = notif.caption ? `: "${notif.caption}"` : "";
        title = senderName;
        body = isEn
          ? `${senderName} mentioned you in a post${caption}`
          : `${senderName} đã nhắc đến bạn trong một bài viết${caption}`;
      }

      const payload = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          type: type,
          postId: notif.postId || "",
          senderUid: notif.senderUid || "",
          groupId: notif.groupId || "",
          channelId: "chat_messages_channel_v3",
        },
        android: {
          priority: "high",
          notification: {
            channelId: "chat_messages_channel_v3",
            sound: "meme_sound",
            defaultSound: false,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "meme_sound",
              badge: 1,
            },
          },
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(payload);
      await cleanupInvalidTokens(userId, tokens, response);
      return null;
    } catch (e) {
      console.error("Error sending user notification FCM:", e);
      return null;
    }
  });

/**
 * 8. Push notification when Group Fund has Expense or Contribution
 */
exports.onGroupTransactionCreated = functions.firestore
  .document("transactions/{transactionId}")
  .onCreate(async (snapshot, context) => {
    const tx = snapshot.data();
    if (!tx || !tx.groupId) return null;

    const { groupId, userId, amount, category, caption, isGroupContribution } = tx;

    try {
      const [creatorDoc, groupDoc] = await Promise.all([
        admin.firestore().collection("users").doc(userId).get(),
        admin.firestore().collection("group_chats").doc(groupId).get(),
      ]);

      const creatorData = creatorDoc.data() || {};
      const groupData = groupDoc.data() || {};
      const creatorName = creatorData.name || creatorData.username || "Thành viên";
      const groupName = groupData.name || tx.groupName || "Nhóm";

      let memberIds = tx.groupMemberIds || groupData.members || groupData.participants || [];
      const targetMembers = memberIds.filter((uid) => uid !== userId);

      if (targetMembers.length === 0) return null;

      const formattedAmount = Number(amount || 0).toLocaleString("vi-VN");
      const desc = caption || category || "Giao dịch";

      for (const targetUid of targetMembers) {
        const memberDoc = await admin.firestore().collection("users").doc(targetUid).get();
        const memberData = memberDoc.data() || {};
        const tokens = getValidTokens(memberData);
        if (tokens.length === 0) continue;

        const isEn = (memberData.language || "").toLowerCase() === "en";
        const isFund = isGroupContribution === true || category === "Quỹ nhóm" || category === "Group Fund";

        let title = isFund ? `${groupName} 💰` : `${groupName} 💳`;
        let body = "";

        if (isFund) {
          body = isEn
            ? `${creatorName} added to group fund: +${formattedAmount}đ (${desc})`
            : `${creatorName} vừa nạp quỹ nhóm: +${formattedAmount}đ (${desc})`;
        } else {
          body = isEn
            ? `${creatorName} spent from group fund: -${formattedAmount}đ (${desc})`
            : `${creatorName} vừa chi tiêu nhóm: -${formattedAmount}đ (${desc})`;
        }

        const payload = {
          notification: {
            title: title,
            body: body,
          },
          data: {
            type: "group_transaction",
            groupId: groupId,
            groupName: groupName,
            transactionId: context.params.transactionId,
            channelId: "chat_messages_channel_v3",
          },
          android: {
            priority: "high",
            notification: {
              channelId: "chat_messages_channel_v3",
              sound: "meme_sound",
              defaultSound: false,
              defaultVibrateTimings: true,
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "meme_sound",
                badge: 1,
              },
            },
          },
          tokens: tokens,
        };

        await admin.messaging().sendEachForMulticast(payload);
      }

      return null;
    } catch (e) {
      console.error("Error sending group transaction notification:", e);
      return null;
    }
  });

/**
 * Helper: Extract all valid tokens from a user document
 */
function getValidTokens(userData) {
  if (!userData) return [];
  const tokens = [];
  if (Array.isArray(userData.fcmTokens)) {
    userData.fcmTokens.forEach((t) => {
      if (typeof t === "string" && t.trim().length > 0 && !tokens.includes(t)) {
        tokens.push(t);
      }
    });
  }
  if (tokens.length === 0 && typeof userData.lastFcmToken === "string" && userData.lastFcmToken.trim().length > 0) {
    tokens.push(userData.lastFcmToken);
  }
  return tokens;
}

/**
 * Helper: Clean up invalid or unregistered FCM tokens
 */
async function cleanupInvalidTokens(uid, tokens, response) {
  if (!response || !response.responses) return;

  const tokensToRemove = [];
  response.responses.forEach((result, index) => {
    if (!result.success) {
      const errCode = result.error ? result.error.code : "";
      if (
        errCode === "messaging/invalid-registration-token" ||
        errCode === "messaging/registration-token-not-registered"
      ) {
        tokensToRemove.push(tokens[index]);
      }
    }
  });

  if (tokensToRemove.length > 0) {
    try {
      await admin
        .firestore()
        .collection("users")
        .doc(uid)
        .update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
        });
    } catch (err) {
      console.error("Error removing stale token:", err);
    }
  }
}

