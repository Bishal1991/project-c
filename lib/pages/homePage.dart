// NewZen Mitjyu · Home (UI only)
// Deck/stack behaviour from Home v2, layout + states from App UI Flow v6.
//
// pubspec.yaml
//   dependencies:
//     flutter_card_swiper: ^7.2.0

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

// ─────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────

class NZRadius {
  static const double r1 = 8, r2 = 12, r3 = 16, r4 = 24;
}

/// Avatar / art tone pair (background, ink) – a1..a6 in the design.
class NZTone {
  const NZTone(this.bg, this.ink);
  final Color bg, ink;
}

@immutable
class NZColors {
  const NZColors({
    required this.bg,
    required this.card,
    required this.ink,
    required this.mute,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.soft,
    required this.softInk,
    required this.danger,
    required this.toastAct,
    required this.tones,
  });

  final Color bg, card, ink, mute, line, primary, onPrimary, soft, softInk;
  final Color danger, toastAct;
  final List<NZTone> tones;

  static const light = NZColors(
    bg: Color(0xFFF6F4FA),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF1B1830),
    mute: Color(0xFF5E5A73),
    line: Color(0xFFE3DFEE),
    primary: Color(0xFF5B35D5),
    onPrimary: Color(0xFFFFFFFF),
    soft: Color(0xFFECE6FB),
    softInk: Color(0xFF3F1FA8),
    danger: Color(0xFFB83257),
    toastAct: Color(0xFFCDBDFF),
    tones: [
      NZTone(Color(0xFFECE6FB), Color(0xFF3F1FA8)), // a1
      NZTone(Color(0xFFFFE9DF), Color(0xFF8A3414)), // a2
      NZTone(Color(0xFFDDF1E6), Color(0xFF14583A)), // a3
      NZTone(Color(0xFFDDEBFA), Color(0xFF17497F)), // a4
      NZTone(Color(0xFFFBF0D0), Color(0xFF6B4A00)), // a5
      NZTone(Color(0xFFFBE1EA), Color(0xFF8A2043)), // a6
    ],
  );

  static const dark = NZColors(
    bg: Color(0xFF121020),
    card: Color(0xFF1C1830),
    ink: Color(0xFFF1EEFA),
    mute: Color(0xFFB1AAC9),
    line: Color(0xFF352F50),
    primary: Color(0xFF7A55F0),
    onPrimary: Color(0xFFFFFFFF),
    soft: Color(0xFF2A2250),
    softInk: Color(0xFFCDBDFF),
    danger: Color(0xFFFF8AA6),
    toastAct: Color(0xFF4A28B8),
    tones: [
      NZTone(Color(0xFF2A2250), Color(0xFFCDBDFF)),
      NZTone(Color(0xFF3A2420), Color(0xFFFFB79A)),
      NZTone(Color(0xFF173A2A), Color(0xFF9BE3C0)),
      NZTone(Color(0xFF17304D), Color(0xFFA9CEF5)),
      NZTone(Color(0xFF3D3214), Color(0xFFF2D58A)),
      NZTone(Color(0xFF40202F), Color(0xFFF5B0C6)),
    ],
  );

  static NZColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  NZTone tone(int n) => tones[(n - 1).clamp(0, tones.length - 1)];
}

class NZText {
  // No fontFamily is set anywhere, so Flutter uses the device's default
  // system font (Roboto on Android, SF on iOS, etc.).

  /// UI text.
  static TextStyle ui(double size,
      {FontWeight weight = FontWeight.w400,
        Color? color,
        double? height,
        double? letterSpacing}) =>
      TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing);

  /// Headings / names (same system font, semi-bold).
  static TextStyle display(double size, {Color? color}) => TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.15,
      letterSpacing: -0.01 * size);
}

const List<BoxShadow> _lift = [
  BoxShadow(
    color: Color.fromRGBO(27, 24, 48, .28),
    blurRadius: 24,
    offset: Offset(0, 8),
    spreadRadius: -8,
  ),
];

