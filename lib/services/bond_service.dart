import 'package:firebase_auth/firebase_auth.dart';
import '../models/bond_model.dart';
import '../models/user_model.dart';
import '../supabase_config.dart';

class FestivalInvitationModel {
  final int id;
  final String bondId;
  final int festivalId;
  final String status;
  final String festivalName;
  final String festivalDate;
  final String festivalCommunity;
  final String festivalRegion;
  final String? festivalDescription;
  final String? festivalEtiquette;
  final String hostName;
  final String? hostPhoto;

  const FestivalInvitationModel({
    required this.id,
    required this.bondId,
    required this.festivalId,
    required this.status,
    required this.festivalName,
    required this.festivalDate,
    required this.festivalCommunity,
    required this.festivalRegion,
    this.festivalDescription,
    this.festivalEtiquette,
    required this.hostName,
    this.hostPhoto,
  });

  factory FestivalInvitationModel.fromJson(Map<String, dynamic> json) {
    return FestivalInvitationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bondId: json['bond_id'] as String? ?? '',
      festivalId: (json['festival_id'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      festivalName: json['festival_name'] as String? ?? '',
      festivalDate: json['festival_date'] as String? ?? '',
      festivalCommunity: json['festival_community'] as String? ?? '',
      festivalRegion: json['festival_region'] as String? ?? '',
      festivalDescription: json['festival_description'] as String?,
      festivalEtiquette: json['festival_etiquette'] as String?,
      hostName: json['host_name'] as String? ?? 'User',
      hostPhoto: json['host_photo'] as String?,
    );
  }
}

class BondService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Automated greeting sent by User A when initiating a bond request (Case 1: Swipe/Tap Bond, Case 2: Search ID & Bond)
  static const String defaultInitiatorAutomatedMessage =
      'Namaste! 🙏 I came across your profile and would love to connect across our communities and start a Chinari bond with you.';

  /// Automated acceptance reply sent by User B in Chat to accept the request and obtain the Chinari badge
  static const String defaultAccepterAutomatedMessage =
      'Namaste! 🙏 I am delighted to accept your bond request. Let\'s share our traditions and begin our Chinari journey!';

  String? get currentUserId => _auth.currentUser?.uid;

