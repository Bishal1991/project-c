import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';

class ChatConversationPage extends StatefulWidget {
  final UserModel otherUser;
  final String? chatId;

  const ChatConversationPage({
    super.key,
    required this.otherUser,
    this.chatId,
  });

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final _messageController = TextEditingController();
  final _chatService = ChatService();
  late String _activeChatId;
  bool _isInit = false;

  // Dark Miteri theme tokens matching BondPage
  static const _bg = Color(0xFF110E20);
  static const _navBg = Color(0xFF120F21);
  static const _cardBg = Color(0xFF1B162E);
  static const _cardBorder = Color(0xFF2E2846);
  static const _purple = Color(0xFF7B5CFA);
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

  Widget _buildAvatar(UserModel user, {double radius = 20}) {
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

  @override
  void initState() {
    super.initState();
    _activeChatId =
        widget.chatId ??
        _chatService.getChatId(
          _chatService.currentUserId ?? '',
          widget.otherUser.uid,
        );
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      await _chatService.getOrCreateChatRoom(widget.otherUser);
    } catch (e) {
      debugPrint('initChat warning: $e');
    }
    if (mounted) setState(() => _isInit = true);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    try {
      await _chatService.sendMessage(
        chatId: _activeChatId,
        text: text,
        otherUser: widget.otherUser,
      );
    } catch (e) {
      debugPrint('Failed to send message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatTime(dynamic rawTimestamp) {
    if (rawTimestamp == null) return '';
    final dt = rawTimestamp is String
        ? DateTime.tryParse(rawTimestamp)?.toLocal()
        : null;
    if (dt == null) return '';
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _chatService.currentUserId;
    final subtitle =
        (widget.otherUser.region != null &&
            widget.otherUser.region!.trim().isNotEmpty)
        ? widget.otherUser.region!
        : (widget.otherUser.culturalLabel.isNotEmpty
              ? widget.otherUser.culturalLabel
              : (widget.otherUser.phoneNumber ??
                    widget.otherUser.email ??
                    'NewZen Mitjyu bond'));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _navBg,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: _cardBorder, height: 1),
        ),
        title: Row(
          children: [
            _buildAvatar(widget.otherUser, radius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12.5, color: _mutedText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getMessagesStream(_activeChatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('Messages stream error: ${snapshot.error}');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error loading messages: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !_isInit) {
                  return const Center(
                    child: CircularProgressIndicator(color: _purple),
                  );
                }

                final docs = snapshot.data ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: Text(
                        'Say Namaste to ${widget.otherUser.displayName}!',
                        style: const TextStyle(
                          color: _mutedText,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final isMe = data['senderId'] == myUid;
                    final text = data['text'] as String? ?? '';
                    final timestamp = data['timestamp'];

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.only(
                          left: 14,
                          right: 14,
                          top: 10,
                          bottom: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? _purple : _cardBg,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe
                                ? const Radius.circular(16)
                                : const Radius.circular(4),
                            bottomRight: isMe
                                ? const Radius.circular(4)
                                : const Radius.circular(16),
                          ),
                          border: isMe
                              ? null
                              : Border.all(color: _cardBorder, width: 1),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            Text(
                              text,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(timestamp),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isMe
                                          ? Colors.white.withValues(alpha: 0.75)
                                          : _mutedText,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.done_all_rounded,
                                      size: 14,
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ],
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

          // Dark-themed composer bar
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: const BoxDecoration(
              color: _navBg,
              border: Border(top: BorderSide(color: _cardBorder, width: 1)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _cardBorder),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        cursorColor: _purple,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Write a message...',
                          hintStyle: TextStyle(color: _mutedText, fontSize: 15),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _handleSend,
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: const BoxDecoration(
                        color: _purple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
