import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static String get _projectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get _messagingSenderId => dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get _storageBucket => dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_WEB'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID_WEB'] ?? '',
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: '$_projectId.firebaseapp.com',
        storageBucket: _storageBucket,
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_ANDROID'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID_ANDROID'] ?? '',
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_IOS'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID_IOS'] ?? '',
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
        iosBundleId: 'com.example.msg',
      );

  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_MACOS'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID_MACOS'] ?? '',
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
        iosBundleId: 'com.example.msg',
      );

  static FirebaseOptions get windows => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_WINDOWS'] ?? '',
        appId: dotenv.env['FIREBASE_APP_ID_WINDOWS'] ?? '',
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
      );

  static FirebaseOptions get linux => FirebaseOptions(
        apiKey: (dotenv.env['FIREBASE_API_KEY_LINUX']?.isNotEmpty ?? false)
            ? dotenv.env['FIREBASE_API_KEY_LINUX']!
            : (dotenv.env['FIREBASE_API_KEY_WEB']?.isNotEmpty ?? false)
                ? dotenv.env['FIREBASE_API_KEY_WEB']!
                : (dotenv.env['FIREBASE_API_KEY_ANDROID'] ?? ''),
        appId: (dotenv.env['FIREBASE_APP_ID_LINUX']?.isNotEmpty ?? false)
            ? dotenv.env['FIREBASE_APP_ID_LINUX']!
            : (dotenv.env['FIREBASE_APP_ID_WEB']?.isNotEmpty ?? false)
                ? dotenv.env['FIREBASE_APP_ID_WEB']!
                : (dotenv.env['FIREBASE_APP_ID_ANDROID'] ?? ''),
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
      );
}
