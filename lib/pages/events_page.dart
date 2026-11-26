import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nepali_kit/nepali_kit.dart'
    show Language, NepaliDate, NepaliDateFormat;
import '../models/bond_model.dart';
import '../services/bond_service.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final _bondService = BondService();
  String? _toast;
  Timer? _toastTimer;
  FestivalInvitationModel? _lastDeclined;

  static const _bg = Color(0xFF110E20);
  static const _cardBg = Color(0xFF1B162E);
  static const _cardBorder = Color(0xFF2E2846);
  static const _purple = Color(0xFF7B5CFA);
  static const _mutedText = Color(0xFF9C96B3);
  static const _eventBg = Color(0xFF382218);
  static const _eventAccent = Color(0xFFF0A262);

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() {
      _toast = message;
    });
    _toastTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _toast != null) setState(() => _toast = null);
    });
  }

  void _handleDecline(FestivalInvitationModel inv) async {
    _lastDeclined = inv;
    _showToast('Invitation declined');
    await _bondService.respondFestivalInvitation(inv.id, 'declined');
  }

  void _handleUndoDecline() async {
    final inv = _lastDeclined;
    if (inv == null) return;
    setState(() => _toast = null);
    await _bondService.respondFestivalInvitation(inv.id, 'pending');
    _lastDeclined = null;
  }

  void _handleAccept(FestivalInvitationModel inv) async {
    _showToast('Invitation accepted!');
    await _bondService.respondFestivalInvitation(inv.id, 'accepted');
  }

  String _formatBsDate(String eventDateStr) {
    // Attempt parse or derive sensible month/day for current year
    try {
      final now = DateTime.now();
      // Parse patterns like "15 Dec" or "26 Dec"
      final parts = eventDateStr.trim().split(' ');
      int day = 15;
      int month = 12;
      const monthMap = {
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };

      if (parts.length >= 2) {
        day = int.tryParse(parts[0]) ?? 15;
        final mStr = parts[1].toLowerCase().substring(0, 3);
        month = monthMap[mStr] ?? 12;
      }

      int year = now.year;
      if (month < now.month || (month == now.month && day < now.day)) {
        year += 1;
      }

      final date = DateTime(year, month, day);
      final bs = NepaliDate.fromDateTime(date);
      final bsStr = NepaliDateFormat('MMMM d, yyyy', Language.english).format(
        bs,
      );
      return '$bsStr BS';
    } catch (_) {
      return '';
    }
  }

  Future<void> _showInviteBondSheet(FestivalModel fest) async {
    final bonds = await _bondService.getBondsStream().first;
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        if (bonds.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'No bonds yet. Make a Chinari bond first to invite them to festivals!',
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
                Text(
                  'Invite a friend to ${fest.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: bonds.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: _cardBorder, height: 1),
                    itemBuilder: (_, i) {
                      final b = bonds[i];
                      final other = b.partner;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: _purple.withValues(alpha: 0.3),
                          child: Text(
                            other.displayName.isNotEmpty
                                ? other.displayName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          other.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${b.daysBonded} days bonded · Stage: ${b.currentStageLabel}',
                          style: const TextStyle(color: _mutedText),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _bondService.inviteToFestival(
                              bondId: b.bondId,
                              festivalId: fest.id,
                              note:
                                  'Invited to ${fest.name} together (${fest.eventDate}).',
                            );
                            _showToast(
                              'Invited ${other.displayName} & sent message in Chat!',
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              children: [
                // Header
                const Text(
                  'Events',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 20),

                // Section: Invitations
                StreamBuilder<List<FestivalInvitationModel>>(
                  stream: _bondService.getFestivalInvitationsStream(),
                  builder: (context, invSnap) {
                    final invites = invSnap.data ?? const [];
                    if (invites.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Invitations',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final inv in invites) ...[
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: _purple.withValues(
                                        alpha: 0.3,
                                      ),
                                      child: Text(
                                        inv.hostName.isNotEmpty
                                            ? inv.hostName[0].toUpperCase()
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${inv.festivalName} with ${inv.hostName}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${inv.festivalCommunity} · ${inv.festivalRegion}',
                                            style: const TextStyle(
                                              color: _mutedText,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (inv.festivalDescription != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    inv.festivalDescription!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _eventBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${inv.festivalDate} · ${_formatBsDate(inv.festivalDate)}',
                                    style: const TextStyle(
                                      color: _eventAccent,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _handleDecline(inv),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _mutedText,
                                          side: const BorderSide(
                                            color: _cardBorder,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Decline'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _handleAccept(inv),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _purple,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Accept'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    );
                  },
                ),

                // Section: Upcoming Festivals
                const Text(
                  'Upcoming festivals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                StreamBuilder<List<FestivalModel>>(
                  stream: _bondService.getFestivalsStream(),
                  builder: (context, festSnap) {
                    if (festSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: _purple),
                        ),
                      );
                    }
                    final festivals = festSnap.data ?? const [];

                    return Column(
                      children: [
                        for (final f in festivals) ...[
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _cardBorder),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _eventBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.celebration_outlined,
                                    color: _eventAccent,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        f.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${f.community} · ${f.region}',
                                        style: const TextStyle(
                                          color: _mutedText,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${f.eventDate} · ${_formatBsDate(f.eventDate)}',
                                        style: const TextStyle(
                                          color: _eventAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (f.description != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          f.description!,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                      if (f.etiquetteNotes != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Cultural etiquette: ${f.etiquetteNotes!}',
                                          style: const TextStyle(
                                            color: Color(0xFFC5BFFF),
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _showInviteBondSheet(f),
                                  tooltip: 'Invite a bond',
                                  icon: const Icon(
                                    Icons.send_outlined,
                                    color: _purple,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),

            if (_toast != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _purple,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _toast!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_lastDeclined != null)
                        TextButton(
                          onPressed: _handleUndoDecline,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            'Undo',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
