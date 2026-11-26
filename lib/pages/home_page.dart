import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/user_model.dart';
import '../services/bond_service.dart';

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
  Timer? _toastTimer;
  UserModel? _lastSwipedUser;

  static const _bg = Color(0xFF110E20);
  static const _cardBg = Color(0xFF1B162E);
  static const _cardBorder = Color(0xFF2E2846);
  static const _purple = Color(0xFF7B5CFA);
  static const _mutedText = Color(0xFF9C96B3);

  static const _sampleUsers = [
    (
      'demo_sunita',
      'Sunita',
      'Rai',
      'Hill region · Patan',
      21,
      'Patan Multiple Campus',
      ['Photography', 'Folk Dance', 'Sakela'],
      'Loves documentary photography and celebrating Udhauli with family.',
    ),
    (
      'demo_pema',
      'Pema',
      'Sherpa',
      'Kathmandu Valley · Lalitpur',
      23,
      'Kathmandu University',
      ['Heritage Walks', 'Hiking', 'Language Exchange'],
      'Passionate about Himalayan heritage conservation and cross-community friendships.',
    ),
    (
      'demo_prakash',
      'Prakash',
      'Newar',
      'Valley · Bhaktapur',
      22,
      'PCPS College',
      ['Cooking', 'Heritage Walks', 'Pottery'],
      'Food enthusiast who loves sharing traditional Yomari recipes and cultural walks.',
    ),
  ];

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
          if (dbUsers.isNotEmpty) {
            _users = dbUsers;
          } else {
            // Provide fallback cultural profiles if user has bonded with all registered DB accounts
            _users = _sampleUsers
                .map(
                  (s) => UserModel(
                    uid: s.$1,
                    displayName: s.$2,
                    community: s.$3,
                    region: s.$4,
                    email: '${s.$1}@mitjyu.np',
                  ),
                )
                .toList();
          }
          _isLoading = false;
          _exhausted = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading discoverable users: $e');
      if (mounted) {
        setState(() {
          _users = _sampleUsers
              .map(
                (s) => UserModel(
                  uid: s.$1,
                  displayName: s.$2,
                  community: s.$3,
                  region: s.$4,
                  email: '${s.$1}@mitjyu.np',
                ),
              )
              .toList();
          _isLoading = false;
        });
      }
    }
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() => _toast = message);
    _toastTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _toast != null) setState(() => _toast = null);
    });
  }

  bool _onSwipe(int previous, int? current, CardSwiperDirection dir) {
    if (previous >= _users.length) return true;
    final user = _users[previous];
    _lastSwipedUser = user;
    final isNamaste = dir == CardSwiperDirection.right;

    HapticFeedback.selectionClick();

    if (isNamaste) {
      _bondService.swipeUser(
        targetUid: user.uid,
        action: 'bond',
        matchReason: 'Cross-community interest in culture & traditions',
      );
      _showToast('Said Namaste to ${user.displayName} 🙏');
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
    });
    return true;
  }

  void _onEnd() {
    setState(() => _exhausted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
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
                              'You have swiped through all available profiles. Check back later or reset to see them again.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _mutedText, fontSize: 14),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _loadDiscoverableUsers,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset Profiles'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _purple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
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
                        numberOfCardsDisplayed: 3,
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

            // Action Buttons: Skip (Left) & Namaste (Right)
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

                        // Namaste / Bond button
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
                      '← Skip · Namaste →',
                      style: TextStyle(color: _mutedText, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // Toast feedback
            if (_toast != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _purple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _toast!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
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
          // Avatar area with initials or photo
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: _purple.withValues(alpha: 0.25),
              child: Text(
                initial,
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  color: Color(0xFFCDBDFF),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name and Community
          Center(
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'Georgia',
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '$community · $region',
              style: const TextStyle(color: _mutedText, fontSize: 14.5),
            ),
          ),
          const SizedBox(height: 16),

          // Cultural Bridge Tag
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
                    'Promoting Miteri kinship across communities',
                    style: const TextStyle(color: _softInk, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Why You Matched section
          const Text(
            'Why you matched',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _bulletPoint('Celebrates different cultural festivals from yours'),
          _bulletPoint('Interested in cross-cultural friendship and stories'),

          const Spacer(),

          // Chips / Interests
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Culture Exchange'),
              _chip('Festivals'),
              _chip('Traditions'),
            ],
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