/// Theme helper – colours only, fonts stay as the device default.
ThemeData nzTheme(Brightness b) {
  final c = b == Brightness.dark ? NZColors.dark : NZColors.light;
  final base = ThemeData(brightness: b, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: b,
    ).copyWith(primary: c.primary, surface: c.card),
    textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink),
  );
}

// ─────────────────────────────────────────────────────────────
// Model (mock) – replace with your real model
// ─────────────────────────────────────────────────────────────

class Profile {
  const Profile({
    required this.name,
    required this.age,
    required this.region,
    required this.tone,
    required this.reasons,
    required this.chips,
    this.match,
    this.community,
    this.highlight,
  });

  final String name, region;
  final int age;

  /// 1..6 → a1..a6 art colour.
  final int tone;
  final List<String> reasons, chips;

  /// Match percentage shown next to "Why you matched" (null = hidden).
  final int? match;

  /// Soft-purple chip, e.g. "Rai · shared by Sunita".
  final String? community;

  /// Extra soft-purple chip, e.g. "Speaks Nepali & English".
  final String? highlight;

  static const samples = <Profile>[
    Profile(
      name: 'Sunita',
      age: 22,
      region: 'Hill region · Kathmandu',
      tone: 2,
      reasons: [
        'Both love photography',
        'Celebrates Udhauli, a festival new to you',
      ],
      chips: ['Photography', 'Udhauli'],
      match: 79,
      community: 'Rai · shared by Sunita',
    ),
    Profile(
      name: 'Pema',
      age: 24,
      region: 'Kathmandu Valley · Lalitpur',
      tone: 4,
      reasons: ['Both enjoy football'],
      chips: ['Football', 'Hiking'],
      match: 71,
    ),
    Profile(
      name: 'Maya',
      age: 23,
      region: 'Terai · Biratnagar',
      tone: 5,
      reasons: ['Both celebrate Dashain'],
      chips: ['Dashain', 'Cooking'],
      match: 66,
    ),
  ];
}

enum HomeStatus { loading, ready, empty }

/// circles → v2: big Skip / Namaste circles with labels + swipe hint,
///           info (i) button on the card.
/// row     → v6: [ ✕ ] [ Say namaste ] [ ⓘ ] bar.
enum HomeActions { circles, row }