  String getBondId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Stream<List<BondModel>> getBondsStream() {
    final myUid = currentUserId;
    if (myUid == null) return const Stream.empty();

    return SupabaseConfig.watchQuery(
      () async {
        final res = await SupabaseConfig.client.rpc(
          'get_user_bonds',
          params: {'p_uid': myUid},
        );
        final list = (res as List<dynamic>? ?? const []);
        return list
            .map((item) => BondModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      },
      tables: const [
        'bonds',
        'bond_confirmations',
        'bond_history',
        'messages',
        'festival_invitations',
      ],
      channelPrefix: 'user_bonds_$myUid',
    );
  }

  Stream<BondModel?> getSingleBondStream(String bondId) {
    final myUid = currentUserId;
    if (myUid == null || bondId.isEmpty) return const Stream.empty();

    return SupabaseConfig.watchQuery(
      () async {
        final res = await SupabaseConfig.client.rpc(
          'get_single_bond',
          params: {
            'p_bond_id': bondId,
            'p_uid': myUid,
          },
        );
        if (res is Map && res.isNotEmpty && res['bond_id'] != null) {
          return BondModel.fromJson(Map<String, dynamic>.from(res));
        }
        return null;
      },
      tables: const [
        'bonds',
        'bond_confirmations',
        'bond_history',
        'festival_invitations',
      ],
      channelPrefix: 'single_bond_$bondId',
    );
  }

  Stream<List<BondStageInfo>> getBondStagesStream() {
    return SupabaseConfig.watchQuery(
      () async {
        final res = await SupabaseConfig.client
            .from('bond_stages')
            .select()
            .order('stage', ascending: true);
        return (res as List<dynamic>)
            .map((e) => BondStageInfo.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
      tables: const ['bond_stages'],
      channelPrefix: 'bond_stages',
    );
  }

  Stream<List<FestivalModel>> getFestivalsStream() {
    return SupabaseConfig.watchQuery(
      () async {
        final res = await SupabaseConfig.client
            .from('festivals')
            .select()
            .order('id', ascending: true);
        return (res as List<dynamic>)
            .map((e) => FestivalModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
      tables: const ['festivals'],
      channelPrefix: 'festivals_stream',
    );
  }

  Future<List<FestivalModel>> getFestivals() async {
    final res = await SupabaseConfig.client
        .from('festivals')
        .select()
        .order('id', ascending: true);
    return (res as List<dynamic>)
        .map((e) => FestivalModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Stream<List<FestivalInvitationModel>> getFestivalInvitationsStream() {
    final myUid = currentUserId;
    if (myUid == null) return const Stream.empty();

    return SupabaseConfig.watchQuery(
      () async {
        final res = await SupabaseConfig.client.rpc(
          'get_user_festival_invitations',
          params: {'p_uid': myUid},
        );
        final list = (res as List<dynamic>? ?? const []);
        return list
            .map(
              (item) => FestivalInvitationModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      },
      tables: const ['festival_invitations'],
      channelPrefix: 'festival_invitations_$myUid',
    );
  }

  Future<void> respondFestivalInvitation(int inviteId, String status) async {
    await SupabaseConfig.client.rpc(
      'respond_festival_invitation',
      params: {
        'p_invite_id': inviteId,
        'p_status': status,
      },
    );
    SupabaseConfig.notifyRefresh();
  }

  /// Invites a Chinari/Saathi bond partner to a festival and posts an interactive invitation in Chat.
  Future<void> inviteToFestival({
    required String bondId,
    required int festivalId,
    String? note,
    bool markDatePassed = false,
  }) async {
    final myUid = currentUserId;
    if (myUid == null) return;

    await SupabaseConfig.client.rpc(
      'invite_to_festival',
      params: {
        'p_bond_id': bondId,
        'p_host_uid': myUid,
        'p_festival_id': festivalId,
        'p_note': note,
        'p_mark_date_passed': markDatePassed,
      },
    );
    SupabaseConfig.notifyRefresh();
  }

  Future<void> setBondFestival({
    required String bondId,
    required int? festivalId,
    String? note,
  }) async {
    final myUid = currentUserId;
    if (myUid == null) return;

    if (festivalId != null) {
      await inviteToFestival(
        bondId: bondId,
        festivalId: festivalId,
        note: note,
      );
      return;
    }

    await SupabaseConfig.client.rpc(
      'set_bond_festival',
      params: {
        'p_bond_id': bondId,
        'p_user_uid': myUid,
        'p_festival_id': null,
        'p_note': note,
      },
    );
    SupabaseConfig.notifyRefresh();
  }

  /// Marks the scheduled festival date as having passed so both users are asked "Did you meet?"
  Future<void> markFestivalDatePassed(String bondId) async {
    await SupabaseConfig.client.rpc(
      'mark_festival_date_passed',
      params: {'p_bond_id': bondId},
    );
    SupabaseConfig.notifyRefresh();
  }

  /// Post-festival verification: "Did you meet?"
  /// Both confirming true upgrades bond to Stage 2 (Saathi) and unlocks Mit.
  /// Either confirming false keeps bond at Stage 1 (Chinari) with Mit locked.
  Future<Map<String, dynamic>> verifyFestivalMeetup({
    required String bondId,
    required bool didMeet,
    String? userUidOverride,
  }) async {
    final uid = userUidOverride ?? currentUserId;
    if (uid == null) return const {};

    final res = await SupabaseConfig.client.rpc(
      'verify_festival_meetup',
      params: {
        'p_bond_id': bondId,
        'p_user_uid': uid,
        'p_did_meet': didMeet,
      },
    );
    SupabaseConfig.notifyRefresh();
    return res is Map ? Map<String, dynamic>.from(res) : const {};
  }

  Future<void> deleteBond(String bondId) async {
    final myUid = currentUserId;
    if (myUid == null) return;
    await SupabaseConfig.client.rpc(
      'decline_bond_request',
      params: {'p_bond_id': bondId, 'p_user_uid': myUid},
    );
    SupabaseConfig.notifyRefresh();
  }

  Future<List<UserModel>> getDiscoverableUsers() async {
    final myUid = currentUserId;
    if (myUid == null) return [];

    final res = await SupabaseConfig.client.rpc(
      'get_discoverable_users',
      params: {'p_uid': myUid},
    );
    final list = (res as List<dynamic>? ?? const []);
    return list.map((item) {
      final map = Map<String, dynamic>.from(item);
      return UserModel.fromMap(map, map['uid'] as String? ?? '');
    }).toList();
  }

  /// Case 1 (Swipe Right / Tap Bond on Home) & Case 2 (Search User ID & Tap Bond):
  /// Creates Stage 0 Pending Bond and sends User A's automated greeting message into Chat.
  Future<Map<String, dynamic>> sendBondRequest({
    required String targetUid,
    String? automatedMessage,
    String? matchReason,
  }) async {
    final myUid = currentUserId;
    if (myUid == null) return const {};

    final res = await SupabaseConfig.client.rpc(
      'send_bond_request',
      params: {
        'p_sender_uid': myUid,
        'p_target_uid': targetUid,
        'p_automated_message':
            automatedMessage ?? defaultInitiatorAutomatedMessage,
        'p_match_reason': matchReason,
      },
    );
    SupabaseConfig.notifyRefresh();
    return res is Map ? Map<String, dynamic>.from(res) : const {};
  }

  /// User B accepts User A's bond request in Chat by sending their automated acceptance message.
  /// Unlocks Stage 1: Chinari and enables free chat!
  Future<Map<String, dynamic>> acceptBondRequest({
    required String bondId,
    String? automatedReply,
    String? accepterUidOverride,
  }) async {
    final uid = accepterUidOverride ?? currentUserId;
    if (uid == null) return const {};

    final res = await SupabaseConfig.client.rpc(
      'accept_bond_request',
      params: {
        'p_bond_id': bondId,
        'p_accepter_uid': uid,
        'p_automated_reply':
            automatedReply ?? defaultAccepterAutomatedMessage,
      },
    );
    SupabaseConfig.notifyRefresh();
    return res is Map ? Map<String, dynamic>.from(res) : const {};
  }

  /// User B declines a pending Stage 0 bond request.
  Future<void> declineBondRequest(String bondId) async {
    final myUid = currentUserId;
    if (myUid == null) return;

    await SupabaseConfig.client.rpc(
      'decline_bond_request',
      params: {
        'p_bond_id': bondId,
        'p_user_uid': myUid,
      },
    );
    SupabaseConfig.notifyRefresh();
  }

  Future<void> swipeUser({
    required String targetUid,
    required String action, // 'pass' or 'bond'
    String? matchReason,
  }) async {
    final myUid = currentUserId;
    if (myUid == null) return;

    if (action == 'bond') {
      await sendBondRequest(
        targetUid: targetUid,
        matchReason: matchReason,
      );
      return;
    }

    await SupabaseConfig.client.from('profile_swipes').upsert({
      'swiper_uid': myUid,
      'target_uid': targetUid,
      'action': 'pass',
      'match_reason': matchReason,
    });
    SupabaseConfig.notifyRefresh();
  }

  Future<void> undoSwipe(String targetUid) async {
    final myUid = currentUserId;
    if (myUid == null) return;

    await SupabaseConfig.client
        .from('profile_swipes')
        .delete()
        .eq('swiper_uid', myUid)
        .eq('target_uid', targetUid);
    SupabaseConfig.notifyRefresh();
  }

  Future<void> createBondWithUser(
    UserModel otherUser, {
    String? matchReason,
  }) async {
    await sendBondRequest(
      targetUid: otherUser.uid,
      matchReason: matchReason,
    );
  }

  Stream<Map<String, int>> getNavBadgesStream() {
    final myUid = currentUserId;
    if (myUid == null) return const Stream.empty();

    return SupabaseConfig.watchQuery(
      () async {
        final res = await SupabaseConfig.client.rpc(
          'get_nav_badges',
          params: {'p_uid': myUid},
        );
        final map = res is Map ? Map<String, dynamic>.from(res) : const {};
        return {
          'eventsCount': (map['eventsCount'] as num?)?.toInt() ?? 0,
          'chatsCount': (map['chatsCount'] as num?)?.toInt() ?? 0,
        };
      },
      tables: const ['bonds', 'messages', 'festival_invitations'],
      channelPrefix: 'nav_badges_$myUid',
    );
  }

  /// Case 2: Search any user by username/handle (@sunita.rai), phone (+977...), or name to send a bond request
  Future<List<UserModel>> searchUsersForBonding(String query) async {
    final myUid = currentUserId;
    final cleanQuery = query.trim();
    if (myUid == null || cleanQuery.isEmpty) return [];

    final res = await SupabaseConfig.client.rpc(
      'search_all_users_for_bonding',
      params: {
        'p_uid': myUid,
        'p_query': cleanQuery,
      },
    );
    final list = (res as List<dynamic>? ?? const []);

    return list.map((item) {
      final map = Map<String, dynamic>.from(item);
      return UserModel.fromMap(map, map['uid'] as String? ?? '');
    }).toList();
  }

  Future<List<UserModel>> searchBondedUsers(String query) async {
    return searchUsersForBonding(query);
  }

  Future<void> confirmStageAdvance(
    BondModel bond, {
    String? userUidOverride,
  }) async {
    final uid = userUidOverride ?? currentUserId;
    if (uid == null || bond.stage >= 3) return;

    await SupabaseConfig.client.rpc(
      'confirm_bond_stage',
      params: {
        'p_bond_id': bond.bondId,
        'p_user_uid': uid,
      },
    );
    SupabaseConfig.notifyRefresh();
  }
}
