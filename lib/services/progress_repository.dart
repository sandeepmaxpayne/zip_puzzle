import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_progress.dart';

class ProgressRepository {
  static const _storageKey = 'zip_puzzle_progress_v1';

  Future<AppProgress> load() async {
    final preferences = await SharedPreferences.getInstance();
    final source = preferences.getString(_storageKey);
    if (source == null || source.isEmpty) {
      return AppProgress.initial();
    }

    try {
      return AppProgress.fromStorageString(source);
    } catch (_) {
      return AppProgress.initial();
    }
  }

  Future<void> save(AppProgress progress) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, progress.toStorageString());
  }
}
