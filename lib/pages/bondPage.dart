// NewZen Mitjyu · Bonds (UI only) – layout, states and colours from App UI Flow v6.
//
// No extra packages. Reuses tokens + shared widgets from home_page.dart
// (NZColors, NZText, NZRadius, nzTheme, nzLift, NZPress, NZTabBar).

import 'package:flutter/material.dart';

import 'homePage.dart';

// ─────────────────────────────────────────────────────────────
// Models (mock) – replace with your real models
// ─────────────────────────────────────────────────────────────

enum NextKind { event, invite }

/// The tinted "what's next" box inside a bond card.
class BondNext {
  const BondNext({required this.kind, required this.title, required this.body});
  final NextKind kind;
  final String title, body;
}

class BondHistory {
  const BondHistory(this.date, this.text);
  final String date, text;
}

class Bond {
  const Bond({
    required this.name,
    required this.sub,
    required this.tone,
    required this.stage,
    required this.stats,
    required this.next,
    required this.history,
  });

  final String name, sub, stats;

  /// 1..6 → avatar colour a1..a6.
  final int tone;

  /// How many stages are reached: 1 Chinari · 2 Saathi · 3 Mit.
  final int stage;
  final BondNext next;
  final List<BondHistory> history;
}

// ─────────────────────────────────────────────────────────────
// Bonds page
// ─────────────────────────────────────────────────────────────

class BondsPage extends StatelessWidget {
  const BondsPage({
    super.key,
    this.themeMode = ThemeMode.dark,
    this.bonds = sampleBonds,
    this.eventsBadge = 1,
    this.chatBadge = 1,
    this.onOpenChat,
    this.onInviteToCelebration,
    this.onOptions,
    this.onGoHome,
    this.onTabTap,
  });

  /// dark (default, as in the design previews) · light · system
  final ThemeMode themeMode;

  /// Empty list → "No bonds yet" state.
  final List<Bond> bonds;
  final int eventsBadge, chatBadge;

  final ValueChanged<Bond>? onOpenChat;
  final ValueChanged<Bond>? onInviteToCelebration;
  final ValueChanged<Bond>? onOptions; // ⋯ button
  final VoidCallback? onGoHome; // empty-state button

  /// 0 Home · 1 Bonds · 2 Events · 3 Chat · 4 Me
  final ValueChanged<int>? onTabTap;

  static const sampleBonds = <Bond>[
    Bond(
      name: 'Sunita',
      sub: 'Hill region',
      tone: 2,
      stage: 2,
      stats: '9 days · met 1 time · 32 messages',
      next: BondNext(
        kind: NextKind.event,
        title: 'Udhauli · 15 Dec',
        body: 'After you meet, you both confirm it. Mit is a choice for later.',
      ),
      history: [
        BondHistory('2 Dec', 'Said namaste, became Chinari'),
        BondHistory('6 Dec', 'Met at a local fair, became Saathi'),
      ],
    ),
    Bond(
      name: 'Pema',
      sub: 'Kathmandu Valley',
      tone: 4,
      stage: 1,
      stats: '2 days · not met yet · 6 messages',
      next: BondNext(
        kind: NextKind.invite,
        title: 'Next: meet in a public place',
        body:
        'Invite Pema to a celebration. You become Saathi once you both confirm you met.',
      ),
      history: [BondHistory('20 Nov', 'Said namaste, became Chinari')],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final b = switch (themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };
    return Theme(data: nzTheme(b), child: Builder(builder: _page));
  }

  Widget _page(BuildContext context) {
    final c = NZColors.of(context);

    final header = Padding(
      padding: EdgeInsets.only(bottom: bonds.isEmpty ? 12 : 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            header: true,
            child: Text('Your bonds', style: NZText.display(24, color: c.ink)),
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: bonds.isEmpty
                  ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    Expanded(child: _EmptyBonds(onGoHome: onGoHome)),
                  ],
                ),
              )
                  : ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                children: [
                  header,
                  const _StagesHelp(),
                  for (final bond in bonds)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BondCard(
                        bond: bond,
                        onOpenChat: () => onOpenChat?.call(bond),
                        onInvite: () => onInviteToCelebration?.call(bond),
                        onOptions: () => onOptions?.call(bond),
                      ),
                    ),
                ],
              ),
            ),
          ),
          NZTabBar(
            current: 1,
            eventsBadge: eventsBadge,
            chatBadge: chatBadge,
            onTap: onTabTap,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// "What do the stages mean?" disclosure
// ─────────────────────────────────────────────────────────────

class _StagesHelp extends StatelessWidget {
  const _StagesHelp();

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);

    Widget p(String bold, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(
              text: bold,
              style: NZText.ui(14, weight: FontWeight.w600, color: c.ink)),
          TextSpan(text: text),
        ]),
        style: NZText.ui(14, color: c.mute, height: 1.45),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _Disclosure(
        title: 'What do the stages mean?',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            p('Chinari', ': someone you both said namaste to.'),
            p('Saathi', ': a friend you have met in person.'),
            p('Mit', ': a lifelong bond you both choose. Always optional.'),
          ],
        ),
      ),
    );
  }
}

