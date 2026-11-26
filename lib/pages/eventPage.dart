// NewZen Mitjyu · Events (UI only) – layout, states and colours from App UI Flow v6.
//
// pubspec.yaml
//   dependencies:
//     nepali_kit: ^1.1.0        # BS (Bikram Sambat) dates + Nepali formatting
//
// Reuses tokens + shared widgets from home_page.dart
// (NZColors, NZText, NZRadius, nzTheme, nzLift, NZPress, NZToast, NZTabBar).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nepali_kit/nepali_kit.dart' show Language, NepaliDate, NepaliDateFormat;

import 'homepage.dart';

// ─────────────────────────────────────────────────────────────
// Models (mock) – replace with your real models
// ─────────────────────────────────────────────────────────────

/// An invitation someone sent you ("Udhauli with Sunita's family").
class EventInvite {
  const EventInvite({
    required this.title,
    required this.tag,
    required this.note,
    required this.date,
  });
  final String title, tag, note;
  final DateTime date; // Gregorian; the BS date is derived by nepali_kit
}

/// A festival in the "Upcoming festivals" list.
class Festival {
  const Festival({required this.name, required this.tag, required this.date});
  final String name, tag;
  final DateTime date;
}

// ─────────────────────────────────────────────────────────────
// Events page
// ─────────────────────────────────────────────────────────────

class EventsPage extends StatefulWidget {
  const EventsPage({
    super.key,
    this.themeMode = ThemeMode.dark,
    this.invitations,
    this.festivals,
    this.showBsDate = true,
    this.bsLanguage = Language.english,
    this.chatBadge = 1,
    this.onAccept,
    this.onDecline,
    this.onUndoDecline,
    this.onInvite,
    this.onTabTap,
  });

  /// dark (default, as in the design previews) · light · system
  final ThemeMode themeMode;

  /// null → sample data · empty list → "No invitations yet" state
  final List<EventInvite>? invitations;

  /// null → sample data
  final List<Festival>? festivals;

  /// Show the Bikram Sambat date (from nepali_kit) under each event.
  final bool showBsDate;

  /// Language.english → "Poush 15, 2083 BS" · Language.nepali → "पौष १५, २०८३ वि.सं."
  final Language bsLanguage;

  final int chatBadge;

  final ValueChanged<EventInvite>? onAccept;
  final ValueChanged<EventInvite>? onDecline;
  final ValueChanged<EventInvite>? onUndoDecline;
  final ValueChanged<Festival>? onInvite;

  /// 0 Home · 1 Bonds · 2 Events · 3 Chat · 4 Me
  final ValueChanged<int>? onTabTap;

  static final List<EventInvite> sampleInvitations = [
    EventInvite(
      title: "Udhauli with Sunita's family",
      tag: 'Hosted ritual · Khotang-style',
      note:
      'Invited into the ceremony itself. Time and place are shared once you accept.',
      date: DateTime(2026, 12, 15),
    ),
  ];

  static final List<Festival> sampleFestivals = [
    Festival(name: 'Tamu Lhosar', tag: 'Gurung community', date: DateTime(2026, 12, 30)),
    Festival(name: 'Maghe Sankranti', tag: 'Varies by region', date: DateTime(2027, 1, 14)),
    Festival(name: 'Nepali New Year', tag: 'Bisket Jatra', date: DateTime(2027, 4, 14)),
  ];

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late List<EventInvite> _invites =
  List.of(widget.invitations ?? EventsPage.sampleInvitations);
  late final bool _startedEmpty = _invites.isEmpty;

  EventInvite? _lastDeclined;
  int _lastDeclinedIndex = 0;
  String? _toast;
  int _toastSeq = 0;
  Timer? _toastTimer;

  List<Festival> get _festivals =>
      widget.festivals ?? EventsPage.sampleFestivals;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  // ── actions ───────────────────────────────────────────────

