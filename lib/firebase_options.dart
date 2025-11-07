
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBtJIwQoK9k791_yDAiSglhmLpNgvv09yE',
    appId: '1:1055692472831:web:f43ad15d9c1b588c8d27ca',
    messagingSenderId: '1055692472831',
    projectId: 'myapp-be713',
    authDomain: 'myapp-be713.firebaseapp.com',
    storageBucket: 'myapp-be713.firebasestorage.app',
    measurementId: 'G-GPPMFVP53Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDq1y-4IJMniCy3250iL9z-SqXBuNxDrCE',
    appId: '1:1055692472831:android:236cbbb43bcd664c8d27ca',
    messagingSenderId: '1055692472831',
    projectId: 'myapp-be713',
    storageBucket: 'myapp-be713.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAryYkRXLudwsEtIsCBD28wo9-jkSQUWTw',
    appId: '1:1055692472831:ios:02626fdaa3578c1b8d27ca',
    messagingSenderId: '1055692472831',
    projectId: 'myapp-be713',
    storageBucket: 'myapp-be713.firebasestorage.app',
    iosBundleId: 'com.example.myapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAryYkRXLudwsEtIsCBD28wo9-jkSQUWTw',
    appId: '1:1055692472831:ios:02626fdaa3578c1b8d27ca',
    messagingSenderId: '1055692472831',
    projectId: 'myapp-be713',
    storageBucket: 'myapp-be713.firebasestorage.app',
    iosBundleId: 'com.example.myapp',
  );
}
