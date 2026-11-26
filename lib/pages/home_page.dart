import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/user_model.dart';
import '../services/bond_service.dart';
import 'chat_conversation_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _bondService = BondService();
  final CardSwiperController _controller = CardSwiperController();

  List<UserModel> _users = [];
  bool _isLoading = true;
  bool _exhausted = false;
  String? _toast;
  UserModel? _lastBondedUser;
  Timer? _toastTimer;
  UserModel? _lastSwipedUser;

  static const _bg = Color(0xFF110E20);
  static const _cardBg = Color(0xFF1B162E);
  static const _cardBorder = Color(0xFF2E2846);
  static const _purple = Color(0xFF7B5CFA);
  static const _mutedText = Color(0xFF9C96B3);

  @override
  void initState() {
    super.initState();
    _loadDiscoverableUsers();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDiscoverableUsers() async {
    setState(() => _isLoading = true);
    try {
      final dbUsers = await _bondService.getDiscoverableUsers();
      if (mounted) {
        setState(() {
          _users = dbUsers;
          _isLoading = false;
          _exhausted = dbUsers.isEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error loading discoverable users: $e');
      if (mounted) {
        setState(() {
          _users = [];
          _isLoading = false;
          _exhausted = true;
        });
      }
    }
  }

  void _showToast(String message, {UserModel? bondedUser}) {
    _toastTimer?.cancel();
    setState(() {
      _toast = message;
      _lastBondedUser = bondedUser;
    });
    _toastTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _toast != null) {
        setState(() {
          _toast = null;
          _lastBondedUser = null;
        });
      }
    });
  }

  // Case 1: User A swipes right or clicks the bond icon -> sends automated message in Chat
  bool _onSwipe(int previous, int? current, CardSwiperDirection dir) {
    if (previous >= _users.length) return true;
    final user = _users[previous];
    _lastSwipedUser = user;
    final isBondRequest = dir == CardSwiperDirection.right;

    HapticFeedback.selectionClick();

    if (isBondRequest) {
      _bondService.sendBondRequest(
        targetUid: user.uid,
        matchReason: 'Cross-community interest in culture & traditions',
      );
      _showToast(
        'Automated bond message sent to ${user.displayName} 🙏',
        bondedUser: user,
      );
    } else {
      _bondService.swipeUser(targetUid: user.uid, action: 'pass');
      _showToast('Skipped ${user.displayName}');
    }

    setState(() {
      if (current == null || current >= _users.length) {
        _exhausted = true;
      }
    });

    return true;
  }

  bool _onUndo(int? previous, int current, CardSwiperDirection dir) {
    if (_lastSwipedUser != null) {
      _bondService.undoSwipe(_lastSwipedUser!.uid);
      _lastSwipedUser = null;
    }
    setState(() {
      _exhausted = false;
      _toast = null;
      _lastBondedUser = null;
    });
    return true;
  }

  void _onEnd() {
    setState(() => _exhausted = true);
  }

  // Case 2: User A searches User B's ID (@username / phone / name) and wants to bond
  void _showSearchUserByIdSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SearchByIdSheet(
        bondService: _bondService,
        onBondSent: (user, bondId) {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatConversationPage(
                otherUser: user,
                chatId: bondId,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar with Case 2 Search by ID button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Discover',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _showSearchUserByIdSheet,
                        tooltip: 'Search user by ID or phone',
                        icon: const Icon(
                          Icons.person_search_rounded,
                          color: _purple,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _controller.undo(),
                        tooltip: 'Undo last swipe',
                        icon: const Icon(Icons.undo_rounded, color: _mutedText),
                      ),
                      IconButton(
                        onPressed: _loadDiscoverableUsers,
                        tooltip: 'Refresh discovery deck',
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: _mutedText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Card Swiper Deck
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _purple),
                    )
                  : (_exhausted || _users.isEmpty)
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.all(28),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _cardBorder),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_outlined,
                              size: 48,
                              color: _purple,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'All caught up!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You have explored all discovery cards. You can also search someone directly by their Miteri ID or reset profiles.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _mutedText, fontSize: 14),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _showSearchUserByIdSheet,
                                  icon: const Icon(Icons.search),
                                  label: const Text('Search by ID'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _purple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _loadDiscoverableUsers,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reset Deck'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: _cardBorder),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CardSwiper(
                        controller: _controller,
                        cardsCount: _users.length,
                        numberOfCardsDisplayed: _users.length.clamp(1, 3),
                        backCardOffset: const Offset(0, 16),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 4,
                        ),
                        onSwipe: _onSwipe,
                        onUndo: _onUndo,
                        onEnd: _onEnd,
                        cardBuilder: (context, index, percentX, percentY) {
                          final user = _users[index];
                          return _DiscoveryCard(user: user);
                        },
                      ),
                    ),
            ),

            // Action Buttons: Skip (Left) & Bond / Namaste (Right)
            if (!_isLoading && !_exhausted && _users.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Skip button
                        InkWell(
                          onTap: () =>
                              _controller.swipe(CardSwiperDirection.left),
                          borderRadius: BorderRadius.circular(35),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _cardBorder,
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.redAccent,
                              size: 30,
                            ),
                          ),
                        ),

                        // Case 1: Bond / Namaste button
                        InkWell(
                          onTap: () =>
                              _controller.swipe(CardSwiperDirection.right),
                          borderRadius: BorderRadius.circular(35),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: _purple,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '← Skip · Send Bond Request →',
                      style: TextStyle(color: _mutedText, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // Toast feedback with quick link to open the Chat room where automated message was sent
            if (_toast != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _purple,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _toast!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (_lastBondedUser != null)
                      TextButton(
                        onPressed: () {
                          final target = _lastBondedUser!;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatConversationPage(otherUser: target),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Open Chat →',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchByIdSheet extends StatefulWidget {
  final BondService bondService;
  final void Function(UserModel user, String bondId) onBondSent;

  const _SearchByIdSheet({
    required this.bondService,
    required this.onBondSent,
  });

  @override
  State<_SearchByIdSheet> createState() => _SearchByIdSheetState();
}

class _SearchByIdSheetState extends State<_SearchByIdSheet> {
  final _controller = TextEditingController();
  List<UserModel> _results = [];
  bool _loading = false;
  String? _sendingUid;

  static const _itemBg = Color(0xFF110E20);
  static const _cardBorder = Color(0xFF2E2846);
  static const _purple = Color(0xFF7B5CFA);
  static const _mutedText = Color(0xFF9C96B3);

  @override
  void initState() {
    super.initState();
    _runSearch('a'); // Load initial directory of users
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    final q = query.trim().isEmpty ? 'a' : query.trim();
    setState(() => _loading = true);
    try {
      final list = await widget.bondService.searchUsersForBonding(q);
      if (mounted) setState(() => _results = list);
    } catch (e) {
      debugPrint('Search by ID failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendBond(UserModel user) async {
    setState(() => _sendingUid = user.uid);
    try {
      final res = await widget.bondService.sendBondRequest(
        targetUid: user.uid,
        matchReason: 'Found via Miteri ID search (${user.handle})',
      );
      final bondId =
          res['bondId'] as String? ??
          widget.bondService.getBondId(
            widget.bondService.currentUserId ?? '',
            user.uid,
          );
      widget.onBondSent(user, bondId);
    } finally {
      if (mounted) setState(() => _sendingUid = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Find friend by ID or phone',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: _mutedText),
              ),
            ],
          ),
          const Text(
            'Search by Miteri handle (e.g. @pema.sherpa, @aarav.tharu) or mobile number to send an automated bond request.',
            style: TextStyle(color: _mutedText, fontSize: 13.5),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _runSearch,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: _purple,
            decoration: InputDecoration(
              hintText: 'Enter @username, phone, or name...',
              hintStyle: const TextStyle(color: _mutedText),
              prefixIcon: const Icon(Icons.alternate_email, color: _purple),
              filled: true,
              fillColor: _itemBg,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _purple, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 290,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _purple))
                : _results.isEmpty
                ? const Center(
                    child: Text(
                      'No user found with that ID or phone number.',
                      style: TextStyle(color: _mutedText),
                    ),
                  )
                : ListView.separated(
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final u = _results[index];
                      final stage = u.bondStage;
                      final isSending = _sendingUid == u.uid;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _itemBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _cardBorder),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: _purple.withValues(alpha: 0.25),
                              child: Text(
                                u.displayName.isNotEmpty
                                    ? u.displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${u.handle}${u.culturalLabel.isNotEmpty ? ' · ${u.culturalLabel}' : ''}',
                                    style: const TextStyle(
                                      color: _mutedText,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (stage != null && stage >= 1)
                              OutlinedButton(
                                onPressed: () => widget.onBondSent(
                                  u,
                                  u.bondId ??
                                      widget.bondService.getBondId(
                                        widget.bondService.currentUserId ?? '',
                                        u.uid,
                                      ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFBBA8FF),
                                  side: const BorderSide(color: _purple),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Chat'),
                              )
                            else if (stage == 0)
                              OutlinedButton(
                                onPressed: () => widget.onBondSent(
                                  u,
                                  u.bondId ??
                                      widget.bondService.getBondId(
                                        widget.bondService.currentUserId ?? '',
                                        u.uid,
                                      ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFF0A262),
                                  side: const BorderSide(
                                    color: Color(0xFFF0A262),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Pending'),
                              )
                            else
                              ElevatedButton(
                                onPressed: isSending
                                    ? null
                                    : () => _sendBond(u),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _purple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isSending
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Bond'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  final UserModel user;

  const _DiscoveryCard({required this.user});

  static const _cardBg = Color(0xFF1B162E);
  static const _cardBorder = Color(0xFF2E2846);
  static const _purple = Color(0xFF7B5CFA);
  static const _mutedText = Color(0xFF9C96B3);
  static const _softPurple = Color(0xFF2A2250);
  static const _softInk = Color(0xFFCDBDFF);

  @override
  Widget build(BuildContext context) {
    final name = user.displayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final region = (user.region != null && user.region!.isNotEmpty)
        ? user.region!
        : 'Nepal';
    final community = user.community ?? 'Miteri Community';
    final chips = user.interests.isNotEmpty
        ? user.interests
        : const ['Culture Exchange', 'Festivals', 'Traditions'];

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _cardBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: _purple.withValues(alpha: 0.25),
              child: Text(
                initial,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  color: Color(0xFFCDBDFF),
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Center(
            child: Text(
              user.age != null ? '$name, ${user.age}' : name,
              style: const TextStyle(
                fontFamily: 'Georgia',
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Center(
            child: Text(
              '${user.handle} · $community · $region',
              style: const TextStyle(color: _mutedText, fontSize: 13.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _softPurple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_stories_outlined,
                  color: _softInk,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user.bio != null && user.bio!.isNotEmpty
                        ? user.bio!
                        : 'Promoting Miteri kinship across communities',
                    style: const TextStyle(color: _softInk, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'How bonding works',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _bulletPoint(
            'Swiping right sends your automated bond request in Chat',
          ),
          _bulletPoint(
            'Once they reply with their automated greeting, you both obtain Chinari',
          ),

          const Spacer(),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map(_chip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: _purple, fontSize: 15)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _mutedText, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12.5),
      ),
    );
  }
}