// ─────────────────────────────────────────────────────────────
// Home page
// ─────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.userName = 'Asmita',
    this.themeMode = ThemeMode.dark,
    this.actions = HomeActions.circles,
    this.activeFilters = 2,
    this.status = HomeStatus.ready,
    this.profiles = Profile.samples,
    this.showCoach = false,
    this.eventsBadge = 1,
    this.chatBadge = 1,
    this.onNamaste,
    this.onSkip,
    this.onUndo,
    this.onDetailsTap,
    this.onDiscoverTap,
    this.onInviteBondTap,
    this.onTabTap,
  });

  final String userName;

  /// dark (default, as in the design previews) · light · system
  final ThemeMode themeMode;
  final HomeActions actions;

  /// Number shown on the filter button badge (0 hides it).
  final int activeFilters;

  /// loading → skeleton · ready → deck · empty → "You've met everyone nearby"
  final HomeStatus status;
  final List<Profile> profiles;

  /// First-time "How it works" overlay.
  final bool showCoach;
  final int eventsBadge, chatBadge;

  final ValueChanged<Profile>? onNamaste;
  final ValueChanged<Profile>? onSkip;
  final ValueChanged<Profile>? onUndo;
  final ValueChanged<Profile>? onDetailsTap; // card tap + (i) button
  final VoidCallback? onDiscoverTap; // top-right button + empty-state button
  final VoidCallback? onInviteBondTap;

  /// 0 Home · 1 Bonds · 2 Events · 3 Chat · 4 Me
  final ValueChanged<int>? onTabTap;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CardSwiperController _controller = CardSwiperController();
  Timer? _toastTimer;
  String? _toast;
  int _toastSeq = 0;
  int _index = 0; // front card
  int _swipes = 0; // hint fades after 5
  bool _exhausted = false; // swiped through everyone
  late bool _coach = widget.showCoach;

  bool get _isLoading => widget.status == HomeStatus.loading;
  bool get _showsSwiper =>
      !_isLoading &&
          widget.status == HomeStatus.ready &&
          widget.profiles.isNotEmpty;

  bool get _isEmpty =>
      !_isLoading && (widget.status == HomeStatus.empty ||
          widget.profiles.isEmpty ||
          _exhausted);

  @override
  void dispose() {
    _toastTimer?.cancel();
    _controller.dispose(); // controller is NOT disposed by CardSwiper (>=6.1)
    super.dispose();
  }

  // ── swiper callbacks ──────────────────────────────────────

  bool _onSwipe(int previous, int? current, CardSwiperDirection dir) {
    final p = widget.profiles[previous];
    final namaste = dir == CardSwiperDirection.right;
    HapticFeedback.selectionClick();
    namaste ? widget.onNamaste?.call(p) : widget.onSkip?.call(p);
    setState(() {
      _index = current ?? widget.profiles.length;
      _swipes++;
    });
    _showToast(namaste ? 'Said namaste to ${p.name}' : 'Skipped ${p.name}');
    return true;
  }

  bool _onUndo(int? previous, int current, CardSwiperDirection dir) {
    setState(() {
      _index = current;
      _swipes = math.max(0, _swipes - 1);
      _exhausted = false;
    });
    _hideToast();
    widget.onUndo?.call(widget.profiles[current]);
    return true;
  }

  void _onEnd() => setState(() => _exhausted = true);

  // ── toast ─────────────────────────────────────────────────

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toast = message;
      _toastSeq++;
    });
    _toastTimer = Timer(const Duration(seconds: 4), _hideToast);
  }

  void _hideToast() {
    _toastTimer?.cancel();
    if (mounted && _toast != null) setState(() => _toast = null);
  }

  // ── build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final b = switch (widget.themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
    return Theme(
      data: nzTheme(b),
      child: Builder(builder: _page),
    );
  }

  Widget _page(BuildContext context) {
    final c = NZColors.of(context);
    final empty = _isEmpty;
    final circles = widget.actions == HomeActions.circles;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, circles ? 4 : 12),
                    child: Column(
                      children: [
                        _TopBar(
                          name: widget.userName,
                          enabled: !_isLoading,
                          filters: widget.activeFilters,
                          onTap: widget.onDiscoverTap,
                        ),
                        const SizedBox(height: 12),
                        Expanded(child: _buildDeck()),
                        if (!empty) ...[
                          // the swiper reserves its own 13px for the peeking
                          // back card, so no extra gap while the deck is shown
                          SizedBox(height: _showsSwiper ? 0 : 12),
                          if (circles) ...[
                            _CircleActions(
                              enabled: !_isLoading,
                              onSkip: () =>
                                  _controller.swipe(CardSwiperDirection.left),
                              onNamaste: () =>
                                  _controller.swipe(CardSwiperDirection.right),
                            ),
                            const SizedBox(height: 8),
                            AnimatedOpacity(
                              opacity: _swipes >= 5 ? 0 : 1,
                              duration: const Duration(milliseconds: 400),
                              child: Text(
                                '← Skip · Namaste →',
                                textAlign: TextAlign.center,
                                style: NZText.ui(13, color: c.mute),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ] else ...[
                            _ActionsRow(
                              enabled: !_isLoading,
                              onSkip: () =>
                                  _controller.swipe(CardSwiperDirection.left),
                              onNamaste: () =>
                                  _controller.swipe(CardSwiperDirection.right),
                              onDetails: () => widget.onDetailsTap
                                  ?.call(widget.profiles[_index]),
                            ),
                            const SizedBox(height: 2),
                          ],
                        ],
                      ],
                    ),
                  ),
                  if (_toast != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: circles ? 140 : 72,
                      child: _Toast(
                        key: ValueKey(_toastSeq),
                        message: _toast!,
                        onUndo: _controller.undo,
                      ),
                    ),
                  if (_coach && !_isLoading && !empty)
                    _CoachOverlay(onDismiss: () => setState(() => _coach = false)),
                ],
              ),
            ),
          ),
          _NZTabBar(
            current: 0,
            eventsBadge: widget.eventsBadge,
            chatBadge: widget.chatBadge,
            onTap: widget.onTabTap,
          ),
        ],
      ),
    );
  }

  Widget _buildDeck() {
    if (_isLoading) return const _DeckSkeleton();

    final emptyView = _EmptyState(
      onChangeDiscover: widget.onDiscoverTap,
      onInviteBond: widget.onInviteBondTap,
    );

    if (widget.status == HomeStatus.empty || widget.profiles.isEmpty) {
      return emptyView;
    }

    final count = widget.profiles.length;
    return Stack(
      fit: StackFit.expand,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            // v2: back card = scale(.94) from the centre, sitting so that its
            // bottom edge is 13px below the front card (peeks out underneath).
            const peek = 13.0;
            const scale = 0.94;
            final cardH = math.max(0.0, box.maxHeight - peek);
            final dy = cardH * (1 - scale) / 2 + peek;
            return CardSwiper(
              controller: _controller,
              cardsCount: count,
              numberOfCardsDisplayed: math.min(2, count),
              isLoop: false,
              padding: const EdgeInsets.only(bottom: peek),
              scale: scale,
              backCardOffset: Offset(0, dy),
              threshold: 90, // v2: 90px commit distance
              maxAngle: 20,
              duration: const Duration(milliseconds: 220),
              allowedSwipeDirection:
              const AllowedSwipeDirection.symmetric(horizontal: true),
              onSwipe: _onSwipe,
              onUndo: _onUndo,
              onEnd: _onEnd,
              cardBuilder: (context, index, percentX, percentY) {
                final p = widget.profiles[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onDetailsTap?.call(p),
                  child: _ProfileCard(
                    profile: p,
                    percentX: percentX,
                    onInfo: widget.actions == HomeActions.circles
                        ? () => widget.onDetailsTap?.call(p)
                        : null,
                  ),
                );
              },
            );
          },
        ),
        if (_exhausted) Positioned.fill(child: emptyView),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.name,
    required this.enabled,
    required this.filters,
    this.onTap,
  });
  final String name;
  final int filters;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Namaste, $name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NZText.display(24, color: c.ink),
            ),
          ),
          const SizedBox(width: 12),
          _Press(
            label: filters > 0
                ? 'Filters, $filters active'
                : 'Discover settings',
            onTap: enabled ? onTap : null,
            child: Opacity(
              opacity: enabled ? 1 : .5,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(NZRadius.r2),
                      border: Border.all(color: c.line),
                    ),
                    child: Icon(Icons.filter_list_rounded,
                        size: 20, color: c.ink),
                  ),
                  if (filters > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text('$filters',
                            style: NZText.ui(12,
                                weight: FontWeight.w700,
                                color: c.onPrimary,
                                height: 18 / 12)),
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

// ─────────────────────────────────────────────────────────────
// Profile card (v2 deck style)
// ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.percentX,
    this.onInfo,
  });
  final Profile profile;

  /// v2 on-card (i) button; null hides it.
  final VoidCallback? onInfo;

  /// Horizontal drag as % of the swipe threshold (+ right, − left).
  final int percentX;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    final p = profile;
    final tone = c.tone(p.tone);
    final go = (percentX / 100).clamp(0.0, 1.0).toDouble();
    final skip = (-percentX / 100).clamp(0.0, 1.0).toDouble();

    return Semantics(
      container: true,
      label: '${p.name}, ${p.age}. ${p.region}. Tap for details.',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(NZRadius.r4),
          border: Border.all(color: c.line),
          boxShadow: percentX != 0 ? _lift : null,
        ),
        child: Column(
          children: [
            // art
            Expanded(
              child: Container(
                color: tone.bg,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: Opacity(
                        opacity: .45,
                        child: Text(
                          p.name.characters.first,
                          style: NZText.display(80, color: tone.ink)
                              .copyWith(letterSpacing: 0),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _Stamp(
                        text: 'Namaste',
                        color: c.softInk,
                        border: c.primary,
                        angle: -6,
                        opacity: go,
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _Stamp(
                        text: 'Skip',
                        color: c.mute,
                        border: c.mute,
                        angle: 6,
                        opacity: skip,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _Scrim(profile: p, rightPad: onInfo != null ? 64 : 16),
                    ),
                    if (onInfo != null)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: _Press(
                          label: 'Details for ${p.name}',
                          onTap: onInfo,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: c.card,
                              shape: BoxShape.circle,
                              border: Border.all(color: c.line),
                            ),
                            child: Icon(Icons.info_outline_rounded,
                                size: 20, color: c.ink),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // why you matched
            _WhySection(profile: p),
          ],
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.text,
    required this.color,
    required this.border,
    required this.angle,
    required this.opacity,
  });
  final String text;
  final Color color, border;
  final double angle, opacity;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: angle * math.pi / 180,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(NZRadius.r1),
            border: Border.all(color: border, width: 2),
          ),
          child: Text(
            text,
            style: NZText.ui(14,
                weight: FontWeight.w700, color: color, letterSpacing: .56),
          ),
        ),
      ),
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim({required this.profile, this.rightPad = 16});
  final Profile profile;
  final double rightPad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 48, rightPad, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.fromRGBO(20, 15, 40, .82),
            Color.fromRGBO(20, 15, 40, 0),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: profile.name,
                  style: NZText.display(28, color: Colors.white),
                ),
                TextSpan(
                  text: '  ${profile.age}',
                  style: NZText.ui(18,
                      color: const Color.fromRGBO(255, 255, 255, .85)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            profile.region,
            style: NZText.ui(14, color: const Color.fromRGBO(255, 255, 255, .92)),
          ),
        ],
      ),
    );
  }
}

