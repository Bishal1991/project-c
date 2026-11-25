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
      tables: const ['bonds', 'bond_confirmations', 'bond_history', 'messages'],
      channelPrefix: 'user_bonds_$myUid',
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
