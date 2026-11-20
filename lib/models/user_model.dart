class UserModel {
  final String uid;
  final String displayName;
  final String? email;
  final String? phoneNumber;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.displayName,
    this.email,
    this.phoneNumber,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email?.toLowerCase(),
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
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
    );
  }
}