class _WhySection extends StatelessWidget {
  const _WhySection({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Why you matched',
                  style:
                  NZText.ui(15, weight: FontWeight.w600, color: c.ink)),
              if (profile.match != null)
                _Chip('${profile.match}%', highlighted: true),
            ],
          ),
          const SizedBox(height: 6),
          for (final r in profile.reasons)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 18,
                    child: Text('•',
                        style: NZText.ui(14, color: c.mute, height: 1.45)),
                  ),
                  Expanded(
                    child: Text(r,
                        style: NZText.ui(14, color: c.mute, height: 1.45)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in profile.chips) _Chip(t),
              if (profile.community != null)
                _Chip(profile.community!, highlighted: true),
              if (profile.highlight != null)
                _Chip(profile.highlight!, highlighted: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.highlighted = false});
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted ? c.soft : c.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: highlighted ? c.soft : c.line),
      ),
      child: Text(
        label,
        style: NZText.ui(13,
            weight: highlighted ? FontWeight.w600 : FontWeight.w400,
            color: highlighted ? c.softInk : c.ink,
            height: 1.3),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Actions row (v6): [ ✕ ]  [ Say namaste ]  [ ⓘ ]
// ─────────────────────────────────────────────────────────────

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.enabled,
    required this.onSkip,
    required this.onNamaste,
    required this.onDetails,
  });
  final bool enabled;
  final VoidCallback onSkip, onNamaste, onDetails;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    return Row(
      children: [
        _CircleButton(
          icon: Icons.close_rounded,
          color: c.danger,
          label: 'Skip',
          onTap: enabled ? onSkip : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PrimaryButton(
            label: 'Say namaste',
            onTap: enabled ? onNamaste : null,
          ),
        ),
        const SizedBox(width: 12),
        _CircleButton(
          icon: Icons.info_outline_rounded,
          color: c.ink,
          label: 'Details',
          onTap: enabled ? onDetails : null,
        ),
      ],
    );
  }
}

