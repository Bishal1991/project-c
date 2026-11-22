import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  String getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  // Search users by email or phone number
  Future<List<UserModel>> searchUsers(String query) async {
    final myUid = currentUserId;
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final Set<String> foundUids = {};
    final List<UserModel> results = [];

    final snapshot = await _firestore.collection('users').limit(50).get();

    for (var doc in snapshot.docs) {
      if (doc.id == myUid) continue; // Exclude self
      final data = doc.data();
      final user = UserModel.fromMap(data, doc.id);

      final email = (user.email ?? '').toLowerCase();
      final phone = (user.phoneNumber ?? '').replaceAll(' ', '');
      final name = user.displayName.toLowerCase();

      final searchPhone = cleanQuery.replaceAll(' ', '');

      if (email.contains(cleanQuery) ||
          phone.contains(searchPhone) ||
          name.contains(cleanQuery)) {
        if (!foundUids.contains(user.uid)) {
          foundUids.add(user.uid);
          results.add(user);
        }
      }
    }

    return results;
  }

  // Create or get 1-on-1 chat room
  Future<String> getOrCreateChatRoom(UserModel otherUser) async {
    final myUser = _auth.currentUser;
    if (myUser == null) throw 'Not logged in';

    final chatId = getChatId(myUser.uid, otherUser.uid);
    final chatDoc = _firestore.collection('chats').doc(chatId);
    final docSnap = await chatDoc.get();

    final myName = myUser.displayName ??
        myUser.email?.split('@')[0] ??
        myUser.phoneNumber ??
        'User';

    if (!docSnap.exists) {
      await chatDoc.set({
        'chatId': chatId,
        'participants': [myUser.uid, otherUser.uid],
        'participantDetails': {
          myUser.uid: {
            'uid': myUser.uid,
            'displayName': myName,
            'email': myUser.email,
            'phoneNumber': myUser.phoneNumber,
          },
          otherUser.uid: {
            'uid': otherUser.uid,
            'displayName': otherUser.displayName,
            'email': otherUser.email,
            'phoneNumber': otherUser.phoneNumber,
          },
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': '',
      });
    }

    return chatId;
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String text,
    required UserModel otherUser,
  }) async {
    final myUser = _auth.currentUser;
    if (myUser == null || text.trim().isEmpty) return;

    final myName = myUser.displayName ??
        myUser.email?.split('@')[0] ??
        myUser.phoneNumber ??
        'User';

    final messageData = {
      'senderId': myUser.uid,
      'senderName': myName,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    final batch = _firestore.batch();

    // 1. Add message to subcollection
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    batch.set(messageRef, messageData);

    // 2. Update chat metadata with merge: true (never fails if doc is missing)
    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.set(
      chatRef,
      {
        'chatId': chatId,
        'participants': [myUser.uid, otherUser.uid],
        'participantDetails': {
          myUser.uid: {
            'uid': myUser.uid,
            'displayName': myName,
            'email': myUser.email,
            'phoneNumber': myUser.phoneNumber,
          },
          otherUser.uid: {
            'uid': otherUser.uid,
            'displayName': otherUser.displayName,
            'email': otherUser.email,
            'phoneNumber': otherUser.phoneNumber,
          },
        },
        'lastMessage': text.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': myUser.uid,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  // Stream of conversations where current user is a participant (No composite index needed)
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserChatsStream() {
    final myUid = currentUserId;
    if (myUid == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .snapshots();
  }

  // Stream of messages in a chat
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}

