class FamilyMemberHealth {
  final bool hasAsthma;
  final String asthmaSeverity; // 'None', 'Mild', 'Moderate', 'Severe', 'Unknown'
  final String otherRespiratoryConditions;
  final String otherHealthConditions;
  final String healthNotes;
  final DateTime? updatedAt;

  const FamilyMemberHealth({
    this.hasAsthma = false,
    this.asthmaSeverity = 'None',
    this.otherRespiratoryConditions = '',
    this.otherHealthConditions = '',
    this.healthNotes = '',
    this.updatedAt,
  });

  bool get isVulnerable =>
      hasAsthma ||
      otherRespiratoryConditions.trim().isNotEmpty ||
      otherHealthConditions.trim().isNotEmpty;

  FamilyMemberHealth copyWith({
    bool? hasAsthma,
    String? asthmaSeverity,
    String? otherRespiratoryConditions,
    String? otherHealthConditions,
    String? healthNotes,
    DateTime? updatedAt,
  }) {
    return FamilyMemberHealth(
      hasAsthma: hasAsthma ?? this.hasAsthma,
      asthmaSeverity: asthmaSeverity ?? this.asthmaSeverity,
      otherRespiratoryConditions:
          otherRespiratoryConditions ?? this.otherRespiratoryConditions,
      otherHealthConditions:
          otherHealthConditions ?? this.otherHealthConditions,
      healthNotes: healthNotes ?? this.healthNotes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hasAsthma': hasAsthma,
      'asthmaSeverity': asthmaSeverity,
      'otherRespiratoryConditions': otherRespiratoryConditions,
      'otherHealthConditions': otherHealthConditions,
      'healthNotes': healthNotes,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory FamilyMemberHealth.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const FamilyMemberHealth();
    return FamilyMemberHealth(
      hasAsthma: map['hasAsthma'] as bool? ?? false,
      asthmaSeverity: map['asthmaSeverity'] as String? ?? 'None',
      otherRespiratoryConditions:
          map['otherRespiratoryConditions'] as String? ?? '',
      otherHealthConditions: map['otherHealthConditions'] as String? ?? '',
      healthNotes: map['healthNotes'] as String? ?? '',
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }
}

class FamilyMember {
  final String id;
  final String name;
  final String relationship; // Father, Mother, Spouse, Son, Daughter, Brother, Sister, Grandparent, Other
  final DateTime? dateOfBirth;
  final int? cachedAge;
  final String? gender;
  final String? photoURL;
  final FamilyMemberHealth health;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.dateOfBirth,
    this.cachedAge,
    this.gender,
    this.photoURL,
    this.health = const FamilyMemberHealth(),
    this.createdAt,
    this.updatedAt,
  });

  /// Automatically computes age from dateOfBirth, or falls back to cachedAge
  int get age {
    if (dateOfBirth != null) {
      final now = DateTime.now();
      int calculated = now.year - dateOfBirth!.year;
      if (now.month < dateOfBirth!.month ||
          (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
        calculated--;
      }
      return calculated >= 0 ? calculated : 0;
    }
    return cachedAge ?? 0;
  }

  bool get isChild => age < 18;
  bool get isSenior => age >= 60;
  bool get isVulnerable => isChild || isSenior || health.isVulnerable;

  FamilyMember copyWith({
    String? id,
    String? name,
    String? relationship,
    DateTime? dateOfBirth,
    int? cachedAge,
    String? gender,
    String? photoURL,
    FamilyMemberHealth? health,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      cachedAge: cachedAge ?? this.cachedAge,
      gender: gender ?? this.gender,
      photoURL: photoURL ?? this.photoURL,
      health: health ?? this.health,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'age': age,
      'gender': gender,
      'photoURL': photoURL,
      'health': health.toMap(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map, {String? docId}) {
    return FamilyMember(
      id: docId ?? (map['id'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      relationship: map['relationship'] as String? ?? 'Other',
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'].toString())
          : null,
      cachedAge: map['age'] as int?,
      gender: map['gender'] as String?,
      photoURL: map['photoURL'] as String?,
      health: map['health'] is Map<String, dynamic>
          ? FamilyMemberHealth.fromMap(map['health'] as Map<String, dynamic>)
          : const FamilyMemberHealth(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }
}

class UserPersonalProfile {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final DateTime? dateOfBirth;
  final int? cachedAge;
  final String? gender;
  final String? photoURL;
  final String city;
  final String state;
  final String country;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserPersonalProfile({
    this.uid = '',
    this.name = '',
    this.email = '',
    this.phone = '',
    this.dateOfBirth,
    this.cachedAge,
    this.gender,
    this.photoURL,
    this.city = '',
    this.state = '',
    this.country = 'India',
    this.createdAt,
    this.updatedAt,
  });

  int get age {
    if (dateOfBirth != null) {
      final now = DateTime.now();
      int calculated = now.year - dateOfBirth!.year;
      if (now.month < dateOfBirth!.month ||
          (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
        calculated--;
      }
      return calculated >= 0 ? calculated : 0;
    }
    return cachedAge ?? 0;
  }

  UserPersonalProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    int? cachedAge,
    String? gender,
    String? photoURL,
    String? city,
    String? state,
    String? country,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPersonalProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      cachedAge: cachedAge ?? this.cachedAge,
      gender: gender ?? this.gender,
      photoURL: photoURL ?? this.photoURL,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'age': age,
      'gender': gender,
      'photoURL': photoURL,
      'city': city,
      'state': state,
      'country': country,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory UserPersonalProfile.fromMap(Map<String, dynamic> map, {String? uid}) {
    return UserPersonalProfile(
      uid: uid ?? (map['uid'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'].toString())
          : null,
      cachedAge: map['age'] as int?,
      gender: map['gender'] as String?,
      photoURL: map['photoURL'] as String?,
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      country: map['country'] as String? ?? 'India',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString())
          : null,
    );
  }
}
