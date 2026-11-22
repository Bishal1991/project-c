import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../pages/chat_conversation_page.dart';
import 'login_page.dart';
import 'searchUserPage.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  final _authService = AuthService();
  final _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    // Ensure currently active user profile is synced to Firestore
    _authService.syncUserProfile();
  }

  String _formatChatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    final now = DateTime.now();

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat('hh:mm a').format(dt);
    } else if (now.difference(dt).inDays < 7) {
      return DateFormat('EEEE').format(dt);
    } else {
      return DateFormat('dd/MM/yy').format(dt);
    }
  }

  void _showProfileDialog() {
    final user = _authService.currentUser;
    final nameController = TextEditingController(text: user?.displayName ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('My Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user?.email ?? "Not set"}'),
            const SizedBox(height: 6),
            Text('Phone: ${user?.phoneNumber ?? "Not set"}'),
            const SizedBox(height: 16),
            const Text('Display Name:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: 'Enter your name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF075E54)),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await _authService.updateDisplayName(newName);
                await _authService.syncUserProfile(displayName: newName);
                if (mounted) setState(() {});
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'eGuff',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search users',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchUserPage()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'profile') {
                _showProfileDialog();
              } else if (value == 'logout') {
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.black54),
                    SizedBox(width: 10),
                    Text('My Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _chatService.getUserChatsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('getUserChatsStream error: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading chats: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            snapshot.data?.docs ?? [],
          );
          docs.sort((a, b) {
            final tA = a.data()['lastMessageTime'] as Timestamp?;
            final tB = b.data()['lastMessageTime'] as Timestamp?;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA);
          });

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_chat_unread_outlined,
                        size: 64,
                        color: Color(0xFF075E54),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No conversations yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the message button below to search friends by email or phone and start chatting like WhatsApp!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
            itemBuilder: (context, index) {
              final chatData = docs[index].data();
              final chatId = docs[index].id;
              final participants = List<String>.from(chatData['participants'] ?? []);
              final details = Map<String, dynamic>.from(chatData['participantDetails'] ?? {});

              // Find other participant's UID
              final otherUid = participants.firstWhere(
                (uid) => uid != myUid,
                orElse: () => '',
              );

              final otherDetails = details[otherUid] is Map
                  ? Map<String, dynamic>.from(details[otherUid])
                  : <String, dynamic>{};

              final otherUser = UserModel.fromMap(otherDetails, otherUid);
              final lastMsg = chatData['lastMessage'] as String? ?? '';
              final lastTime = chatData['lastMessageTime'] as Timestamp?;
              final lastSenderId = chatData['lastSenderId'] as String? ?? '';
              final isMeLast = lastSenderId == myUid;

              final initial = otherUser.displayName.isNotEmpty
                  ? otherUser.displayName[0].toUpperCase()
                  : 'U';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF128C7E),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  otherUser.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Row(
                  children: [
                    if (isMeLast && lastMsg.isNotEmpty) ...[
                      const Icon(
                        Icons.done_all,
                        size: 16,
                        color: Color(0xFF34B7F1),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        lastMsg.isNotEmpty ? lastMsg : 'Tap to chat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: lastMsg.isNotEmpty ? Colors.grey.shade700 : Colors.grey,
                          fontStyle: lastMsg.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  _formatChatTime(lastTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatConversationPage(
                        otherUser: otherUser,
                        chatId: chatId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchUserPage()),
          );
        },
        child: const Icon(Icons.chat),
      ),
    );
  }
}
