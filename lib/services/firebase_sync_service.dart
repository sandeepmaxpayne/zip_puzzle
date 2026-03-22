import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../models/app_progress.dart';
import '../models/auth_profile.dart';
import '../models/classic_leaderboard.dart';
import '../models/purchase_record.dart';

class FirebaseSyncService {
  bool _ready = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>['email']);

  bool get isReady => _ready && FirebaseAuth.instance.currentUser != null;

  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  AuthProfile? get currentProfile {
    if (Firebase.apps.isEmpty) {
      return null;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }
    return AuthProfile(
      uid: user.uid,
      isAnonymous: user.isAnonymous,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
    );
  }

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<AppProgress?> fetchProgress() async {
    if (!isReady) {
      return null;
    }
    try {
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final data = document.data();
      if (data == null) {
        return null;
      }
      return AppProgress.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProgress(AppProgress progress) async {
    if (!isReady) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        ...progress.toJson(),
        'profile': {
          'displayName': currentProfile?.displayName,
          'email': currentProfile?.email,
          'photoUrl': currentProfile?.photoUrl,
          'isAnonymous': currentProfile?.isAnonymous ?? false,
        },
      }, SetOptions(merge: true));
    } catch (_) {
      // Local storage remains the primary fallback.
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    if (!_ready) {
      throw Exception('Firebase is not ready yet.');
    }
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> registerWithEmail(String email, String password) async {
    if (!_ready) {
      throw Exception('Firebase is not ready yet.');
    }
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signInAnonymously() async {
    if (!_ready) {
      throw Exception('Firebase is not ready yet.');
    }
    await FirebaseAuth.instance.signInAnonymously();
  }

  Future<void> signInWithGoogle() async {
    if (!_ready) {
      throw Exception('Firebase is not ready yet.');
    }
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in was cancelled.');
    }
    final authentication = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: authentication.accessToken,
      idToken: authentication.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (!_ready) {
      return;
    }
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (!_ready) {
      throw Exception('Firebase is not ready yet.');
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<void> updateProfile({
    required String displayName,
    required String photoUrl,
  }) async {
    if (!_ready) {
      throw Exception('Firebase is not ready yet.');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No signed-in user found.');
    }
    await user.updateDisplayName(displayName.isEmpty ? null : displayName);
    await user.updatePhotoURL(photoUrl.isEmpty ? null : photoUrl);
    await user.reload();
  }

  Future<List<ClassicLeaderboardEntry>> fetchClassicLeaderboard({
    required int year,
    required int day,
    required ClassicDifficulty difficulty,
    int limit = 10,
  }) async {
    if (!isReady) {
      return const <ClassicLeaderboardEntry>[];
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('classic_leaderboards')
          .doc('$year-$day-${difficulty.name}')
          .collection('entries')
          .orderBy('score', descending: true)
          .orderBy('elapsedSeconds')
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => ClassicLeaderboardEntry.fromJson(doc.data()))
          .toList();
    } catch (_) {
      return const <ClassicLeaderboardEntry>[];
    }
  }

  Future<void> submitClassicLeaderboardEntry({
    required int year,
    required int day,
    required ClassicDifficulty difficulty,
    required int score,
    required int elapsedSeconds,
    required int hintsUsed,
    required int undoCount,
  }) async {
    if (!isReady || userId == null) {
      return;
    }
    try {
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final displayName = currentProfile?.displayName?.trim().isNotEmpty == true
          ? currentProfile!.displayName!.trim()
          : (currentProfile?.email?.trim().isNotEmpty == true
              ? currentProfile!.email!.trim()
              : 'Player ${userId!.substring(0, 6).toUpperCase()}');
      final docRef = FirebaseFirestore.instance
          .collection('classic_leaderboards')
          .doc('$year-$day-${difficulty.name}')
          .collection('entries')
          .doc(userId);

      final current = await docRef.get();
      final nextEntry = ClassicLeaderboardEntry(
        userId: userId!,
        displayName: displayName,
        score: score,
        elapsedSeconds: elapsedSeconds,
        hintsUsed: hintsUsed,
        undoCount: undoCount,
        difficulty: difficulty,
        updatedAtIso: nowIso,
      );

      if (!current.exists) {
        await docRef.set(nextEntry.toJson());
        return;
      }

      final existing = ClassicLeaderboardEntry.fromJson(current.data()!);
      final isBetter = score > existing.score ||
          (score == existing.score &&
              elapsedSeconds < existing.elapsedSeconds);
      if (isBetter) {
        await docRef.set(nextEntry.toJson(), SetOptions(merge: true));
      }
    } catch (_) {
      // Ignore cloud leaderboard failures; gameplay stays available.
    }
  }

  Future<void> savePurchaseRecord(PurchaseRecord purchaseRecord) async {
    if (!isReady || userId == null) {
      return;
    }
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      await userDoc.collection('purchases').add(purchaseRecord.toJson());
      await userDoc.set(
        <String, dynamic>{
          'monetization': <String, dynamic>{
            'lastPurchaseAtIso': purchaseRecord.grantedAtIso,
            'lastProductId': purchaseRecord.productId,
          },
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Purchase history is mirrored to Firestore when available.
    }
  }
}
