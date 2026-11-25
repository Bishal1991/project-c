import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../pages/chat_conversation_page.dart';
import '../services/bond_service.dart';
import '../services/chat_service.dart';

class ChatListWidget extends StatefulWidget {
  const ChatListWidget({super.key});

  @override
  State<ChatListWidget> createState() => _ChatListWidgetState();
}

class _ChatListWidgetState extends State<ChatListWidget> {
  final _chatService = ChatService();
  final _bondService = BondService();
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
      final results = await _bondService.searchBondedUsers(query);
      if (mounted) setState(() => _searchResults = results);
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            onChanged: _searchUsers,
            decoration: InputDecoration(
              hintText: 'Search bonded friends...',
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
                ? const Center(child: Text('No bonded friends match your search'))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : 'U',
                          ),
                        ),
                        title: Text(user.displayName),
                        subtitle: Text(
                          user.culturalLabel.isNotEmpty
                              ? user.culturalLabel
                              : (user.email ?? user.phoneNumber ?? ''),
                        ),
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
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getUserChatsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error loading chats: ${snapshot.error}'),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chats = snapshot.data ?? [];
                if (chats.isEmpty) {
                  return const Center(
                    child: Text(
                      'No bonded chats yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chatData = chats[index];
                    final chatId = chatData['chatId'] as String? ?? '';
                    final lastMessage =
                        chatData['lastMessage'] as String? ?? '';
                    final otherUser = UserModel(
                      uid: chatData['otherUid'] as String? ?? '',
                      displayName: chatData['otherName'] as String? ?? 'User',
                      email: chatData['otherEmail'] as String?,
                      phoneNumber: chatData['otherPhone'] as String?,
                      photoUrl: chatData['otherPhoto'] as String?,
                      community: chatData['otherCommunity'] as String?,
                      region: chatData['otherRegion'] as String?,
                    );

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          otherUser.displayName.isNotEmpty
                              ? otherUser.displayName[0].toUpperCase()
                              : 'U',
                        ),
                      ),
                      title: Text(
                        otherUser.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
          ),
        ],
      ],
    );
  }
}
