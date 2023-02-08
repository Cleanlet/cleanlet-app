import 'package:cleanlet/services/firebase_auth_repository.dart';
import 'package:cleanlet/views/home.dart';
import 'package:cleanlet/views/profile.dart';
import 'package:cleanlet/views/settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide PhoneAuthProvider, EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  FirebaseUIAuth.configureProviders([
  EmailAuthProvider(),
  ]);

  // Pull firebase data from local emulators in dev
  if (kDebugMode) {
    try {
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
      await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  runApp(
      const ProviderScope(
          child: MyApp(),
      )
  );
}

// final inletProvider = Provider((ref) => InletService());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        useMaterial3: true,
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.blueAccent),
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          ),
        ),
      ),
      navigatorObservers: <NavigatorObserver>[observer],
      routes: {
        '/profile': (context) => const ProfilePage(),
        '/settings': (context) => const SettingsPage(),
        '/home': (context) => const AuthGate(),
        // '/inlet': (context) => const InletView(inletId: '',),
      },
      initialRoute: '/home',
      // home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final user = ref.watch(authStateChangesProvider).value;
      if (user == null) {
        return SignInScreen(
          providers: [
            EmailAuthProvider(),
          ],
          headerBuilder: (context, constraints, _) {
            return const Padding(
              padding: EdgeInsets.only(top: 20),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image(image: AssetImage('assets/cleanlet-logo.png')),
              ),
            );
          },
        );
      }

      return const HomePage();
    });
  }
}
