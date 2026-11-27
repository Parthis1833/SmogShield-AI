import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';
import '../models/family_profile.dart';

abstract class AuthService {
  bool get isAuthenticated;
  String? get currentUserId;
  String? get currentUserEmail;
  String? get currentUserDisplayName;
  String? get currentUserPhotoUrl;
  bool get isAnonymous;
  Stream<String?> get emailChanges;
  Stream<User?> get authStateChanges;
  Future<String> getIdToken();
  Future<void> signInAnonymously();
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<UserCredential> signInWithGoogle();
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Web client ID from google-services.json oauth_client
  static const _webClientId =
      '962117559195-26jjhfkirj49ibt19hq245oau9cdvh8l.apps.googleusercontent.com';

  @override
  bool get isAuthenticated =>
      Firebase.apps.isNotEmpty && _auth.currentUser != null;

  @override
  String? get currentUserId =>
      Firebase.apps.isEmpty ? null : _auth.currentUser?.uid;

  @override
  String? get currentUserEmail =>
      Firebase.apps.isEmpty ? null : _auth.currentUser?.email;

  @override
  String? get currentUserDisplayName =>
      Firebase.apps.isEmpty ? null : _auth.currentUser?.displayName;

  @override
  String? get currentUserPhotoUrl =>
      Firebase.apps.isEmpty ? null : _auth.currentUser?.photoURL;

  @override
  bool get isAnonymous =>
      Firebase.apps.isEmpty ? true : (_auth.currentUser?.isAnonymous ?? true);

  @override
  Stream<String?> get emailChanges => Firebase.apps.isEmpty
      ? Stream<String?>.value(null)
      : _auth.authStateChanges().map((user) => user?.email);

  @override
  Stream<User?> get authStateChanges => Firebase.apps.isEmpty
      ? Stream<User?>.value(null)
      : _auth.authStateChanges();

  @override
  Future<String> getIdToken() async {
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not configured.');
    }
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('Sign in before requesting an ID token.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Firebase did not return an ID token.');
    }
    return token;
  }

  @override
  Future<void> signInAnonymously() async {
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not configured.');
    }
    await _auth.signInAnonymously();
  }

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not configured.');
    }
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not configured.');
    }
    final user = _auth.currentUser;
    if (user?.isAnonymous == true) {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user!.linkWithCredential(credential);
      return;
    }
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    if (Firebase.apps.isEmpty) {
      throw StateError('Firebase is not configured.');
    }

    if (kIsWeb) {
      // Web: Use Firebase Auth popup flow directly
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      return await _auth.signInWithPopup(googleProvider);
    }

    // Android/iOS: Use google_sign_in package
    final googleSignIn = GoogleSignIn(
      serverClientId: _webClientId,
      scopes: ['email', 'profile'],
    );

    // Sign out first to force account picker
    await googleSignIn.signOut();

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google Sign-In was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // If user is currently anonymous, link the Google credential
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.isAnonymous) {
      try {
        return await currentUser.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          // The Google account is already linked to another Firebase user.
          // Sign in with the existing account instead.
          return await _auth.signInWithCredential(credential);
        }
        rethrow;
      }
    }

    return await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    if (Firebase.apps.isNotEmpty) {
      // Sign out from Google first
      if (!kIsWeb) {
        try {
          await GoogleSignIn().signOut();
        } catch (_) {
          // Ignore errors from Google Sign-Out
        }
      }
      await _auth.signOut();
    }
  }
}

abstract class FirestoreSyncService {
  Future<void> saveProfile(FamilyProfile profile);
  Future<FamilyProfile?> fetchProfile(String userId);
  Future<void> recordLoggedAction(String actionId, double co2eSavings);
}

class FirebaseFirestoreSyncService implements FirestoreSyncService {
  FirebaseFirestore get _firestore =>
      FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: AppConfig.firebaseDatabaseId,
      );

  @override
  Future<void> saveProfile(FamilyProfile profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in before saving a profile.');
    await _firestore.collection('users').doc(user.uid).set({
      'city': profile.city,
      'adults_count': profile.adultsCount,
      'children_count': profile.childrenCount,
      'seniors_count': profile.seniorsCount,
      'has_vulnerable_member': profile.hasVulnerableMember,
      'primary_commute_mode': profile.primaryCommuteMode,
      'air_purification_setup': profile.airPurificationSetup,
      'alert_on_spikes': profile.alertOnSpikes,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<FamilyProfile?> fetchProfile(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    final data = snapshot.data();
    if (data == null) return null;
    return FamilyProfile(
      city: data['city'] as String? ?? '',
      adultsCount: data['adults_count'] as int? ?? 0,
      childrenCount: data['children_count'] as int? ?? 0,
      seniorsCount: data['seniors_count'] as int? ?? 0,
      hasVulnerableMember: data['has_vulnerable_member'] as bool? ?? false,
      primaryCommuteMode: data['primary_commute_mode'] as String? ?? '',
      airPurificationSetup: data['air_purification_setup'] as String? ?? '',
      alertOnSpikes: data['alert_on_spikes'] as bool? ?? false,
    );
  }

  @override
  Future<void> recordLoggedAction(String actionId, double co2eSavings) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in before recording an action.');
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('impact_actions')
        .add({
      'action_id': actionId,
      'co2e_savings_kg': co2eSavings,
      'recorded_at': FieldValue.serverTimestamp(),
    });
  }
}

final authServiceProvider =
    Provider<AuthService>((ref) => FirebaseAuthService());
final authEmailProvider = StreamProvider<String?>(
  (ref) => ref.watch(authServiceProvider).emailChanges,
);
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);
final firestoreSyncServiceProvider =
    Provider<FirestoreSyncService>((ref) => FirebaseFirestoreSyncService());