/// v2: two 64px circles with labels underneath.
class _CircleActions extends StatelessWidget {
  const _CircleActions({
    required this.enabled,
    required this.onSkip,
    required this.onNamaste,
  });
  final bool enabled;
  final VoidCallback onSkip, onNamaste;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);

    Widget item(IconData icon, String label, VoidCallback tap,
        {bool primary = false}) {
      final on = enabled;
      final bg = !on ? c.line : (primary ? c.primary : c.card);
      final fg = !on ? c.mute : (primary ? c.onPrimary : c.ink);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Press(
            label: label,
            onTap: on ? tap : null,
            scale: .94,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bg,
                border: Border.all(
                    color: (primary && on) ? c.primary : c.line),
                boxShadow: on ? _lift : null,
              ),
              child: Icon(icon, size: 28, color: fg),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: NZText.ui(13, weight: FontWeight.w600, color: c.ink)),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        item(Icons.close_rounded, 'Skip', onSkip),
        const SizedBox(width: 56),
        item(Icons.spa_outlined, 'Namaste', onNamaste, primary: true),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    final on = onTap != null;
    return _Press(
      label: label,
      onTap: onTap,
      scale: .94,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? c.card : c.line,
          border: Border.all(color: c.line),
          boxShadow: on ? _lift : null,
        ),
        child: Icon(icon, size: 22, color: on ? color : c.mute),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.onTap, this.height = 52});
  final String label;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    final on = onTap != null;
    return _Press(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: on ? c.primary : c.line,
          borderRadius: BorderRadius.circular(NZRadius.r2),
        ),
        child: Text(
          label,
          style: NZText.ui(15,
              weight: FontWeight.w600, color: on ? c.onPrimary : c.mute),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    return _Press(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        child: Text(label,
            style: NZText.ui(15, weight: FontWeight.w600, color: c.mute)),
      ),
    );
  }
}