/// `details.hist` from the design: 36px summary row + chevron, animated body.
class _Disclosure extends StatefulWidget {
  const _Disclosure({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  State<_Disclosure> createState() => _DisclosureState();
}

class _DisclosureState extends State<_Disclosure> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final d = reduce ? Duration.zero : const Duration(milliseconds: 150);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          label: widget.title,
          excludeSemantics: true,
          onTap: () => setState(() => _open = !_open),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: NZText.ui(14,
                            weight: FontWeight.w600, color: c.ink)),
                  ),
                  AnimatedRotation(
                    turns: _open ? .5 : 0,
                    duration: d,
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: c.mute),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: d,
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
            padding: const EdgeInsets.only(top: 2),
            child: widget.child,
          )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bond card
// ─────────────────────────────────────────────────────────────

class _BondCard extends StatelessWidget {
  const _BondCard({
    required this.bond,
    required this.onOpenChat,
    required this.onInvite,
    required this.onOptions,
  });
  final Bond bond;
  final VoidCallback onOpenChat, onInvite, onOptions;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    final tone = c.tone(bond.tone);
    final isInvite = bond.next.kind == NextKind.invite;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(NZRadius.r3),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // who
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration:
                BoxDecoration(color: tone.bg, shape: BoxShape.circle),
                child: ExcludeSemantics(
                  child: Text(bond.name.characters.first,
                      style: NZText.display(18, color: tone.ink)
                          .copyWith(letterSpacing: 0)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bond.name,
                        style: NZText.ui(17,
                            weight: FontWeight.w700, color: c.ink)),
                    Text(bond.sub, style: NZText.ui(14, color: c.mute)),
                  ],
                ),
              ),
              NZPress(
                label: 'Options for ${bond.name}',
                onTap: onOptions,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.more_horiz_rounded,
                      size: 20, color: c.ink),
                ),
              ),
            ],
          ),

          // stages
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 14),
            child: _Stages(reached: bond.stage),
          ),

          // stats
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(bond.stats, style: NZText.ui(14, color: c.mute)),
          ),

          // next
          _NextBox(next: bond.next),

          // history
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _Disclosure(
              title: 'History',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final h in bond.history)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: h.date,
                              style: NZText.ui(14,
                                  weight: FontWeight.w600, color: c.ink)),
                          TextSpan(text: ' — ${h.text}'),
                        ]),
                        style: NZText.ui(14, color: c.mute),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // actions
          const SizedBox(height: 8),
          if (isInvite) ...[
            _Btn(label: 'Invite to a celebration', onTap: onInvite),
            const SizedBox(height: 8),
            _Btn(label: 'Open chat', onTap: onOpenChat, ghost: true),
          ] else
            _Btn(label: 'Open chat', onTap: onOpenChat),
        ],
      ),
    );
  }
}

/// Chinari — Saathi — Mit progress with connecting lines.
class _Stages extends StatelessWidget {
  const _Stages({required this.reached});
  final int reached;

  static const _labels = ['Chinari', 'Saathi', 'Mit'];

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);

    return Semantics(
      label: 'Stage: ${_labels[(reached - 1).clamp(0, 2)]}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final on = i < reached;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // connector from the previous dot
                      if (i > 0)
                        Positioned(
                          top: 10,
                          left: -box.maxWidth / 2,
                          width: box.maxWidth,
                          height: 2,
                          child: ColoredBox(color: on ? c.primary : c.line),
                        ),
                      // dot
                      Positioned(
                        top: 0,
                        left: box.maxWidth / 2 - 11,
                        child: Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: on ? c.primary : c.line,
                          ),
                          child: Text('${i + 1}',
                              style: NZText.ui(12,
                                  weight: FontWeight.w700,
                                  color: on ? c.onPrimary : c.mute)),
                        ),
                      ),
                      // label
                      Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: SizedBox(
                          width: double.infinity,
                          child: Text(
                            _labels[i],
                            textAlign: TextAlign.center,
                            style: NZText.ui(13,
                                weight: on ? FontWeight.w600 : FontWeight.w400,
                                color: on ? c.ink : c.mute),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NextBox extends StatelessWidget {
  const _NextBox({required this.next});
  final BondNext next;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    final isEvent = next.kind == NextKind.event;
    final bg = isEvent ? c.accentSoft : c.soft;
    final fg = isEvent ? c.accentInk : c.softInk;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(NZRadius.r2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: fg,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(next.title,
                    style: NZText.ui(15, weight: FontWeight.w700, color: fg)),
                Text(next.body, style: NZText.ui(14, color: fg, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.onTap, this.ghost = false});
  final String label;
  final VoidCallback onTap;
  final bool ghost;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    return NZPress(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: ghost ? null : c.primary,
          borderRadius: BorderRadius.circular(NZRadius.r2),
        ),
        child: Text(label,
            style: NZText.ui(15,
                weight: FontWeight.w600,
                color: ghost ? c.mute : c.onPrimary)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────

class _EmptyBonds extends StatelessWidget {
  const _EmptyBonds({this.onGoHome});
  final VoidCallback? onGoHome;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: c.soft, shape: BoxShape.circle),
              child: Icon(Icons.favorite_border_rounded,
                  size: 32, color: c.softInk),
            ),
            const SizedBox(height: 16),
            Text('No bonds yet',
                textAlign: TextAlign.center,
                style: NZText.display(22, color: c.ink)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 270),
              child: Text(
                'Say namaste to someone on Home. When you both say namaste, your bond starts as Chinari.',
                textAlign: TextAlign.center,
                style: NZText.ui(15, color: c.mute, height: 1.45),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: _Btn(label: 'Go to Home', onTap: onGoHome ?? () {}),
            ),
          ],
        ),
      ),
    );
  }
}