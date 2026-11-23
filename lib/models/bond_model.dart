import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class BondModel {
  static const stageNames = ['Chinari', 'Saathi', 'Mit'];

  final String bondId;
  final List<String> participants;
  final Map<String, dynamic> participantDetails;
  final int stage; // 1 = Chinari, 2 = Saathi, 3 = Mit
  final DateTime createdAt;
  final int festivalsShared;
  final int messageCount;
  final String? upcomingEventTitle;
  final String? upcomingEventDate;
  final String? upcomingEventNote;
  final List<String> history;
  final List<String> stageConfirmations;

  BondModel({
    required this.bondId,
    required this.participants,
    required this.participantDetails,
    required this.stage,
    required this.createdAt,
    this.festivalsShared = 0,
    this.messageCount = 0,
    this.upcomingEventTitle,
    this.upcomingEventDate,
    this.upcomingEventNote,
    this.history = const [],
    this.stageConfirmations = const [],
  });

  int get daysBonded => DateTime.now().difference(createdAt).inDays.clamp(0, 99999);

  String? get nextStageName => stage < 3 ? stageNames[stage] : null;

  UserModel otherUser(String myUid) {
    final otherUid = participants.firstWhere(
      (uid) => uid != myUid,
      orElse: () => '',
    );
    final raw = participantDetails[otherUid];
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return UserModel.fromMap(map, otherUid);
  }

  factory BondModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    final createdAt = ts is Timestamp ? ts.toDate() : DateTime.now();

    return BondModel(
      bondId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantDetails:
          Map<String, dynamic>.from(data['participantDetails'] ?? {}),
      stage: (data['stage'] as num?)?.toInt().clamp(1, 3) ?? 1,
      createdAt: createdAt,
      festivalsShared: (data['festivalsShared'] as num?)?.toInt() ?? 0,
      messageCount: (data['messageCount'] as num?)?.toInt() ?? 0,
      upcomingEventTitle: data['upcomingEventTitle'] as String?,
      upcomingEventDate: data['upcomingEventDate'] as String?,
      upcomingEventNote: data['upcomingEventNote'] as String?,
      history: List<String>.from(data['history'] ?? []),
      stageConfirmations: List<String>.from(data['stageConfirmations'] ?? []),
    );
  }
}