/// Tap target with the design's press feedback (scale .97, 120 ms).
class _Press extends StatefulWidget {
  const _Press({
    required this.child,
    this.onTap,
    this.label,
    this.scale = .97,
  });
  final Widget child;
  final VoidCallback? onTap;
  final String? label;
  final double scale;

  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: widget.label != null,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: (_down && !reduce) ? widget.scale : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Loading skeleton
// ─────────────────────────────────────────────────────────────

class _DeckSkeleton extends StatelessWidget {
  const _DeckSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);

    Widget bar({double? h, double? factor, double? w, double radius = NZRadius.r1}) {
      final box = Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          color: c.line,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
      return factor == null
          ? box
          : FractionallySizedBox(
          alignment: Alignment.centerLeft, widthFactor: factor, child: box);
    }

    return Semantics(
      label: 'Loading people',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(NZRadius.r4),
          border: Border.all(color: c.line),
        ),
        child: _Pulse(
          child: Column(
            children: [
              Expanded(child: Container(color: c.line)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(h: 16, factor: .55),
                    const SizedBox(height: 12),
                    bar(h: 12, factor: .90),
                    const SizedBox(height: 8),
                    bar(h: 12, factor: .70),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        bar(h: 32, w: 92, radius: 999),
                        const SizedBox(width: 8),
                        bar(h: 32, w: 72, radius: 999),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _opacity = Tween<double>(begin: 1, end: .55)
      .animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ac.stop();
    } else if (!_ac.isAnimating) {
      _ac.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}

// ─────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onChangeDiscover, this.onInviteBond});
  final VoidCallback? onChangeDiscover, onInviteBond;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: c.soft, shape: BoxShape.circle),
              child: Icon(Icons.person_outline_rounded,
                  size: 32, color: c.softInk),
            ),
            const SizedBox(height: 16),
            Text(
              "You've met everyone nearby",
              textAlign: TextAlign.center,
              style: NZText.display(22, color: c.ink),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 270),
              child: Text(
                'Check back tomorrow, or change your Discover setting to meet more people.',
                textAlign: TextAlign.center,
                style: NZText.ui(15, color: c.mute, height: 1.45),
              ),
            ),
            const SizedBox(height: 20),
            _PrimaryButton(
              label: 'Change Discover setting',
              height: 48,
              onTap: onChangeDiscover,
            ),
            const SizedBox(height: 8),
            _GhostButton(
              label: 'Invite a bond to a festival',
              onTap: onInviteBond,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Toast (with Undo)
// ─────────────────────────────────────────────────────────────

class _Toast extends StatelessWidget {
  const _Toast({super.key, required this.message, required this.onUndo});
  final String message;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: const Cubic(.2, .8, .2, 1),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
      ),
      child: Semantics(
        liveRegion: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          decoration: BoxDecoration(
            color: c.ink,
            borderRadius: BorderRadius.circular(NZRadius.r2),
            boxShadow: _lift,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NZText.ui(14, color: c.bg)),
              ),
              _Press(
                label: 'Undo',
                onTap: onUndo,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  child: Text('Undo',
                      style: NZText.ui(14,
                          weight: FontWeight.w700, color: c.toastAct)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// First-time coach overlay
// ─────────────────────────────────────────────────────────────

class _CoachOverlay extends StatelessWidget {
  const _CoachOverlay({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);

    Widget row(String glyph, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration:
            BoxDecoration(color: c.soft, shape: BoxShape.circle),
            child: Text(glyph,
                style: NZText.ui(18, color: c.softInk),
                semanticsLabel: ''),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: NZText.ui(16, weight: FontWeight.w600, color: c.ink)),
          ),
        ],
      ),
    );

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // absorb taps behind the coach
              child: const ColoredBox(color: Color.fromRGBO(27, 24, 48, .5)),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Semantics(
                scopesRoute: true,
                namesRoute: true,
                label: 'How swiping works',
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(NZRadius.r4),
                    boxShadow: _lift,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How it works',
                          style: NZText.display(20, color: c.ink)),
                      const SizedBox(height: 8),
                      row('←', 'Swipe left to skip'),
                      row('→', 'Swipe right to say namaste'),
                      const SizedBox(height: 6),
                      Text('Tap the card to see more about them.',
                          style: NZText.ui(13, color: c.mute, height: 1.45)),
                      const SizedBox(height: 8),
                      _PrimaryButton(label: 'Got it', height: 48, onTap: onDismiss),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom tab bar
// ─────────────────────────────────────────────────────────────

class _NZTabBar extends StatelessWidget {
  const _NZTabBar({
    required this.current,
    required this.eventsBadge,
    required this.chatBadge,
    this.onTap,
  });
  final int current, eventsBadge, chatBadge;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    final items = <_TabSpec>[
      const _TabSpec('Home', Icons.home_outlined),
      const _TabSpec('Bonds', Icons.favorite_border_rounded),
      _TabSpec('Events', Icons.calendar_today_outlined,
          badge: eventsBadge,
          semantic: eventsBadge > 0
              ? 'Events, $eventsBadge pending invitation'
              : 'Events'),
      _TabSpec('Chat', Icons.chat_bubble_outline_rounded,
          badge: chatBadge,
          semantic: chatBadge > 0 ? 'Chat, $chatBadge unread' : 'Chat'),
      const _TabSpec('Me', Icons.person_outline_rounded),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(4, 8, 4, 10 + bottom),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: _TabItem(
                spec: items[i],
                selected: i == current,
                onTap: onTap == null ? null : () => onTap!(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.label, this.icon, {this.badge = 0, this.semantic});
  final String label;
  final IconData icon;
  final int badge;
  final String? semantic;
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.spec, required this.selected, this.onTap});
  final _TabSpec spec;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    final color = selected ? c.softInk : c.mute;

    return Semantics(
      button: true,
      selected: selected,
      label: spec.semantic ?? spec.label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(spec.icon, size: 22, color: color),
                  const SizedBox(height: 2),
                  Text(
                    spec.label,
                    style: NZText.ui(11,
                        weight: selected ? FontWeight.w700 : FontWeight.w400,
                        color: color),
                  ),
                ],
              ),
              if (spec.badge > 0)
                Positioned(
                  top: -1,
                  child: Transform.translate(
                    offset: const Offset(14, 0),
                    child: Container(
                      constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${spec.badge}',
                        style: NZText.ui(11,
                            weight: FontWeight.w700,
                            color: c.onPrimary,
                            height: 16 / 11),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