  void _decline(EventInvite e) {
    final i = _invites.indexOf(e);
    setState(() {
      _lastDeclined = e;
      _lastDeclinedIndex = i < 0 ? 0 : i;
      _invites = List.of(_invites)..remove(e);
      _toast = 'Invitation declined';
      _toastSeq++;
    });
    widget.onDecline?.call(e);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 4), _hideToast);
  }

  void _undoDecline() {
    final e = _lastDeclined;
    if (e == null) return;
    setState(() {
      _invites = List.of(_invites)
        ..insert(_lastDeclinedIndex.clamp(0, _invites.length), e);
      _lastDeclined = null;
      _toast = null;
    });
    _toastTimer?.cancel();
    widget.onUndoDecline?.call(e);
  }

  void _hideToast() {
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
    return Theme(data: nzTheme(b), child: Builder(builder: _page));
  }

  Widget _page(BuildContext context) {
    final c = NZColors.of(context);

    // "No invitations yet" only when the page started without any;
    // after declining the last one the section simply disappears (v6).
    final showEmptyNote = _invites.isEmpty && _startedEmpty;

    final children = <Widget>[
      const _Header(),
      if (_invites.isNotEmpty)
        for (final e in _invites)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _InviteCard(
              invite: e,
              bs: _bsLine(e.date),
              onAccept: () => widget.onAccept?.call(e),
              onDecline: () => _decline(e),
            ),
          ),
      if (showEmptyNote) ...[
        const _SectionLabel('Invitations', first: true),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'No invitations yet. Invite a bond to a festival and it shows up here.',
            style: NZText.ui(13, color: c.mute, height: 1.45),
          ),
        ),
      ],
      _SectionLabel('Upcoming festivals',
          first: _invites.isEmpty && !showEmptyNote),
      for (final f in _festivals)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _FestivalRow(
            festival: f,
            bs: _bsLine(f.date),
            onInvite: () => widget.onInvite?.call(f),
          ),
        ),
    ];

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
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    children: children,
                  ),
                  if (_toast != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: NZToast(
                        key: ValueKey(_toastSeq),
                        message: _toast!,
                        onUndo: _undoDecline,
                      ),
                    ),
                ],
              ),
            ),
          ),
          NZTabBar(
            current: 2,
            eventsBadge: 0, // v6: no badge on the tab you're already on
            chatBadge: widget.chatBadge,
            onTap: widget.onTabTap,
          ),
        ],
      ),
    );
  }

  // ── nepali_kit: Gregorian → Bikram Sambat ─────────────────

  String? _bsLine(DateTime date) {
    if (!widget.showBsDate) return null;
    try {
      final bs = NepaliDate.fromDateTime(date);
      final text = NepaliDateFormat('MMMM d, yyyy', widget.bsLanguage).format(bs);
      return widget.bsLanguage == Language.nepali ? '$text वि.सं.' : '$text BS';
    } catch (_) {
      return null; // outside the supported BS range → just hide the line
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Pieces
// ─────────────────────────────────────────────────────────────

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          header: true,
          child: Text('Events', style: NZText.display(24, color: c.ink)),
        ),
      ),
    ).withBottom(12);
  }
}

extension on Widget {
  Widget withBottom(double v) =>
      Padding(padding: EdgeInsets.only(bottom: v), child: this);
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.first = false});
  final String text;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 20, bottom: 10),
      child: Semantics(
        header: true,
        child: Text(text,
            style: NZText.ui(15, weight: FontWeight.w600, color: c.ink)),
      ),
    );
  }
}

/// Date chip: "Dec / 15".
class _DateChip extends StatelessWidget {
  const _DateChip(this.date);
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 48,
        height: 52,
        decoration: BoxDecoration(
          color: c.soft,
          borderRadius: BorderRadius.circular(NZRadius.r2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_months[date.month - 1],
                style: NZText.ui(12,
                    weight: FontWeight.w600, color: c.softInk, height: 1.1)),
            Text('${date.day}',
                style: NZText.display(20, color: c.softInk)
                    .copyWith(height: 1.1, letterSpacing: 0)),
          ],
        ),
      ),
    );
  }
}

class _Titles extends StatelessWidget {
  const _Titles({required this.title, required this.tag, this.bs});
  final String title, tag;
  final String? bs;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style: NZText.ui(16, weight: FontWeight.w700, color: c.ink, height: 1.25)),
        Text(tag, style: NZText.ui(13, color: c.mute)),
        if (bs != null) Text(bs!, style: NZText.ui(13, color: c.mute)),
      ],
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.bs,
    required this.onAccept,
    required this.onDecline,
  });
  final EventInvite invite;
  final String? bs;
  final VoidCallback onAccept, onDecline;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    return Semantics(
      container: true,
      label: 'Invitation: ${invite.title}',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(NZRadius.r3),
          border: Border.all(color: c.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _DateChip(invite.date),
                const SizedBox(width: 12),
                Expanded(
                  child: _Titles(title: invite.title, tag: invite.tag, bs: bs),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(invite.note,
                style: NZText.ui(13, color: c.mute, height: 1.45)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Btn(label: 'Accept', onTap: onAccept),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Btn(label: 'Decline', onTap: onDecline, line: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FestivalRow extends StatelessWidget {
  const _FestivalRow({
    required this.festival,
    required this.bs,
    required this.onInvite,
  });
  final Festival festival;
  final String? bs;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final c = NZColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(NZRadius.r3),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          _DateChip(festival.date),
          const SizedBox(width: 12),
          Expanded(
            child: _Titles(title: festival.name, tag: festival.tag, bs: bs),
          ),
          const SizedBox(width: 12),
          NZPress(
            label: 'Invite to ${festival.name}',
            onTap: onInvite,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.soft,
                borderRadius: BorderRadius.circular(NZRadius.r2),
              ),
              child: Text('Invite',
                  style: NZText.ui(14, weight: FontWeight.w600, color: c.softInk)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filled (primary) or outlined (`line`) 48px button.
class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.onTap, this.line = false});
  final String label;
  final VoidCallback onTap;
  final bool line;

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
          color: line ? null : c.primary,
          borderRadius: BorderRadius.circular(NZRadius.r2),
          border: line ? Border.all(color: c.line) : null,
        ),
        child: Text(label,
            style: NZText.ui(15,
                weight: FontWeight.w600, color: line ? c.ink : c.onPrimary)),
      ),
    );
  }
}