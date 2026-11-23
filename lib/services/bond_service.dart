import 'package:firebase_auth/firebase_auth.dart';
import '../models/bond_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class BondService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<List<BondModel>> getBondsStream() {
    final myUid = currentUserId;
    if (myUid == null) return const Stream.empty();

    return ApiClient.pollStream(() async {
      final list = await ApiClient.get('/users/$myUid/bonds') as List<dynamic>;
      return list
          .map((item) => BondModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  // Search only among already bonded users (used by Chat searchbar)
  Future<List<UserModel>> searchBondedUsers(String query) async {
    final myUid = currentUserId;
    final cleanQuery = query.trim();
    if (myUid == null || cleanQuery.isEmpty) return [];

    final encoded = Uri.encodeQueryComponent(cleanQuery);
    final list =
        await ApiClient.get('/users/$myUid/bonds/search?q=$encoded')
            as List<dynamic>;

    return list.map((item) {
      final map = Map<String, dynamic>.from(item);
      return UserModel.fromMap(map, map['uid'] as String? ?? '');
    }).toList();
  }

  // Both participants confirm to move Chinari (1) -> Saathi (2) -> Mit (3)
  Future<void> confirmStageAdvance(BondModel bond) async {
    final myUid = currentUserId;
    if (myUid == null || bond.stage >= 3) return;

    await ApiClient.post('/bonds/${bond.bondId}/confirm', {'userUid': myUid});
    ApiClient.notifyRefresh();
  }
}
