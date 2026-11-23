import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  String getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  // Ensure a bond/chat row exists in PostgreSQL between the current user and otherUser
  Future<String> getOrCreateChatRoom(UserModel otherUser) async {
    final myUid = currentUserId;
    if (myUid == null) throw 'Not logged in';

    final chatId = getChatId(myUid, otherUser.uid);
    await ApiClient.post('/bonds', {
      'user1Uid': myUid,
      'user2Uid': otherUser.uid,
      'initiatorUid': myUid,
      'stage': 1,
    });
    return chatId;
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
    required UserModel otherUser,
  }) async {
    final myUid = currentUserId;
    if (myUid == null || text.trim().isEmpty) return;

    await ApiClient.post('/bonds/$chatId/messages', {
      'senderUid': myUid,
      'text': text.trim(),
    });
    ApiClient.notifyRefresh();
  }

  Stream<List<Map<String, dynamic>>> getUserChatsStream() {
    final myUid = currentUserId;
    if (myUid == null) return const Stream.empty();

    return ApiClient.pollStream(() async {
      final list = await ApiClient.get('/users/$myUid/chats') as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return ApiClient.pollStream(() async {
      final list =
          await ApiClient.get('/bonds/$chatId/messages') as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }
}
