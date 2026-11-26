import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../supabase_config.dart';

class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  String getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
    required UserModel otherUser,
    String? mediaUrl,
  }) async {
    final myUid = currentUserId;
    if (myUid == null || text.trim().isEmpty) return;

    await SupabaseConfig.client.from('messages').insert({
      'bond_id': chatId,
      'sender_uid': myUid,
      'text': text.trim(),
      'media_url': mediaUrl,
    });
    SupabaseConfig.notifyRefresh();
  }

  Stream<List<Map<String, dynamic>>> getUserChatsStream() {
    final myUid = currentUserId;
    if (myUid == null) return const Stream.empty();

    return SupabaseConfig.watchQuery(
      () async {
        final res = await SupabaseConfig.client.rpc(
          'get_user_chats',
          params: {'p_uid': myUid},
        );
        final list = (res as List<dynamic>? ?? const []);
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      },
      tables: const ['messages', 'bonds', 'bond_confirmations'],
      channelPrefix: 'user_chats_$myUid',
    );
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return SupabaseConfig.watchQuery(
      () async {
        final res = await SupabaseConfig.client.rpc(
          'get_bond_messages',
          params: {'p_bond_id': chatId},
        );
        final list = (res as List<dynamic>? ?? const []);
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      },
      tables: const ['messages', 'bonds'],
      channelPrefix: 'chat_messages_$chatId',
    );
  }
}
