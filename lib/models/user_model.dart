class UserModel {
  final String uid;
  final String displayName;
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;
  final String? community;
  final String? region;

  UserModel({
    required this.uid,
    required this.displayName,
    this.email,
    this.phoneNumber,
    this.photoUrl,
    this.community,
    this.region,
  });

  String get culturalLabel => [
        if (community != null && community!.isNotEmpty) community!,
        if (region != null && region!.isNotEmpty) region!,
      ].join(' · ');

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email?.toLowerCase(),
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      if (community != null) 'community': community,
      if (region != null) 'region': region,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      displayName: map['displayName'] as String? ?? 'User',
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      photoUrl: map['photoUrl'] as String?,
      community: map['community'] as String?,
      region: map['region'] as String?,
    );
  }
}