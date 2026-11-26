import 'package:firebase_auth/firebase_auth.dart';
import '../models/bond_model.dart';
import '../models/user_model.dart';
import '../supabase_config.dart';

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

  Future<List<FestivalModel>> getFestivals() async {
    final res = await SupabaseConfig.client
        .from('festivals')
        .select()
        .order('id', ascending: true);
    return (res as List<dynamic>)
        .map((e) => FestivalModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
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

  // Search only among already bonded users (used by Chat searchbar)
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

  // Both participants confirm to move Chinari (1) -> Saathi (2) -> Mit (3)
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
