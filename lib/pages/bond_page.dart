import 'package:flutter/material.dart';
import '../models/bond_model.dart';
import '../models/user_model.dart';
import '../services/bond_service.dart';
import 'chat_conversation_page.dart';

class BondPage extends StatefulWidget {
  const BondPage({super.key});

  @override
  State<BondPage> createState() => _BondPageState();
}

class _BondPageState extends State<BondPage> {
  final _bondService = BondService();
  bool _stagesMeaningExpanded = false;

  static const _bg = Color(0xFF110E20);
  static const _cardBg = Color(0xFF1B162E);
  static const _cardBorder = Color(0xFF2E2846);
  static const _purple = Color(0xFF7B5CFA);
  static const _mutedCircle = Color(0xFF332E47);
  static const _mutedText = Color(0xFF9C96B3);
  static const _eventBg = Color(0xFF382218);
  static const _eventAccent = Color(0xFFF0A262);
  static const _eventBody = Color(0xFFE0B495);

  Future<void> _showAddBondSheet() async {
    final users = await _bondService.getDiscoverableUsers();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        if (users.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'You have already sent bond requests to all discoverable users.',
              style: TextStyle(color: Colors.white, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          );
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send a bond request',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sends your automated greeting in Chat. Once they accept with their automated message, you both obtain Chinari!',
                  style: TextStyle(color: _mutedText, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: users.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: _cardBorder, height: 1),
                    itemBuilder: (_, i) {
                      final u = users[i];
                      final subtitle = u.region?.isNotEmpty == true
                          ? '${u.handle} · ${u.region!}'
                          : '${u.handle} · ${u.culturalLabel}';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _BondAvatar(user: u, radius: 22),
                        title: Text(
                          u.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          subtitle,
                          style: const TextStyle(
                            color: _mutedText,
                            fontSize: 12.5,
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final res = await _bondService.sendBondRequest(
                              targetUid: u.uid,
                            );
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatConversationPage(
                                  otherUser: u,
                                  chatId: res['bondId'] as String?,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Send Request'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _bondService.currentUserId ?? '';

    return Container(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: StreamBuilder<List<BondModel>>(
          stream: _bondService.getBondsStream(),
          builder: (context, snapshot) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your bonds',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    IconButton(
                      onPressed: _showAddBondSheet,
                      tooltip: 'Send bond request',
                      icon: const Icon(
                        Icons.person_add_alt_1_outlined,
                        color: _mutedText,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Dynamic "What do the stages mean?" accordion
                InkWell(
                  onTap: () => setState(
                    () => _stagesMeaningExpanded = !_stagesMeaningExpanded,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'What do the stages mean?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(
                          _stagesMeaningExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: _mutedText,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_stagesMeaningExpanded)
                  StreamBuilder<List<BondStageInfo>>(
                    stream: _bondService.getBondStagesStream(),
                    builder: (context, stageSnap) {
                      final stages = stageSnap.data ?? const [];
                      return Container(
                        margin: const EdgeInsets.only(top: 6, bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _cardBorder),
                        ),
                        child: stages.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    color: _purple,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (int i = 0; i < stages.length; i++) ...[
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            color: _purple,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${stages[i].stage}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${stages[i].name} · ${stages[i].subtitle}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                stages[i].description,
                                                style: const TextStyle(
                                                  color: _mutedText,
                                                  fontSize: 13.5,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (i < stages.length - 1)
                                      const SizedBox(height: 14),
                                  ],
                                ],
                              ),
                      );
                    },
                  ),

                const SizedBox(height: 12),

                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error loading bonds: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(
                      child: CircularProgressIndicator(color: _purple),
                    ),
                  )
                else if ((snapshot.data ?? []).isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          size: 48,
                          color: _mutedText,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No Chinari bonds yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Send a bond request on Discover or Chat. Once your friend replies with their automated message, you will obtain Chinari!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _mutedText, fontSize: 14),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _showAddBondSheet,
                          icon: const Icon(Icons.add),
                          label: const Text('Send a bond request'),
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
                  )
                else
                  for (int i = 0; i < snapshot.data!.length; i++) ...[
                    _BondCard(
                      bond: snapshot.data![i],
                      myUid: myUid,
                      bondService: _bondService,
                    ),
                    if (i < snapshot.data!.length - 1)
                      const SizedBox(height: 18),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BondAvatar extends StatelessWidget {
  final UserModel user;
  final double radius;

  const _BondAvatar({required this.user, this.radius = 27});

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

  @override
  Widget build(BuildContext context) {
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
}

class _BondCard extends StatefulWidget {
  final BondModel bond;
  final String myUid;
  final BondService bondService;

  const _BondCard({
    required this.bond,
    required this.myUid,
    required this.bondService,
  });

  @override
  State<_BondCard> createState() => _BondCardState();
}

class _BondCardState extends State<_BondCard> {
  bool _historyExpanded = false;
  bool _confirming = false;

  Future<void> _handleVerifyMeetup(
    bool didMeet, {
    String? userUidOverride,
  }) async {
    setState(() => _confirming = true);
    try {
      await widget.bondService.verifyFestivalMeetup(
        bondId: widget.bond.bondId,
        didMeet: didMeet,
        userUidOverride: userUidOverride,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update meetup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _handleConfirmMit({String? userUidOverride}) async {
    setState(() => _confirming = true);
    try {
      await widget.bondService.confirmStageAdvance(
        widget.bond,
        userUidOverride: userUidOverride,
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _showFestivalPickerSheet() async {
    final festivals = await widget.bondService.getFestivals();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _BondPageState._cardBg,
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
                'Invite ${widget.bond.partner.displayName} to a festival',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: festivals.length,
                  itemBuilder: (_, i) {
                    final f = festivals[i];
                    final isSelected =
                        widget.bond.upcomingFestivalId == f.id ||
                        widget.bond.upcomingEventTitle == f.name;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today_outlined,
                        color: _BondPageState._eventAccent,
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
                        style: const TextStyle(
                          color: _BondPageState._mutedText,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: _BondPageState._purple,
                            )
                          : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await widget.bondService.inviteToFestival(
                          bondId: widget.bond.bondId,
                          festivalId: f.id,
                        );
                      },
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

  void _showMoreActionsSheet() {
    final bond = widget.bond;
    final other = bond.partner;

    showModalBottomSheet(
      context: context,
      backgroundColor: _BondPageState._cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.calendar_month_outlined,
                  color: _BondPageState._eventAccent,
                ),
                title: Text(
                  bond.upcomingEventTitle == null
                      ? 'Invite to an upcoming festival'
                      : 'Change festival (${bond.upcomingEventTitle})',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showFestivalPickerSheet();
                },
              ),
              if (bond.upcomingEventTitle != null &&
                  !bond.upcomingEventDatePassed)
                ListTile(
                  leading: const Icon(
                    Icons.fast_forward_rounded,
                    color: _BondPageState._purple,
                  ),
                  title: Text(
                    'Mark ${bond.upcomingEventTitle} date as passed (test meetup check)',
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.bondService.markFestivalDatePassed(bond.bondId);
                  },
                ),
              ListTile(
                leading: const Icon(
                  Icons.heart_broken_outlined,
                  color: Colors.redAccent,
                ),
                title: Text(
                  'End bond with ${other.displayName}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await widget.bondService.deleteBond(bond.bondId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bond = widget.bond;
    final other = bond.otherUser(widget.myUid);
    final subtitle = (other.region != null && other.region!.trim().isNotEmpty)
        ? other.region!
        : other.culturalLabel;
    final hasEvent =
        bond.upcomingEventTitle != null &&
        bond.upcomingEventTitle!.trim().isNotEmpty;
    final alreadyConfirmed = bond.stageConfirmations.contains(widget.myUid);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _BondPageState._cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _BondPageState._cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Avatar + Name + Region + Three-dots action button
          Row(
            children: [
              _BondAvatar(user: other, radius: 27),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      other.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _BondPageState._mutedText,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: _showMoreActionsSheet,
                icon: const Icon(
                  Icons.more_horiz,
                  color: _BondPageState._mutedText,
                  size: 24,
                ),
                tooltip: 'Bond options',
              ),
            ],
          ),

          const SizedBox(height: 22),

          // 3-step Mit Journey Stepper: 1 Chinari -> 2 Saathi -> 3 Mit
          _MitJourneyStepper(currentStage: bond.stage),

          const SizedBox(height: 20),

          // Live stats line
          Text(
            '${bond.daysBonded} ${bond.daysBonded == 1 ? 'day' : 'days'}'
            ' · met ${bond.festivalsShared} ${bond.festivalsShared == 1 ? 'time' : 'times'}'
            ' · ${bond.messageCount} ${bond.messageCount == 1 ? 'message' : 'messages'}',
            style: const TextStyle(
              color: _BondPageState._mutedText,
              fontSize: 15,
            ),
          ),

          // Upcoming cultural event & Post-Festival Meetup Verification ("Did you meet?")
          if (hasEvent) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _BondPageState._eventBg,
                borderRadius: BorderRadius.circular(16),
                border: bond.upcomingEventDatePassed
                    ? Border.all(
                        color: _BondPageState._eventAccent,
                        width: 1.3,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.calendar_today_outlined,
                          color: _BondPageState._eventAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bond.upcomingEventDate != null &&
                                      bond.upcomingEventDate!.isNotEmpty
                                  ? '${bond.upcomingEventTitle} · ${bond.upcomingEventDate}'
                                  : bond.upcomingEventTitle!,
                              style: const TextStyle(
                                color: _BondPageState._eventAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              bond.upcomingEventDatePassed && bond.stage == 1
                                  ? (alreadyConfirmed
                                        ? '✓ You confirmed that you met. Waiting for ${other.displayName} to confirm to become Saathi & unlock Mit.'
                                        : 'Festival date passed! Did you meet ${other.displayName} at ${bond.upcomingEventTitle}?')
                                  : (bond.upcomingEventNote ??
                                        'After you meet, you both confirm it. Mit is a choice for later.'),
                              style: const TextStyle(
                                color: _BondPageState._eventBody,
                                fontSize: 14.5,
                                height: 1.38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (bond.stage == 1 && !bond.upcomingEventDatePassed) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => widget.bondService
                            .markFestivalDatePassed(bond.bondId),
                        icon: const Icon(Icons.fast_forward_rounded, size: 16),
                        label: const Text('Festival date passed → Verify'),
                        style: TextButton.styleFrom(
                          foregroundColor: _BondPageState._eventAccent,
                        ),
                      ),
                    ),
                  ],
                  if (bond.stage == 1 &&
                      bond.upcomingEventDatePassed &&
                      !alreadyConfirmed) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _confirming
                                ? null
                                : () => _handleVerifyMeetup(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _BondPageState._eventBody,
                              side: const BorderSide(
                                color: _BondPageState._eventAccent,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('No, didn\'t meet'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _confirming
                                ? null
                                : () => _handleVerifyMeetup(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _BondPageState._purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Yes, we met!'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ] else if (bond.stage == 1) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _showFestivalPickerSheet,
              icon: const Icon(
                Icons.celebration_outlined,
                color: _BondPageState._eventAccent,
                size: 18,
              ),
              label: Text(
                'Invite ${other.displayName} to a festival to unlock Saathi & Mit',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _BondPageState._eventAccent,
                side: const BorderSide(color: _BondPageState._cardBorder),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],

          // Stage 2: Saathi achieved & Mit unlocked banner
          if (bond.stage == 2) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _BondPageState._purple.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _BondPageState._purple.withValues(alpha: 0.5),
                ),
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
                          'Mit Stage Unlocked ✨',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      if (!alreadyConfirmed)
                        TextButton(
                          onPressed: _confirming ? null : _handleConfirmMit,
                          style: TextButton.styleFrom(
                            backgroundColor: _BondPageState._purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Unlock Mit',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (alreadyConfirmed) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Waiting for ${other.displayName} to confirm sacred Mit bond.',
                      style: const TextStyle(
                        color: _BondPageState._mutedText,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Collapsible History section
          InkWell(
            onTap: () => setState(() => _historyExpanded = !_historyExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _historyExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _BondPageState._mutedText,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
          if (_historyExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: bond.history.isEmpty
                  ? const Text(
                      'No milestones recorded yet.',
                      style: TextStyle(
                        color: _BondPageState._mutedText,
                        fontSize: 13.5,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: bond.history
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: _BondPageState._purple,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      entry,
                                      style: const TextStyle(
                                        color: _BondPageState._mutedText,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),

          const SizedBox(height: 16),

          // Full-width purple "Open chat" button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatConversationPage(
                      otherUser: other,
                      chatId: bond.bondId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _BondPageState._purple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Open chat',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MitJourneyStepper extends StatelessWidget {
  final int currentStage; // 1 = Chinari, 2 = Saathi, 3 = Mit

  const _MitJourneyStepper({required this.currentStage});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Row(
            children: [
              _buildCircle(1, isReached: currentStage >= 1),
              Expanded(
                child: Container(
                  height: 2,
                  color: currentStage >= 2
                      ? _BondPageState._purple
                      : _BondPageState._cardBorder,
                ),
              ),
              _buildCircle(2, isReached: currentStage >= 2),
              Expanded(
                child: Container(
                  height: 2,
                  color: currentStage >= 3
                      ? _BondPageState._purple
                      : _BondPageState._cardBorder,
                ),
              ),
              _buildCircle(
                3,
                isReached: currentStage >= 3,
                isUnlocked: currentStage >= 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildLabel('Chinari', isReached: currentStage >= 1),
            ),
            Expanded(
              child: _buildLabel('Saathi', isReached: currentStage >= 2),
            ),
            Expanded(
              child: _buildLabel(
                currentStage >= 2 ? 'Mit' : 'Mit 🔒',
                isReached: currentStage >= 3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircle(
    int stepNumber, {
    required bool isReached,
    bool isUnlocked = true,
  }) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isReached
            ? _BondPageState._purple
            : _BondPageState._mutedCircle,
        shape: BoxShape.circle,
        border: (!isReached && isUnlocked && stepNumber == 3)
            ? Border.all(color: _BondPageState._purple, width: 1.5)
            : null,
      ),
      child: Text(
        '$stepNumber',
        style: TextStyle(
          color: isReached ? Colors.white : _BondPageState._mutedText,
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {required bool isReached}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isReached ? Colors.white : _BondPageState._mutedText,
        fontSize: 14,
        fontWeight: isReached ? FontWeight.bold : FontWeight.w500,
      ),
    );
  }
}
