import 'user_model.dart';

class BondStageInfo {
  final int stage;
  final String name;
  final String subtitle;
  final String description;

  const BondStageInfo({
    required this.stage,
    required this.name,
    required this.subtitle,
    required this.description,
  });

  factory BondStageInfo.fromJson(Map<String, dynamic> json) {
    return BondStageInfo(
      stage: (json['stage'] as num?)?.toInt() ?? 1,
      name: json['name'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class FestivalModel {
  final int id;
  final String name;
  final String community;
  final String region;
  final String eventDate;
  final String? etiquetteNotes;
  final String? description;

  const FestivalModel({
    required this.id,
    required this.name,
    required this.community,
    required this.region,
    required this.eventDate,
    this.etiquetteNotes,
    this.description,
  });

  factory FestivalModel.fromJson(Map<String, dynamic> json) {
    return FestivalModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      community: json['community'] as String? ?? '',
      region: json['region'] as String? ?? '',
      eventDate: json['event_date'] as String? ?? '',
      etiquetteNotes: json['etiquette_notes'] as String?,
      description: json['description'] as String?,
    );
  }
}

class BondModel {
  static const stageNames = ['Chinari', 'Saathi', 'Mit'];

  final String bondId;
  final UserModel partner;
  final int stage; // 0 = Pending Request, 1 = Chinari, 2 = Saathi, 3 = Mit
  final String? initiatorUid;
  final String requestStatus;
  final String? matchReason;
  final DateTime createdAt;
  final int festivalsShared;
  final int messageCount;
  final int? upcomingFestivalId;
  final String? upcomingEventTitle;
  final String? upcomingEventDate;
  final String? upcomingEventNote;
  final bool upcomingEventDatePassed;
  final List<String> history;
  final List<String> stageConfirmations;

  BondModel({
    required this.bondId,
    required this.partner,
    required this.stage,
    required this.createdAt,
    this.initiatorUid,
    this.requestStatus = 'active',
    this.matchReason,
    this.festivalsShared = 0,
    this.messageCount = 0,
    this.upcomingFestivalId,
    this.upcomingEventTitle,
    this.upcomingEventDate,
    this.upcomingEventNote,
    this.upcomingEventDatePassed = false,
    this.history = const [],
    this.stageConfirmations = const [],
  });

  bool get isPendingRequest => stage == 0;
  bool get hasChinari => stage >= 1;
  bool get isSaathiOrHigher => stage >= 2;
  bool get isMitUnlocked => stage >= 2;
  bool get isMit => stage >= 3;

  String get currentStageLabel {
    if (stage <= 0) return 'Pending Request';
    final idx = (stage - 1).clamp(0, stageNames.length - 1);
    return stageNames[idx];
  }

  int get daysBonded =>
      DateTime.now().difference(createdAt).inDays.clamp(0, 99999);

  String? get nextStageName {
    if (stage <= 0) return 'Chinari';
    return stage < 3 ? stageNames[stage] : null;
  }

  UserModel otherUser(String _) => partner;

  factory BondModel.fromJson(Map<String, dynamic> json) {
    final partner = UserModel(
      uid: json['other_uid'] as String? ?? '',
      displayName: json['other_name'] as String? ?? 'User',
      username: json['other_username'] as String?,
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
      stage: (json['stage'] as num?)?.toInt().clamp(0, 3) ?? 0,
      initiatorUid: json['initiator_uid'] as String?,
      requestStatus: json['request_status'] as String? ?? 'active',
      matchReason: json['match_reason'] as String?,
      createdAt: createdAt,
      festivalsShared: (json['festivals_shared'] as num?)?.toInt() ?? 0,
      messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
      upcomingFestivalId: (json['upcoming_festival_id'] as num?)?.toInt(),
      upcomingEventTitle: json['upcoming_event_title'] as String?,
      upcomingEventDate: json['upcoming_event_date'] as String?,
      upcomingEventNote: json['upcoming_event_note'] as String?,
      upcomingEventDatePassed:
          (json['upcoming_event_date_passed'] as bool?) ?? false,
      history: (json['history'] as List?)?.map((e) => '$e').toList() ?? const [],
      stageConfirmations:
          (json['stage_confirmations'] as List?)?.map((e) => '$e').toList() ??
          const [],
    );
  }
}
