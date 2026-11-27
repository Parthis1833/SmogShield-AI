import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/firebase_service.dart';

abstract class FamilyMembersRepository {
  Stream<List<FamilyMember>> watchFamilyMembers(String userId);
  Future<List<FamilyMember>> fetchFamilyMembers(String userId);
  Future<void> saveFamilyMember(String userId, FamilyMember member);
  Future<void> deleteFamilyMember(String userId, String memberId);
  Future<UserPersonalProfile?> fetchUserProfile(String userId);
  Future<void> saveUserProfile(UserPersonalProfile profile);
  Stream<UserPersonalProfile?> watchUserProfile(String userId);
}

class FirestoreFamilyMembersRepository implements FamilyMembersRepository {
  final FirebaseFirestore _firestore;

  FirestoreFamilyMembersRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userRef(String userId) =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _familyRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('family_members');

  @override
  Stream<List<FamilyMember>> watchFamilyMembers(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _familyRef(userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FamilyMember.fromMap(doc.data(), docId: doc.id);
      }).toList();
    }).handleError((error) {
      // Gracefully handle Firestore missing database or permission issues
      return <FamilyMember>[];
    });
  }

  @override
  Future<List<FamilyMember>> fetchFamilyMembers(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final snapshot = await _familyRef(userId)
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs.map((doc) {
        return FamilyMember.fromMap(doc.data(), docId: doc.id);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> saveFamilyMember(String userId, FamilyMember member) async {
    if (userId.isEmpty) throw StateError('User ID is required');
    final docRef = member.id.isEmpty
        ? _familyRef(userId).doc()
        : _familyRef(userId).doc(member.id);

    final map = member.toMap();
    map['id'] = docRef.id;
    map['updatedAt'] = FieldValue.serverTimestamp();
    if (member.createdAt == null) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(map, SetOptions(merge: true));
  }

  @override
  Future<void> deleteFamilyMember(String userId, String memberId) async {
    if (userId.isEmpty || memberId.isEmpty) return;
    try {
      await _familyRef(userId).doc(memberId).delete();
    } catch (_) {}
  }

  @override
  Future<UserPersonalProfile?> fetchUserProfile(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final doc = await _userRef(userId).doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserPersonalProfile.fromMap(doc.data()!, uid: doc.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<UserPersonalProfile?> watchUserProfile(String userId) {
    if (userId.isEmpty) return Stream.value(null);
    return _userRef(userId).doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserPersonalProfile.fromMap(doc.data()!, uid: doc.id);
    }).handleError((error) {
      return null;
    });
  }

  @override
  Future<void> saveUserProfile(UserPersonalProfile profile) async {
    if (profile.uid.isEmpty) throw StateError('User UID is required');
    final map = profile.toMap();
    map['updatedAt'] = FieldValue.serverTimestamp();
    if (profile.createdAt == null) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }
    await _userRef(profile.uid).doc(profile.uid).set(map, SetOptions(merge: true));
  }
}

// Global Providers
final familyMembersRepositoryProvider = Provider<FamilyMembersRepository>(
  (ref) => FirestoreFamilyMembersRepository(),
);

/// Real-time stream of the current user's profile
final userPersonalProfileProvider = StreamProvider<UserPersonalProfile?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null || user.isAnonymous) return Stream.value(null);
  return ref.watch(familyMembersRepositoryProvider).watchUserProfile(user.uid);
});

/// Real-time stream of family members for current authenticated user
final familyMembersStreamProvider = StreamProvider<List<FamilyMember>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(familyMembersRepositoryProvider).watchFamilyMembers(user.uid);
});
