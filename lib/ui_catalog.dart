import 'package:cleanlet/views/inlet.dart';
import 'package:cleanlet/views/inlet_job.dart';
import 'package:cleanlet/views/login.dart';
import 'package:cleanlet/views/test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide PhoneAuthProvider, EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
  ]);

  if (kDebugMode) {
    try {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  runApp(const CleanletUiCatalog());
}

class CleanletUiCatalog extends StatelessWidget {
  const CleanletUiCatalog({super.key});

  static const _views = [
    {
      'route': '/test',
      'title': 'Test',
      'subtitle': 'This is a subtitle test',
    },
    {'route': '/login', 'title': 'Login'},
    {'route': '/inlet', 'title': 'Inlet'},
    {'route': '/inlet-job', 'title': 'Inlet Job'},
  ];
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cleanlet UI Catalog',
      routes: {
        '/test': (context) => const TestPage(),
        '/login': (context) => const LoginPage(),
        '/inlet': (context) => const InletPage(),
        '/inlet-job': (context) => const InletJobPage(),
      },
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Cleanlet UI  Catalog'),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: _views.length,
                itemBuilder: (BuildContext context, int index) {
                  final title = _views[index]['title'];
                  final subtitle = _views[index]['subtitle'];
                  final route = _views[index]['route'];

                  return Ink(
                    child: ListTile(
                      title: Text(title!),
                      subtitle:
                          subtitle != null ? Text(subtitle.toString()) : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pushNamed(context, route!);
                      },
                    ),
                  );
                },
                separatorBuilder: (BuildContext context, int index) =>
                    const Divider(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
