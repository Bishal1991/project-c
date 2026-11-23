import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bond_model.dart';
import '../models/user_model.dart';

class BondService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<List<BondModel>> getBondsStream() {
    final myUid = currentUserId;
    if (myUid == null) return const Stream.empty();

    return _firestore
        .collection('bonds')
        .where('participants', arrayContains: myUid)
        .snapshots()
        .map((snap) {
          final bonds = snap.docs.map(BondModel.fromDoc).toList();
          bonds.sort((a, b) {
            final stageCmp = b.stage.compareTo(a.stage);
            return stageCmp != 0 ? stageCmp : b.createdAt.compareTo(a.createdAt);
          });
          return bonds;
        });
  }

  // Search only among already bonded users (used by Chat searchbar)
  // ponytail: filters user's own bonds client-side; fine for personal bond lists (<100)
  Future<List<UserModel>> searchBondedUsers(String query) async {
    final myUid = currentUserId;
    final cleanQuery = query.trim().toLowerCase();
    if (myUid == null || cleanQuery.isEmpty) return [];

    final searchPhone = cleanQuery.replaceAll(' ', '');
    final snap = await _firestore
        .collection('bonds')
        .where('participants', arrayContains: myUid)
        .get();

    return snap.docs
        .map((doc) => BondModel.fromDoc(doc).otherUser(myUid))
        .where((user) {
          if (user.uid.isEmpty) return false;
          final name = user.displayName.toLowerCase();
          final email = (user.email ?? '').toLowerCase();
          final phone = (user.phoneNumber ?? '').replaceAll(' ', '');
          return name.contains(cleanQuery) ||
              email.contains(cleanQuery) ||
              phone.contains(searchPhone);
        })
        .toList();
  }

  // Both participants confirm to move Chinari -> Saathi -> Mit
  Future<void> confirmStageAdvance(BondModel bond) async {
    final myUid = currentUserId;
    if (myUid == null || bond.stage >= 3) return;
    if (bond.stageConfirmations.contains(myUid)) return;

    final updatedConfirmations = [...bond.stageConfirmations, myUid];
    final bothConfirmed = bond.participants.every(updatedConfirmations.contains);
    final ref = _firestore.collection('bonds').doc(bond.bondId);

    if (bothConfirmed) {
      final nextStage = bond.stage + 1;
      final label = BondModel.stageNames[nextStage - 1];
      await ref.update({
        'stage': nextStage,
        'stageConfirmations': [],
        'festivalsShared': FieldValue.increment(1),
        'history': FieldValue.arrayUnion(['Reached $label']),
      });
    } else {
      await ref.update({
        'stageConfirmations': FieldValue.arrayUnion([myUid]),
      });
    }
  }
}
