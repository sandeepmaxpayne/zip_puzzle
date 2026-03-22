import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase Web is not configured yet. Add the real web Firebase config to enable cloud auth on web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Firebase iOS is not configured yet. Add the real GoogleService-Info.plist to enable cloud auth on iOS.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'Firebase macOS is not configured yet. Add the real macOS Firebase config to enable cloud auth on macOS.',
        );
      default:
        throw UnsupportedError(
          'Firebase options are not configured for this platform yet.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBYbA6jfh2JL4UZvsUcMl9rXNdAzFuRQpY',
    appId: '1:343650775749:android:79e0a22147c99eb1fab6ac',
    messagingSenderId: '343650775749',
    projectId: 'zip-puzzle-f8120',
    storageBucket: 'zip-puzzle-f8120.firebasestorage.app',
  );
}
