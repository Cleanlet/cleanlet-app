import 'package:cleanlet/services/firebase_auth_repository.dart';
import 'package:cleanlet/views/add_inlet.dart';
import 'package:cleanlet/views/home.dart';
import 'package:cleanlet/views/profile.dart';
import 'package:cleanlet/views/settings.dart';
import 'package:cleanlet/views/terms_and_conditions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide PhoneAuthProvider, EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/user.dart';
import 'services/firestore_repository.dart';

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
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  // This widget is the root of your application.

  Future<ColorScheme>? imageColorSchemeFuture;

  static const ColorScheme customColorScheme = ColorScheme(
    primary: Color(0xff006780),
    primaryVariant: Color(0xff006780),
    secondary: Color(0xff4c626b),
    secondaryVariant: Color(0xff4c626b),
    surface: Color(0xfffbfcfe),
    background: Color(0xfffbfcfe),
    error: Color(0xffba1a1a),
    onPrimary: Color(0xffffffff),
    onSecondary: Color(0xffffffff),
    onSurface: Color(0xff191c1d),
    onBackground: Color(0xff191c1d),
    onError: Color(0xffffffff),
    brightness: Brightness.light,
  );

  @override
  void initState() {
    super.initState();
    imageColorSchemeFuture = ColorScheme.fromImageProvider(
      provider: const AssetImage('assets/cleanlet-icon.png'),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(autoUpdateUserListenerProvider);

    // Auto-update the user data in Firestore when the user's Firebase authentication data changes
    return FutureBuilder<ColorScheme>(
        future: imageColorSchemeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(); // Show loading indicator while waiting
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}'); // Handle error case
          } else {
            ColorScheme? colorScheme =
                snapshot.data; // Assume that this is your ColorScheme object

// Now you can use the map to export the color values.
// For instance, printing them to the console:
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
                // primarySwatch: Colors.blue,
                colorScheme: customColorScheme,
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        customColorScheme.primary),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                  ),
                ),
                // outlinedButtonTheme: OutlinedButtonThemeData(
                //   style: OutlinedButton.styleFrom(
                //     primary: customColorScheme.onPrimary,  // The color of the text
                //     onSurface: customColorScheme.surface,  // The color of the button's border
                //     backgroundColor: customColorScheme.primary,  // The color of the button's background
                //   ),
                // ),
              ),
              navigatorObservers: <NavigatorObserver>[MyApp.observer],
              routes: {
                '/profile': (context) => const ProfilePage(),
                '/settings': (context) => SettingsPage(
                      items: [
                        SettingsItem(
                          title: 'Profile',
                          icon: Icons.person,
                          action: (context) {
                            Navigator.pushNamed(context, '/profile');
                          },
                        ),
                        SettingsItem(
                          title: 'Terms & Conditions',
                          icon: Icons.link,
                          action: (context) async {
                            final url = Uri.parse(
                                'https://cleanletapp.cae.drexel.edu/privacy-policy/');
                            await _launchUrl(url);
                          },
                        ),
                        SettingsItem(
                          title: 'FAQs',
                          icon: Icons.link,
                          action: (context) async {
                            final url = Uri.parse(
                                'https://cleanletapp.cae.drexel.edu/');
                            await _launchUrl(url);
                          },
                        ),
                        SettingsItem(
                          title: 'Add an Inlet',
                          icon: Icons.add,
                          action: (context) async {
                            final url = Uri.parse(
                                'https://docs.google.com/forms/d/e/1FAIpQLSe4ISFYoUAdZ93AZw14SBwfqHoH4ShKLfVVXKKhCz-3ibXZjQ/viewform');
                            await _launchUrl(url);
                          },
                        ),
                        SettingsItem(
                          title: 'Submit Feedback',
                          icon: Icons.email,
                          action: (context) async {
                            final email = Uri(
                              scheme: 'mailto',
                              path: 'casdrexel@gmail.com',
                            );
                            await _launchUrl(email);
                          },
                        ),
                      ],
                    ),
                '/home': (context) => const AuthGate(),
                '/add-inlet': (context) => AddInletPage(),
                '/terms': (context) => TermsAndConditionsPage(),
                // '/inlet': (context) => const InletView(inletId: '',),
              },
              initialRoute: '/home',
              // home: const AuthGate(),
            );
          }
        });
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

Future<void> _launchUrl(Uri uri) async {
  if (!await canLaunch(uri.toString())) {
    throw Exception('Could not launch $uri');
  } else {
    await launch(uri.toString());
  }
}
