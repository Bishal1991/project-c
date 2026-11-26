import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bond_model.dart';
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

  static const _bg = Color(0xFF110E20);
  static const _cardBg = Color(0xFF1B162E);
  static const _cardBorder = Color(0xFF2E2846);
  static const _purple = Color(0xFF7B5CFA);
  static const _mutedCircle = Color(0xFF332E47);
  static const _mutedText = Color(0xFF9C96B3);

  static const _palettes = [
    (Color(0xFF3E281F), Color(0xFFE59A5C)),
    (Color(0xFF173245), Color(0xFF88C0E6)),
    (Color(0xFF2B2444), Color(0xFFB59DFF)),
    (Color(0xFF1F3830), Color(0xFF7DD8B4)),
  ];

  (Color, Color) _pickPalette(String name) {
    if (name.isEmpty) return _palettes[0];
    final upper = name[0].toUpperCase();
    if (upper == 'S') return _palettes[0];
    if (upper == 'P') return _palettes[1];
    return _palettes[name.hashCode.abs() % _palettes.length];
  }

  Widget _buildAvatar(UserModel user, {double radius = 25}) {
    final initial =
        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U';
    final (bg, fg) = _pickPalette(user.displayName);

    if (user.photoUrl != null && user.photoUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        backgroundImage: NetworkImage(user.photoUrl!),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'Georgia',
          color: fg,
          fontSize: radius * 0.82,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatChatTime(dynamic rawTime) {
    if (rawTime == null) return '';
    final dt = rawTime is String ? DateTime.tryParse(rawTime)?.toLocal() : null;
    if (dt == null) return '';
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      return DateFormat('hh:mm a').format(dt);
    }
    return DateFormat('d MMM').format(dt);
  }

  String _stageLabel(int? stage) {
    final idx = ((stage ?? 1) - 1).clamp(0, BondModel.stageNames.length - 1);
    return BondModel.stageNames[idx];
  }

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
    final myUid = _chatService.currentUserId ?? '';

    return Container(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header matching "Your bonds"
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 14),
              child: Text(
                'Chat',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            // Dark-themed Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: TextField(
                controller: _searchController,
                onChanged: _searchUsers,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: _purple,
                decoration: InputDecoration(
                  hintText: 'Search bonded friends...',
                  hintStyle: const TextStyle(color: _mutedText, fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: _mutedText),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: _mutedText),
                          onPressed: () {
                            _searchController.clear();
                            _searchUsers('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: _cardBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _purple, width: 1.5),
                  ),
                ),
              ),
            ),

            if (_isSearching && _searchController.text.isNotEmpty) ...[
              Expanded(
                child: _searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          'No bonded friends match your search',
                          style: TextStyle(color: _mutedText, fontSize: 15),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final subtitle = user.region?.isNotEmpty == true
                              ? user.region!
                              : user.culturalLabel;
                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ChatConversationPage(otherUser: user),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _cardBg,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _cardBorder),
                              ),
                              child: Row(
                                children: [
                                  _buildAvatar(user, radius: 24),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.displayName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            subtitle,
                                            style: const TextStyle(
                                              color: _mutedText,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: _mutedText,
                                  ),
                                ],
                              ),
                            ),
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
                          child: Text(
                            'Error loading chats: ${snapshot.error}',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: _purple),
                      );
                    }

                    final chats = snapshot.data ?? [];
                    if (chats.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: _cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _cardBorder),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 46,
                                  color: _mutedText,
                                ),
                                SizedBox(height: 14),
                                Text(
                                  'No bonded chats yet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Open a chat from Your bonds to start sharing stories and festival plans.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _mutedText,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                      itemCount: chats.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final chatData = chats[index];
                        final chatId = chatData['chatId'] as String? ?? '';
                        final stage = (chatData['stage'] as num?)?.toInt() ?? 1;
                        final lastMessage =
                            chatData['lastMessage'] as String? ?? '';
                        final lastSenderId =
                            chatData['lastSenderId'] as String? ?? '';
                        final lastTime = _formatChatTime(
                          chatData['lastMessageTime'],
                        );
                        final hasUnreadFromPartner =
                            lastMessage.isNotEmpty &&
                            lastSenderId.isNotEmpty &&
                            lastSenderId != myUid;

                        final otherUser = UserModel(
                          uid: chatData['otherUid'] as String? ?? '',
                          displayName:
                              chatData['otherName'] as String? ?? 'User',
                          email: chatData['otherEmail'] as String?,
                          phoneNumber: chatData['otherPhone'] as String?,
                          photoUrl: chatData['otherPhoto'] as String?,
                          community: chatData['otherCommunity'] as String?,
                          region: chatData['otherRegion'] as String?,
                        );

                        final regionOrCulture =
                            (otherUser.region != null &&
                                otherUser.region!.trim().isNotEmpty)
                            ? otherUser.region!
                            : otherUser.culturalLabel;

                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
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
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: hasUnreadFromPartner
                                    ? _purple.withValues(alpha: 0.65)
                                    : _cardBorder,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildAvatar(otherUser, radius: 26),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              otherUser.displayName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: stage >= 2
                                                  ? _purple.withValues(
                                                      alpha: 0.2,
                                                    )
                                                  : _mutedCircle,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              _stageLabel(stage),
                                              style: TextStyle(
                                                color: stage >= 2
                                                    ? const Color(0xFFBBA8FF)
                                                    : _mutedText,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (lastTime.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              lastTime,
                                              style: TextStyle(
                                                color: hasUnreadFromPartner
                                                    ? _purple
                                                    : _mutedText,
                                                fontSize: 12,
                                                fontWeight: hasUnreadFromPartner
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (regionOrCulture.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          regionOrCulture,
                                          style: const TextStyle(
                                            color: _mutedText,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              lastMessage.isNotEmpty
                                                  ? lastMessage
                                                  : 'Tap to say Namaste',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: hasUnreadFromPartner
                                                    ? Colors.white
                                                    : _mutedText,
                                                fontSize: 14.5,
                                                fontWeight: hasUnreadFromPartner
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          if (hasUnreadFromPartner) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 9,
                                              height: 9,
                                              decoration: const BoxDecoration(
                                                color: _purple,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
