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

  String? get currentUserId => _auth.currentUser?.uid;

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

  Future<void> setBondFestival({
    required String bondId,
    required int? festivalId,
    String? note,
  }) async {
    final myUid = currentUserId;
    if (myUid == null) return;

    await SupabaseConfig.client.rpc(
      'set_bond_festival',
      params: {
        'p_bond_id': bondId,
        'p_user_uid': myUid,
        'p_festival_id': festivalId,
        'p_note': note,
      },
    );
    SupabaseConfig.notifyRefresh();
  }

  Future<void> deleteBond(String bondId) async {
    await SupabaseConfig.client.from('bonds').delete().eq('id', bondId);
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

  Future<void> swipeUser({
    required String targetUid,
    required String action, // 'pass' or 'bond'
    String? matchReason,
  }) async {
    final myUid = currentUserId;
    if (myUid == null) return;

    await SupabaseConfig.client.from('profile_swipes').upsert({
      'swiper_uid': myUid,
      'target_uid': targetUid,
      'action': action,
      if (matchReason != null) 'match_reason': matchReason,
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
    final myUid = currentUserId;
    if (myUid == null) return;

    await SupabaseConfig.client.rpc(
      'create_or_get_bond',
      params: {
        'p_user1_uid': myUid,
        'p_user2_uid': otherUser.uid,
        'p_initiator_uid': myUid,
        'p_stage': 1,
        'p_match_reason': matchReason,
      },
    );
    SupabaseConfig.notifyRefresh();
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

  Future<List<UserModel>> searchBondedUsers(String query) async {
    final myUid = currentUserId;
    final cleanQuery = query.trim();
    if (myUid == null || cleanQuery.isEmpty) return [];

    final res = await SupabaseConfig.client.rpc(
      'search_bonded_users',
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

  Future<void> confirmStageAdvance(BondModel bond) async {
    final myUid = currentUserId;
    if (myUid == null || bond.stage >= 3) return;

    await SupabaseConfig.client.rpc(
      'confirm_bond_stage',
      params: {
        'p_bond_id': bond.bondId,
        'p_user_uid': myUid,
      },
    );
    SupabaseConfig.notifyRefresh();
  }
}
