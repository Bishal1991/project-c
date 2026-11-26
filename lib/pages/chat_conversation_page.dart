import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bond_model.dart';
import '../models/user_model.dart';
import '../services/bond_service.dart';
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
  final _bondService = BondService();
  late String _activeChatId;
  bool _actionLoading = false;

  // Dark Miteri theme tokens
  static const _bg = Color(0xFF110E20);
  static const _navBg = Color(0xFF120F21);
  static const _cardBg = Color(0xFF1B162E);
  static const _cardBorder = Color(0xFF2E2846);
  static const _purple = Color(0xFF7B5CFA);
  static const _mutedText = Color(0xFF9C96B3);
  static const _eventBg = Color(0xFF382218);
  static const _eventAccent = Color(0xFFF0A262);
  static const _eventBody = Color(0xFFE0B495);

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
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSend(BondModel? bond) async {
    if (bond != null && bond.stage < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Accept the bond request first to obtain Chinari and unlock chatting.',
          ),
        ),
      );
      return;
    }

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

  // User B accepts User A's bond request by sending their automated message -> Obtains Chinari!
  Future<void> _handleAcceptBondRequest({String? accepterUidOverride}) async {
    setState(() => _actionLoading = true);
    try {
      await _bondService.acceptBondRequest(
        bondId: _activeChatId,
        accepterUidOverride: accepterUidOverride,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 Chinari Bond Obtained! Automated reply sent & chat unlocked.',
            ),
            backgroundColor: _purple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not accept bond request: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _handleDeclineBondRequest() async {
    setState(() => _actionLoading = true);
    try {
      await _bondService.declineBondRequest(_activeChatId);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  // Open festival picker to invite partner to an upcoming festival
  Future<void> _showInviteFestivalSheet(BondModel bond) async {
    if (bond.stage < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obtain Chinari first before inviting to a festival.'),
        ),
      );
      return;
    }

    final festivals = await _bondService.getFestivals();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite ${widget.otherUser.displayName} to a Festival',
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'After the festival date passes, the system will ask both of you if you met. If both agree, you become Saathi and unlock Mit!',
                style: TextStyle(color: _mutedText, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: festivals.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: _cardBorder, height: 1),
                  itemBuilder: (_, i) {
                    final f = festivals[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _eventBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.celebration_outlined,
                          color: _eventAccent,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${f.name} · ${f.eventDate}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${f.community} · ${f.region}',
                        style: const TextStyle(color: _mutedText, fontSize: 13),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _bondService.inviteToFestival(
                            bondId: _activeChatId,
                            festivalId: f.id,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Invite'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerifyMeetup({
    required bool didMeet,
    String? userUidOverride,
  }) async {
    setState(() => _actionLoading = true);
    try {
      final res = await _bondService.verifyFestivalMeetup(
        bondId: _activeChatId,
        didMeet: didMeet,
        userUidOverride: userUidOverride,
      );
      if (!mounted) return;
      final advanced = res['advanced'] == true;
      if (!didMeet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Recorded that you did not meet. You remain at Chinari and Mit stays locked.',
            ),
          ),
        );
      } else if (advanced) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 Both confirmed! You are now Saathi and Mit is unlocked!',
            ),
            backgroundColor: _purple,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _handleAdvanceToMit(
    BondModel bond, {
    String? userUidOverride,
  }) async {
    setState(() => _actionLoading = true);
    try {
      await _bondService.confirmStageAdvance(
        bond,
        userUidOverride: userUidOverride,
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
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

  Widget _buildStageBadge(BondModel? bond) {
    final stage = bond?.stage ?? 0;
    if (stage <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _eventBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Pending Chinari',
          style: TextStyle(
            color: _eventAccent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final label = BondModel.stageNames[(stage - 1).clamp(0, 2)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _purple.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            stage >= 3
                ? Icons.auto_awesome
                : (stage == 2
                      ? Icons.handshake_outlined
                      : Icons.verified_rounded),
            color: const Color(0xFFD6C9FF),
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD6C9FF),
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopWorkflowBanner(BondModel bond, String myUid) {
    // 1. STAGE 0: Pending Bond Request (Before Chinari is obtained!)
    if (bond.stage == 0) {
      final isIncoming = bond.initiatorUid != myUid;
      if (isIncoming) {
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _eventAccent, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.waving_hand_rounded,
                    color: _eventAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.otherUser.displayName} wants to bond with you',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Accepting will send your automated greeting message, grant you both the Chinari sign, and unlock chat.',
                style: TextStyle(
                  color: _mutedText,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _actionLoading
                          ? null
                          : _handleDeclineBondRequest,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _mutedText,
                        side: const BorderSide(color: _cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _actionLoading
                          ? null
                          : () => _handleAcceptBondRequest(),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Accept & Send Greeting'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        // User A sent the request and is waiting for User B to accept with their automated message
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    color: _eventAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Waiting for ${widget.otherUser.displayName} to accept',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Your automated bond request was sent. Once ${widget.otherUser.displayName} accepts by sending their automated greeting, you will both obtain the Chinari sign and unlock free chat.',
                style: const TextStyle(color: _mutedText, fontSize: 12.5),
              ),
            ],
          ),
        );
      }
    }

    // 2. POST-FESTIVAL MEETUP VERIFICATION ("Did you meet?")
    final hasFestival =
        bond.upcomingEventTitle != null &&
        bond.upcomingEventTitle!.trim().isNotEmpty;

    if (bond.stage == 1 && hasFestival && bond.upcomingEventDatePassed) {
      final iConfirmed = bond.stageConfirmations.contains(myUid);
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _eventBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _eventAccent, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.event_available_rounded,
                  color: _eventAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Did you meet at ${bond.upcomingEventTitle} (${bond.upcomingEventDate ?? ''})?',
                    style: const TextStyle(
                      color: _eventAccent,
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              iConfirmed
                  ? '✓ You confirmed that you met! Waiting for ${widget.otherUser.displayName} to confirm so you both become Saathi and unlock Mit.'
                  : 'The festival date has passed. If you both agree that you met in person, you will become Saathi and unlock Mit. If you did not meet, Mit will stay locked.',
              style: const TextStyle(
                color: _eventBody,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            if (!iConfirmed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _actionLoading
                          ? null
                          : () => _handleVerifyMeetup(didMeet: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _eventBody,
                        side: const BorderSide(color: _eventAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('No, didn\'t meet'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _actionLoading
                          ? null
                          : () => _handleVerifyMeetup(didMeet: true),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Yes, we met!'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    // 3. FESTIVAL SCHEDULED (Date hasn't passed yet)
    if (bond.stage == 1 && hasFestival && !bond.upcomingEventDatePassed) {
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _eventBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: _eventAccent,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Planned: ${bond.upcomingEventTitle} (${bond.upcomingEventDate ?? ''})',
                style: const TextStyle(
                  color: _eventAccent,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  _bondService.markFestivalDatePassed(_activeChatId),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _purple.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Date Passed →',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    // 4. STAGE 2 (Saathi achieved -> Mit is unlocked!)
    if (bond.stage == 2) {
      final iConfirmedMit = bond.stageConfirmations.contains(myUid);
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _purple.withValues(alpha: 0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lock_open_rounded,
                  color: Color(0xFFD6C9FF),
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Saathi Bond · "Mit" is Unlocked! ✨',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!iConfirmedMit)
                  ElevatedButton(
                    onPressed: _actionLoading
                        ? null
                        : () => _handleAdvanceToMit(bond),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Become Mit',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (iConfirmedMit) ...[
              const SizedBox(height: 6),
              Text(
                '✓ You chose to become Mit. Waiting for ${widget.otherUser.displayName} to confirm.',
                style: const TextStyle(color: _mutedText, fontSize: 12.5),
              ),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _chatService.currentUserId ?? '';
    final subtitle =
        (widget.otherUser.region != null &&
            widget.otherUser.region!.trim().isNotEmpty)
        ? widget.otherUser.region!
        : (widget.otherUser.culturalLabel.isNotEmpty
              ? widget.otherUser.culturalLabel
              : widget.otherUser.handle);

    return StreamBuilder<BondModel?>(
      stream: _bondService.getSingleBondStream(_activeChatId),
      builder: (context, bondSnap) {
        final bond = bondSnap.data;
        final isChatUnlocked = (bond?.stage ?? 0) >= 1;

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
                _buildAvatar(widget.otherUser, radius: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.otherUser.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStageBadge(bond),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _mutedText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (bond != null && bond.stage >= 1)
                IconButton(
                  onPressed: () => _showInviteFestivalSheet(bond),
                  tooltip: 'Invite to a cultural festival',
                  icon: const Icon(
                    Icons.celebration_outlined,
                    color: _eventAccent,
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Dynamic Workflow Banner (Stage 0 Accept Request / Post-Festival "Did you meet?" / Mit Unlocked)
              if (bond != null) _buildTopWorkflowBanner(bond, myUid),

              // Messages list
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _chatService.getMessagesStream(_activeChatId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
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
                        !snapshot.hasData) {
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
                        final isFestivalCard = text.startsWith('📅');
                        final isMilestoneCard =
                            text.startsWith('🎉') ||
                            text.startsWith('✨') ||
                            text.startsWith('✅');

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.80,
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.only(
                              left: 14,
                              right: 14,
                              top: 10,
                              bottom: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isFestivalCard
                                  ? _eventBg
                                  : (isMilestoneCard
                                        ? const Color(0xFF281F4A)
                                        : (isMe ? _purple : _cardBg)),
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
                              border: isFestivalCard
                                  ? Border.all(color: _eventAccent)
                                  : (isMe
                                        ? null
                                        : Border.all(
                                            color: _cardBorder,
                                            width: 1,
                                          )),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              crossAxisAlignment: WrapCrossAlignment.end,
                              children: [
                                Text(
                                  text,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isFestivalCard
                                        ? _eventAccent
                                        : Colors.white,
                                    fontWeight:
                                        (isFestivalCard || isMilestoneCard)
                                        ? FontWeight.w600
                                        : FontWeight.normal,
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
                                              ? Colors.white.withValues(
                                                  alpha: 0.75,
                                                )
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

              // Composer bar: Locked until Chinari (stage >= 1) is obtained!
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                decoration: const BoxDecoration(
                  color: _navBg,
                  border: Border(
                    top: BorderSide(color: _cardBorder, width: 1),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: !isChatUnlocked
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                color: _eventAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  bond?.initiatorUid == myUid
                                      ? 'Chat unlocks once ${widget.otherUser.displayName} accepts & you obtain Chinari.'
                                      : 'Accept the bond request above to obtain Chinari & start chatting.',
                                  style: const TextStyle(
                                    color: _mutedText,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            // '+' Festival Invite Button right inside Chat
                            IconButton(
                              onPressed: bond == null
                                  ? null
                                  : () => _showInviteFestivalSheet(bond),
                              tooltip: 'Invite to a festival',
                              style: IconButton.styleFrom(
                                backgroundColor: _cardBg,
                                side: const BorderSide(color: _cardBorder),
                              ),
                              icon: const Icon(
                                Icons.celebration_outlined,
                                color: _eventAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _cardBg,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: _cardBorder),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  maxLines: null,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                  cursorColor: _purple,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    hintText: 'Write a message...',
                                    hintStyle: TextStyle(
                                      color: _mutedText,
                                      fontSize: 15,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  onSubmitted: (_) => _handleSend(bond),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _handleSend(bond),
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
      },
    );
  }
}
