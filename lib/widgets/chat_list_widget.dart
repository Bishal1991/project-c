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
  String? _sendingBondUid;

  static const _bg = Color(0xFF110E20);
  static const _cardBg = Color(0xFF1B162E);
  static const _cardBorder = Color(0xFF2E2846);
  static const _purple = Color(0xFF7B5CFA);
  static const _mutedCircle = Color(0xFF332E47);
  static const _mutedText = Color(0xFF9C96B3);
  static const _requestAmber = Color(0xFFF0A262);
  static const _requestBg = Color(0xFF382218);

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

  String _stageLabel(int stage, {required bool isIncomingRequest}) {
    if (stage <= 0) {
      return isIncomingRequest ? 'Bond Request' : 'Request Sent';
    }
    final idx = (stage - 1).clamp(0, BondModel.stageNames.length - 1);
    return BondModel.stageNames[idx];
  }

  // Case 2: Search user by ID (@username), phone number, or name
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
      final results = await _bondService.searchUsersForBonding(query);
      if (mounted) setState(() => _searchResults = results);
    } catch (e) {
      debugPrint('Search failed: $e');
    }
  }

  Future<void> _handleSendBondFromSearch(UserModel user) async {
    setState(() => _sendingBondUid = user.uid);
    try {
      final res = await _bondService.sendBondRequest(
        targetUid: user.uid,
        matchReason: 'Connected via Miteri ID search (${user.handle})',
      );
      if (!mounted) return;
      final chatId =
          res['bondId'] as String? ??
          _chatService.getChatId(_chatService.currentUserId ?? '', user.uid);

      _searchController.clear();
      _searchUsers('');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatConversationPage(otherUser: user, chatId: chatId),
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingBondUid = null);
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

            // Case 2 Search Bar: Search any user by ID (@username), phone, or name to bond or chat
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: TextField(
                controller: _searchController,
                onChanged: _searchUsers,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: _purple,
                decoration: InputDecoration(
                  hintText: 'Search by @username, phone ID, or name to bond...',
                  hintStyle: const TextStyle(color: _mutedText, fontSize: 14.5),
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
                          'No user found with that ID or phone number',
                          style: TextStyle(color: _mutedText, fontSize: 15),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final bondStage = user.bondStage;
                          final isSending = _sendingBondUid == user.uid;
                          final subtitle = [
                            user.handle,
                            if (user.culturalLabel.isNotEmpty)
                              user.culturalLabel,
                          ].join(' · ');

                          return Container(
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
                                      const SizedBox(height: 3),
                                      Text(
                                        subtitle,
                                        style: const TextStyle(
                                          color: _mutedText,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (bondStage == null)
                                  ElevatedButton.icon(
                                    onPressed: isSending
                                        ? null
                                        : () => _handleSendBondFromSearch(user),
                                    icon: isSending
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.favorite_border_rounded,
                                            size: 16,
                                          ),
                                    label: const Text('Bond'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _purple,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  )
                                else
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ChatConversationPage(
                                                otherUser: user,
                                                chatId: user.bondId,
                                              ),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: bondStage == 0
                                          ? _requestAmber
                                          : const Color(0xFFBBA8FF),
                                      side: BorderSide(
                                        color: bondStage == 0
                                            ? _requestAmber
                                            : _purple,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      bondStage == 0
                                          ? 'Pending'
                                          : _stageLabel(
                                              bondStage,
                                              isIncomingRequest: false,
                                            ),
                                    ),
                                  ),
                              ],
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
                                  'No chats or bond requests yet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Swipe right on Discover or search a friend\'s @username above to send an automated bond request.',
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
                        final stage = (chatData['stage'] as num?)?.toInt() ?? 0;
                        final initiatorUid =
                            chatData['initiatorUid'] as String? ?? '';
                        final isPending = stage == 0;
                        final isIncomingRequest =
                            isPending && initiatorUid != myUid;
                        final datePassed =
                            (chatData['upcomingEventDatePassed'] as bool?) ??
                            false;
                        final eventTitle =
                            chatData['upcomingEventTitle'] as String?;

                        final lastMessage =
                            chatData['lastMessage'] as String? ?? '';
                        final lastSenderId =
                            chatData['lastSenderId'] as String? ?? '';
                        final lastTime = _formatChatTime(
                          chatData['lastMessageTime'],
                        );
                        final hasUnreadFromPartner =
                            isIncomingRequest ||
                            (lastMessage.isNotEmpty &&
                                lastSenderId.isNotEmpty &&
                                lastSenderId != myUid);

                        final otherUser = UserModel(
                          uid: chatData['otherUid'] as String? ?? '',
                          displayName:
                              chatData['otherName'] as String? ?? 'User',
                          username: chatData['otherUsername'] as String?,
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
                                color: isIncomingRequest
                                    ? _requestAmber
                                    : (hasUnreadFromPartner
                                          ? _purple.withValues(alpha: 0.65)
                                          : _cardBorder),
                                width: isIncomingRequest ? 1.5 : 1.2,
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
                                          // Stage or Request Badge: Chinari is ONLY shown when stage >= 1!
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 9,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isPending
                                                  ? _requestBg
                                                  : (stage >= 2
                                                        ? _purple.withValues(
                                                            alpha: 0.22,
                                                          )
                                                        : _mutedCircle),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (stage >= 1) ...[
                                                  Icon(
                                                    stage >= 3
                                                        ? Icons.auto_awesome
                                                        : (stage == 2
                                                              ? Icons
                                                                    .handshake_outlined
                                                              : Icons
                                                                    .verified_outlined),
                                                    size: 12,
                                                    color: stage >= 2
                                                        ? const Color(
                                                            0xFFBBA8FF,
                                                          )
                                                        : Colors.white70,
                                                  ),
                                                  const SizedBox(width: 4),
                                                ],
                                                Text(
                                                  _stageLabel(
                                                    stage,
                                                    isIncomingRequest:
                                                        isIncomingRequest,
                                                  ),
                                                  style: TextStyle(
                                                    color: isPending
                                                        ? _requestAmber
                                                        : (stage >= 2
                                                              ? const Color(
                                                                  0xFFBBA8FF,
                                                                )
                                                              : Colors.white),
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
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
                                          '${otherUser.handle} · $regionOrCulture',
                                          style: const TextStyle(
                                            color: _mutedText,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      if (datePassed &&
                                          eventTitle != null &&
                                          stage == 1)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _requestBg,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'Did you meet at $eventTitle? Tap to confirm →',
                                            style: const TextStyle(
                                              color: _requestAmber,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              isIncomingRequest
                                                  ? 'Tap to accept & send automated greeting'
                                                  : (lastMessage.isNotEmpty
                                                        ? lastMessage
                                                        : 'Tap to open chat'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isIncomingRequest
                                                    ? _requestAmber
                                                    : (hasUnreadFromPartner
                                                          ? Colors.white
                                                          : _mutedText),
                                                fontSize: 14,
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
                                              decoration: BoxDecoration(
                                                color: isIncomingRequest
                                                    ? _requestAmber
                                                    : _purple,
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
