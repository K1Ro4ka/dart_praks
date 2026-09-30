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
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBWVfJPexrJQIKr5r4qvpZzUzeVgapb-vs',
    appId: '1:1041212696439:web:5fbd49d1f87817d6726372',
    messagingSenderId: '1041212696439',
    projectId: 'promobilki-bc8ed',
    authDomain: 'promobilki-bc8ed.firebaseapp.com',
    storageBucket: 'promobilki-bc8ed.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAWLy-tiA2FqwRH12ZOTeOvrzoQo0JeH9U',
    appId: '1:1041212696439:android:731e6f281d88953f726372',
    messagingSenderId: '1041212696439',
    projectId: 'promobilki-bc8ed',
    storageBucket: 'promobilki-bc8ed.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDIvEVlKsa0rlozQP86SzNmLFomJbpgRyA',
    appId: '1:1041212696439:ios:13a29e954c8029aa726372',
    messagingSenderId: '1041212696439',
    projectId: 'promobilki-bc8ed',
    storageBucket: 'promobilki-bc8ed.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );
}