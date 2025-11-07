
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
    apiKey: 'AIzaSyCRj0hErjGRzR--ybc8oTY86Db16YTQTCU',
    appId: '1:300570015281:web:60fbd9b6ea4c8cd84fc710',
    messagingSenderId: '300570015281',
    projectId: 'app1-91396',
    authDomain: 'app1-91396.firebaseapp.com',
    storageBucket: 'app1-91396.firebasestorage.app',
    measurementId: 'G-7QK9L66X5F',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC7Xh7Z1CwkrkqxGGOSwqDx17kKdClN7jw',
    appId: '1:300570015281:android:1617efdd4f5b4c8c4fc710',
    messagingSenderId: '300570015281',
    projectId: 'app1-91396',
    storageBucket: 'app1-91396.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCLNnf41tmwapvD-tHxtiJXrbIDbN3eloU',
    appId: '1:300570015281:ios:5d1b748fecc9223a4fc710',
    messagingSenderId: '300570015281',
    projectId: 'app1-91396',
    storageBucket: 'app1-91396.firebasestorage.app',
    iosBundleId: 'com.example.myapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCLNnf41tmwapvD-tHxtiJXrbIDbN3eloU',
    appId: '1:300570015281:ios:5d1b748fecc9223a4fc710',
    messagingSenderId: '300570015281',
    projectId: 'app1-91396',
    storageBucket: 'app1-91396.firebasestorage.app',
    iosBundleId: 'com.example.myapp',
  );

}