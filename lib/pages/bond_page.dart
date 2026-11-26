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
              'You are already bonded with all registered users in Supabase.',
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
                  'Start a new Chinari bond',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
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
                          ? u.region!
                          : u.culturalLabel;
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
                        subtitle: subtitle.isNotEmpty
                            ? Text(
                                subtitle,
                                style: const TextStyle(color: _mutedText),
                              )
                            : null,
                        trailing: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _bondService.createBondWithUser(u);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Bond'),
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
                // Header: "Your bonds" in Georgia serif + Add bond button
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
                      tooltip: 'Add bond from Supabase users',
                      icon: const Icon(
                        Icons.person_add_alt_1_outlined,
                        color: _mutedText,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Dynamic "What do the stages mean?" accordion pulled from Supabase bond_stages
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
                          'No bonds yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Connect with someone across communities to start your Chinari → Saathi → Mit journey.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _mutedText, fontSize: 14),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _showAddBondSheet,
                          icon: const Icon(Icons.add),
                          label: const Text('Find someone to bond'),
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
    (Color(0xFF3E281F), Color(0xFFE59A5C)), // Warm brown + amber
    (Color(0xFF173245), Color(0xFF88C0E6)), // Deep navy + sky blue
    (Color(0xFF2B2444), Color(0xFFB59DFF)), // Deep plum + lavender
    (Color(0xFF1F3830), Color(0xFF7DD8B4)), // Deep forest + mint
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

  Future<void> _handleConfirm() async {
    setState(() => _confirming = true);
    try {
      await widget.bondService.confirmStageAdvance(widget.bond);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not confirm: $e')),
        );
      }
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
                'Plan festival with ${widget.bond.partner.displayName}',
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
                        await widget.bondService.setBondFestival(
                          bondId: widget.bond.bondId,
                          festivalId: f.id,
                        );
                      },
                    );
                  },
                ),
              ),
              if (widget.bond.upcomingEventTitle != null)
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await widget.bondService.setBondFestival(
                      bondId: widget.bond.bondId,
                      festivalId: null,
                    );
                  },
                  child: const Text(
                    'Clear scheduled festival',
                    style: TextStyle(color: Colors.redAccent),
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
    final alreadyConfirmed = bond.stageConfirmations.contains(widget.myUid);

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
                      ? 'Schedule upcoming festival'
                      : 'Change upcoming festival (${bond.upcomingEventTitle})',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showFestivalPickerSheet();
                },
              ),
              if (bond.stage < 3)
                ListTile(
                  leading: const Icon(
                    Icons.verified_outlined,
                    color: _BondPageState._purple,
                  ),
                  title: Text(
                    alreadyConfirmed
                        ? 'Confirmed meeting (waiting for ${other.displayName})'
                        : 'Confirm we met to reach ${bond.nextStageName}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  enabled: !alreadyConfirmed && !_confirming,
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleConfirm();
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

          // Live stats line: "9 days · met 1 time · 32 messages"
          Text(
            '${bond.daysBonded} ${bond.daysBonded == 1 ? 'day' : 'days'}'
            ' · met ${bond.festivalsShared} ${bond.festivalsShared == 1 ? 'time' : 'times'}'
            ' · ${bond.messageCount} ${bond.messageCount == 1 ? 'message' : 'messages'}',
            style: const TextStyle(
              color: _BondPageState._mutedText,
              fontSize: 15,
            ),
          ),

          // Upcoming cultural event box
          if (hasEvent) ...[
            const SizedBox(height: 18),
            InkWell(
              onTap: (bond.stage < 3 && !alreadyConfirmed && !_confirming)
                  ? _handleConfirm
                  : _showFestivalPickerSheet,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _BondPageState._eventBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
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
                            alreadyConfirmed
                                ? 'Confirmed · waiting for ${other.displayName} to confirm.'
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

          // Open chat button
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
                  borderRadius: BorderRadius.circular(16),
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
  final int currentStage; // 1..3

  const _MitJourneyStepper({required this.currentStage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          // Row of circles connected edge-to-edge by lines
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                _circleNode(1),
                Expanded(
                  child: Container(
                    height: 2,
                    color: currentStage >= 2
                        ? _BondPageState._purple
                        : _BondPageState._mutedCircle,
                  ),
                ),
                _circleNode(2),
                Expanded(
                  child: Container(
                    height: 2,
                    color: currentStage >= 3
                        ? _BondPageState._purple
                        : _BondPageState._mutedCircle,
                  ),
                ),
                _circleNode(3),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Labels aligned under each circle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < BondModel.stageNames.length; i++)
                SizedBox(
                  width: 72,
                  child: Text(
                    BondModel.stageNames[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (i + 1) <= currentStage
                          ? Colors.white
                          : _BondPageState._mutedText,
                      fontSize: 14,
                      fontWeight: (i + 1) <= currentStage
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleNode(int step) {
    final active = step <= currentStage;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? _BondPageState._purple : _BondPageState._mutedCircle,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$step',
        style: TextStyle(
          color: active ? Colors.white : _BondPageState._mutedText,
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
