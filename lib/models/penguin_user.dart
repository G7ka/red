class PenguinUser {
  final String id;
  final String firstName;
  final String? lastName;
  final String displayName;
  final String gender; // 'male' or 'female'
  final DateTime dob;
  final List<String> interests;
  final String? profileImageUrl;
  final List<String> friends;
  final String? anonymousPenguinType;
  final String? email;

  PenguinUser({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.displayName,
    required this.gender,
    required this.dob,
    required this.interests,
    this.profileImageUrl,
    required this.friends,
    this.anonymousPenguinType,
    this.email,
  });

  int get age {
    final now = DateTime.now();
    int years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years;
  }

  factory PenguinUser.fromMap(String id, Map<String, dynamic> data) {
    return PenguinUser(
      id: id,
      firstName: data['first_name'] as String? ?? '',
      lastName: data['last_name'] as String?,
      displayName: data['display_name'] as String? ?? '',
      gender: data['gender'] as String? ?? 'male',
      dob: DateTime.parse(data['dob'] as String),
      interests: (data['interests'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      profileImageUrl: data['image_url'] as String?,
      friends: (data['friends'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      anonymousPenguinType: data['anonymous_penguin_type'] as String?,
      email: data['email'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'gender': gender,
      'dob': dob.toIso8601String(),
      'age': age, // Store age for easier queries
      'interests': interests,
      'image_url': profileImageUrl,
      'friends': friends,
      'anonymous_penguin_type': anonymousPenguinType,
      'email': email,
    };
  }
}




