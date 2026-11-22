import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../pages/chat_conversation_page.dart';

class ChatListWidget extends StatefulWidget {
  const ChatListWidget({super.key});

  @override
  State<ChatListWidget> createState() => _ChatListWidgetState();
}

class _ChatListWidgetState extends State<ChatListWidget> {
  final _chatService = ChatService();
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await _chatService.searchUsers(query);
      setState(() => _searchResults = results);
    } catch (e) {
      debugPrint('Search failed: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _chatService.currentUserId;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            onChanged: _searchUsers,
            decoration: InputDecoration(
              hintText: 'Search user by name or email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchUsers('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
        ),
        if (_isSearching && _searchController.text.isNotEmpty) ...[
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(child: Text('No users found'))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : 'U'),
                        ),
                        title: Text(user.displayName),
                        subtitle: Text(user.email ?? user.phoneNumber ?? ''),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChatConversationPage(otherUser: user),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ] else ...[
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatService.getUserChatsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error loading chats: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No chats yet.\nSearch above to start chatting!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final chatData = docs[index].data();
                    final chatId = chatData['chatId'] as String? ?? '';
                    final lastMessage =
                        chatData['lastMessage'] as String? ?? '';
                    final participantDetails =
                        chatData['participantDetails'] as Map<String, dynamic>? ??
                            {};

                    UserModel? otherUser;
                    participantDetails.forEach((uid, details) {
                      if (uid != myUid && details is Map<String, dynamic>) {
                        otherUser = UserModel.fromMap(details, uid);
                      }
                    });

                    if (otherUser == null) return const SizedBox.shrink();

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(otherUser!.displayName.isNotEmpty
                            ? otherUser!.displayName[0].toUpperCase()
                            : 'U'),
                      ),
                      title: Text(otherUser!.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        lastMessage.isNotEmpty ? lastMessage : 'Tap to chat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatConversationPage(
                              otherUser: otherUser!,
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
          ),
        ],
      ],
    );
  }
}
