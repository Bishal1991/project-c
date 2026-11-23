import 'package:flutter/material.dart';
import '../models/bond_model.dart';
import '../pages/chat_conversation_page.dart';
import '../services/bond_service.dart';

class BondsWidget extends StatelessWidget {
  const BondsWidget({super.key});

  static const _bg = Color(0xFF0F0D1D);
  static const _cardBg = Color(0xFF19162B);
  static const _cardBorder = Color(0xFF2B2742);
  static const _purple = Color(0xFF7C5CFC);
  static const _mutedCircle = Color(0xFF35324A);
  static const _mutedText = Color(0xFF9A96B0);
  static const _eventBg = Color(0xFF35221B);
  static const _eventAccent = Color(0xFFF2A365);
  static const _eventBody = Color(0xFFE5B89B);

  @override
  Widget build(BuildContext context) {
    final bondService = BondService();
    final myUid = bondService.currentUserId ?? '';

    return Container(
      color: _bg,
      child: StreamBuilder<List<BondModel>>(
        stream: bondService.getBondsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading bonds: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _purple),
            );
          }

          final bonds = snapshot.data ?? [];
          if (bonds.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 52, color: _mutedText),
                    SizedBox(height: 16),
                    Text(
                      'No bonds yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Once you bond with someone from Home, your Mit Journey (Chinari → Saathi → Mit) will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _mutedText, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: bonds.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _BondCard(
              bond: bonds[index],
              myUid: myUid,
              bondService: bondService,
            ),
          );
        },
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

  static const _avatarPalettes = [
    (Color(0xFF3A2820), Color(0xFFF2A365)),
    (Color(0xFF1E3547), Color(0xFF8CC4E8)),
    (Color(0xFF2B2444), Color(0xFFB59DFF)),
    (Color(0xFF1F3830), Color(0xFF7DD8B4)),
  ];

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

  @override
  Widget build(BuildContext context) {
    final bond = widget.bond;
    final other = bond.otherUser(widget.myUid);
    final initial =
        other.displayName.isNotEmpty ? other.displayName[0].toUpperCase() : 'U';
    final (avatarBg, avatarFg) =
        _avatarPalettes[other.displayName.hashCode.abs() % _avatarPalettes.length];
    final hasEvent = bond.upcomingEventTitle != null &&
        bond.upcomingEventTitle!.trim().isNotEmpty;
    final alreadyConfirmed = bond.stageConfirmations.contains(widget.myUid);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BondsWidget._cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BondsWidget._cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: avatar + name + community/region
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: avatarBg,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: avatarFg,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      other.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (other.culturalLabel.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        other.culturalLabel,
                        style: const TextStyle(
                          color: BondsWidget._mutedText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // 3-step Mit Journey: Chinari -> Saathi -> Mit
          _MitJourneyStepper(currentStage: bond.stage),

          const SizedBox(height: 18),

          // Closeness stats
          Text(
            '${bond.daysBonded} ${bond.daysBonded == 1 ? 'day' : 'days'}'
            ' · ${bond.festivalsShared} ${bond.festivalsShared == 1 ? 'festival' : 'festivals'} shared'
            ' · ${bond.messageCount} ${bond.messageCount == 1 ? 'message' : 'messages'}',
            style: const TextStyle(
              color: BondsWidget._mutedText,
              fontSize: 14,
            ),
          ),

          // Upcoming cultural event box
          if (hasEvent) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BondsWidget._eventBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      color: BondsWidget._eventAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            color: BondsWidget._eventAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bond.upcomingEventNote ??
                              (bond.nextStageName != null
                                  ? 'You will both confirm you met afterwards to reach ${bond.nextStageName}.'
                                  : 'Upcoming cultural festival together.'),
                          style: const TextStyle(
                            color: BondsWidget._eventBody,
                            fontSize: 13.5,
                            height: 1.35,
                          ),
                        ),
                        if (bond.stage < 3) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed:
                                (alreadyConfirmed || _confirming) ? null : _handleConfirm,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: alreadyConfirmed
                                  ? Colors.white10
                                  : BondsWidget._eventAccent.withValues(alpha: 0.18),
                              foregroundColor: BondsWidget._eventAccent,
                            ),
                            child: Text(
                              alreadyConfirmed
                                  ? 'Confirmed · waiting for ${other.displayName}'
                                  : 'Confirm we met for ${bond.nextStageName}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Collapsible History
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _historyExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: BondsWidget._mutedText,
                  ),
                ],
              ),
            ),
          ),
          if (_historyExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: bond.history.isEmpty
                  ? const Text(
                      'No milestones recorded yet.',
                      style: TextStyle(
                        color: BondsWidget._mutedText,
                        fontSize: 13,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: bond.history
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: BondsWidget._purple,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      entry,
                                      style: const TextStyle(
                                        color: BondsWidget._mutedText,
                                        fontSize: 13,
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

          const SizedBox(height: 14),

          // Open chat button
          SizedBox(
            height: 48,
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
                backgroundColor: BondsWidget._purple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Open chat',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
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
    return Row(
      children: [
        for (int i = 0; i < BondModel.stageNames.length; i++) ...[
          _stepNode(i + 1, BondModel.stageNames[i]),
          if (i < BondModel.stageNames.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Container(
                  height: 2,
                  color: (i + 1) < currentStage
                      ? BondsWidget._purple
                      : BondsWidget._mutedCircle,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _stepNode(int step, String label) {
    final active = step <= currentStage;
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? BondsWidget._purple : BondsWidget._mutedCircle,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$step',
              style: TextStyle(
                color: active ? Colors.white : BondsWidget._mutedText,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : BondsWidget._mutedText,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
