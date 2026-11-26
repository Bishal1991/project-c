class UserModel {
  final String uid;
  final String displayName;
  final String? username;
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;
  final String? community;
  final String? region;
  final String? city;
  final String? area;
  final int? age;
  final String? college;
  final String? bio;
  final List<String> interests;
  final List<String> languages;

  // Optional bond relationship fields returned by search_all_users_for_bonding
  final String? bondId;
  final int? bondStage;
  final String? initiatorUid;
  final String? requestStatus;

  UserModel({
    required this.uid,
    required this.displayName,
    this.username,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    this.community,
    this.region,
    this.city,
    this.area,
    this.age,
    this.college,
    this.bio,
    this.interests = const [],
    this.languages = const [],
    this.bondId,
    this.bondStage,
    this.initiatorUid,
    this.requestStatus,
  });

  String get handle {
    if (username != null && username!.trim().isNotEmpty) {
      return '@${username!.trim()}';
    }
    final slug = displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '@${slug.isEmpty ? 'user' : slug}';
  }

  String get culturalLabel => [
        if (community != null && community!.isNotEmpty) community!,
        if (region != null && region!.isNotEmpty)
          region!
        else if (city != null && city!.isNotEmpty)
          city!,
      ].join(' · ');

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      if (username != null) 'username': username,
      'email': email?.toLowerCase(),
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      if (community != null) 'community': community,
      if (region != null) 'region': region,
      if (city != null) 'city': city,
      if (area != null) 'area': area,
      if (age != null) 'age': age,
      if (college != null) 'college': college,
      if (bio != null) 'bio': bio,
      'interests': interests,
      'languages': languages,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id.isNotEmpty ? id : (map['uid'] as String? ?? ''),
      displayName:
          (map['displayName'] ?? map['display_name'] ?? 'User') as String,
      username: map['username'] as String?,
      email: map['email'] as String?,
      phoneNumber: (map['phoneNumber'] ?? map['phone_number']) as String?,
      photoUrl: (map['photoUrl'] ?? map['photo_url']) as String?,
      community: map['community'] as String?,
      region: map['region'] as String?,
      city: map['city'] as String?,
      area: map['area'] as String?,
      age: (map['age'] as num?)?.toInt(),
      college: map['college'] as String?,
      bio: map['bio'] as String?,
      interests:
          (map['interests'] as List?)?.map((e) => '$e').toList() ?? const [],
      languages:
          (map['languages'] as List?)?.map((e) => '$e').toList() ?? const [],
      bondId: map['bondId'] as String?,
      bondStage: (map['bondStage'] as num?)?.toInt(),
      initiatorUid: map['initiatorUid'] as String?,
      requestStatus: map['requestStatus'] as String?,
    );
  }
}
