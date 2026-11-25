import 'user_model.dart';

class BondModel {
  static const stageNames = ['Chinari', 'Saathi', 'Mit'];

  final String bondId;
  final UserModel partner;
  final int stage; // 1 = Chinari, 2 = Saathi, 3 = Mit
  final String? matchReason;
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
    required this.partner,
    required this.stage,
    required this.createdAt,
    this.matchReason,
    this.festivalsShared = 0,
    this.messageCount = 0,
    this.upcomingEventTitle,
    this.upcomingEventDate,
    this.upcomingEventNote,
    this.history = const [],
    this.stageConfirmations = const [],
  });

  int get daysBonded =>
      DateTime.now().difference(createdAt).inDays.clamp(0, 99999);

  String? get nextStageName => stage < 3 ? stageNames[stage] : null;

  UserModel otherUser(String _) => partner;

  factory BondModel.fromJson(Map<String, dynamic> json) {
    final partner = UserModel(
      uid: json['other_uid'] as String? ?? '',
      displayName: json['other_name'] as String? ?? 'User',
      email: json['other_email'] as String?,
      phoneNumber: json['other_phone'] as String?,
      photoUrl: json['other_photo'] as String?,
      community: json['other_community'] as String?,
      region: json['other_region'] as String?,
    );

    final createdRaw = json['created_at'];
    final createdAt = createdRaw is String
        ? (DateTime.tryParse(createdRaw) ?? DateTime.now())
        : DateTime.now();

    return BondModel(
      bondId: json['bond_id'] as String? ?? '',
      partner: partner,
      stage: (json['stage'] as num?)?.toInt().clamp(1, 3) ?? 1,
      matchReason: json['match_reason'] as String?,
      createdAt: createdAt,
      festivalsShared: (json['festivals_shared'] as num?)?.toInt() ?? 0,
      messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
      upcomingEventTitle: json['upcoming_event_title'] as String?,
      upcomingEventDate: json['upcoming_event_date'] as String?,
      upcomingEventNote: json['upcoming_event_note'] as String?,
      history: (json['history'] as List?)?.map((e) => '$e').toList() ?? const [],
      stageConfirmations:
          (json['stage_confirmations'] as List?)?.map((e) => '$e').toList() ??
          const [],
    );
  }
}
