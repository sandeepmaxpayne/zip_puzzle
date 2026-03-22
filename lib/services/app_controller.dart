import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/app_progress.dart';
import '../models/auth_profile.dart';
import '../models/classic_leaderboard.dart';
import 'firebase_sync_service.dart';
import 'monetization_config.dart';
import 'monetization_service.dart';
import 'progress_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    ProgressRepository? repository,
    FirebaseSyncService? firebaseSyncService,
    MonetizationService? monetizationService,
  })  : _repository = repository ?? ProgressRepository(),
        _firebaseSyncService = firebaseSyncService ?? FirebaseSyncService(),
        _monetizationService = monetizationService ?? MonetizationService();

  final ProgressRepository _repository;
  final FirebaseSyncService _firebaseSyncService;
  final MonetizationService _monetizationService;

  ThemeMode _themeMode = ThemeMode.light;
  AppProgress _progress = AppProgress.initial();
  bool _initialized = false;
  AuthProfile? _localGuestProfile;
  String? _billingMessage;

  ThemeMode get themeMode => _themeMode;
  AppProgress get progress => _progress;
  bool get isCloudReady => _firebaseSyncService.isReady;
  String? get cloudUserId => _firebaseSyncService.userId;
  bool get initialized => _initialized;
  bool get isBillingAvailable => _monetizationService.isBillingAvailable;
  List<ProductDetails> get monetizationProducts => _monetizationService.products;
  String? get billingMessage => _billingMessage;
  AuthProfile? get authProfile =>
      _firebaseSyncService.currentProfile ?? _localGuestProfile;
  bool get isSignedIn => authProfile != null;

  Future<void> initialize() async {
    _progress = await _repository.load();
    await _firebaseSyncService.initialize();
    if (isSignedIn) {
      final remote = await _firebaseSyncService.fetchProgress();
      if (remote != null &&
          (remote.totalClaims > _progress.totalClaims ||
              remote.totalScore > _progress.totalScore)) {
        _progress = remote;
      }
    }
    _progress.userId ??= _firebaseSyncService.userId;
    await _monetizationService.initialize(onEntitlement: _grantEntitlement);
    _billingMessage = _monetizationService.isBillingAvailable
        ? 'Google Play purchases are ready.'
        : 'Purchases will appear after the Play billing products are live on this build.';
    _initialized = true;
    notifyListeners();
    await _persist();
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> claimToday() async {
    _progress.claimToday(DateTime.now());
    await _persist();
  }

  Future<void> signInWithGoogle() async {
    await _firebaseSyncService.signInWithGoogle();
    _localGuestProfile = null;
    _progress.userId = _firebaseSyncService.userId;
    await _persist();
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _firebaseSyncService.signInWithEmail(email, password);
    _localGuestProfile = null;
    _progress.userId = _firebaseSyncService.userId;
    await _persist();
  }

  Future<void> registerWithEmail(String email, String password) async {
    await _firebaseSyncService.registerWithEmail(email, password);
    _localGuestProfile = null;
    _progress.userId = _firebaseSyncService.userId;
    await _persist();
  }

  Future<void> continueAsGuest() async {
    try {
      await _firebaseSyncService.signInAnonymously();
      _localGuestProfile = null;
      _progress.userId = _firebaseSyncService.userId;
    } catch (_) {
      _localGuestProfile = const AuthProfile(
        uid: 'local-guest',
        isAnonymous: true,
        displayName: 'Guest',
      );
      _progress.userId ??= _localGuestProfile!.uid;
    }
    await _persist();
  }

  Future<void> signOut() async {
    await _firebaseSyncService.signOut();
    _localGuestProfile = null;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseSyncService.sendPasswordResetEmail(email);
  }

  Future<void> updateProfile({
    required String displayName,
    required String photoUrl,
  }) async {
    await _firebaseSyncService.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
    );
    notifyListeners();
    await _persist();
  }

  bool isDayUnlocked(int year, int day) {
    return _progress.isDayUnlocked(
      year: year,
      day: day,
      totalDays: AppProgress.totalDaysForYear(year),
    );
  }

  Future<void> markClassicLevelCompleted({
    required int year,
    required int day,
    required ClassicDifficulty difficulty,
  }) async {
    _progress.markDayCompleted(
      year: year,
      day: day,
      difficulty: difficulty,
      seconds: 0,
    );
    _progress.awardPoints(5);
    await _persist();
  }

  Future<bool> buyAdvanceUnlockPack() async {
    final didStart = await _monetizationService.buyProduct(
      MonetizationConfig.advanceUnlockProductId,
    );
    _billingMessage = didStart
        ? 'Google Play purchase opened for 5 extra unlock days.'
        : 'The advance unlock product is not available yet on this build.';
    notifyListeners();
    return didStart;
  }

  Future<bool> buyStreakFreezePack() async {
    final didStart = await _monetizationService.buyProduct(
      MonetizationConfig.streakFreezeProductId,
    );
    _billingMessage = didStart
        ? 'Google Play purchase opened for a streak freeze.'
        : 'The streak freeze product is not available yet on this build.';
    notifyListeners();
    return didStart;
  }

  BannerAd createBannerAd({
    void Function(Ad ad)? onLoaded,
    void Function(LoadAdError error)? onFailed,
  }) {
    return _monetizationService.createBannerAd(
      onLoaded: onLoaded,
      onFailed: onFailed,
    );
  }

  Future<List<ClassicLeaderboardEntry>> fetchClassicLeaderboard({
    required int year,
    required int day,
    required ClassicDifficulty difficulty,
    int limit = 10,
  }) {
    return _firebaseSyncService.fetchClassicLeaderboard(
      year: year,
      day: day,
      difficulty: difficulty,
      limit: limit,
    );
  }

  Future<void> submitClassicLeaderboardEntry({
    required int year,
    required int day,
    required ClassicDifficulty difficulty,
    required int score,
    required int elapsedSeconds,
    required int hintsUsed,
    required int undoCount,
  }) {
    return _firebaseSyncService.submitClassicLeaderboardEntry(
      year: year,
      day: day,
      difficulty: difficulty,
      score: score,
      elapsedSeconds: elapsedSeconds,
      hintsUsed: hintsUsed,
      undoCount: undoCount,
    );
  }

  Future<void> _persist() async {
    _progress.userId ??= _firebaseSyncService.userId ?? _localGuestProfile?.uid;
    await _repository.save(_progress);
    if (_firebaseSyncService.currentProfile != null) {
      await _firebaseSyncService.saveProgress(_progress);
    }
    notifyListeners();
  }

  Future<void> _grantEntitlement(MonetizationEntitlement entitlement) async {
    final token = entitlement.purchaseRecord.purchaseToken;
    if (_progress.hasProcessedPurchaseToken(token)) {
      return;
    }

    switch (entitlement.productId) {
      case MonetizationConfig.advanceUnlockProductId:
        _progress.grantAdvanceUnlockDays(5);
        break;
      case MonetizationConfig.streakFreezeProductId:
        _progress.grantStreakFreezeCredits(1);
        break;
      default:
        break;
    }

    _progress.rememberPurchaseToken(token);
    _billingMessage = 'Purchase applied to your account.';
    await _persist();
    await _firebaseSyncService.savePurchaseRecord(entitlement.purchaseRecord);
  }

  @override
  void dispose() {
    _monetizationService.dispose();
    super.dispose();
  }
}
