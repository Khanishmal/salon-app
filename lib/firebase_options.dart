//lib/firebase_option.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC924Jt4F_CAqQQt1M0GxpWuFE86TkbLsk',
    appId: '1:318949552806:web:692c4f5455ce23d5b43a67',
    messagingSenderId: '318949552806',
    projectId: 'salon-assistant-pro',
    authDomain: 'salon-assistant-pro.firebaseapp.com',
    storageBucket: 'salon-assistant-pro.firebasestorage.app',
    measurementId: 'G-ZKEYPMC7MR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDk5leNgHHwjwS1KCjl26H3sBIIZ_lTCpI',
    appId: '1:318949552806:android:14830bd7c606d0e6b43a67',
    messagingSenderId: '318949552806',
    projectId: 'salon-assistant-pro',
    storageBucket: 'salon-assistant-pro.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBRgd-CjdebnS_o5ec5PrJOU7pXQFedhYg',
    appId: '1:318949552806:ios:80ba91d40e73806ab43a67',
    messagingSenderId: '318949552806',
    projectId: 'salon-assistant-pro',
    storageBucket: 'salon-assistant-pro.firebasestorage.app',
    iosBundleId: 'com.example.salonAssistantPro',
    iosClientId: '318949552806-v8jv9v3p5v6v7v8v9v0v1v2v3v4v5v6v7v8.apps.googleusercontent.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBRgd-CjdebnS_o5ec5PrJOU7pXQFedhYg',
    appId: '1:318949552806:ios:80ba91d40e73806ab43a67',
    messagingSenderId: '318949552806',
    projectId: 'salon-assistant-pro',
    storageBucket: 'salon-assistant-pro.firebasestorage.app',
    iosBundleId: 'com.example.salonAssistantPro',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC924Jt4F_CAqQQt1M0GxpWuFE86TkbLsk',
    appId: '1:318949552806:web:448bc8ee13d70932b43a67',
    messagingSenderId: '318949552806',
    projectId: 'salon-assistant-pro',
    authDomain: 'salon-assistant-pro.firebaseapp.com',
    storageBucket: 'salon-assistant-pro.firebasestorage.app',
    measurementId: 'G-KWE1QGKRTQ',
  );
}