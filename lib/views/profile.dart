import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final List<FirebaseUIAction> actions;
  const ProfilePage({super.key, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
      ),
      body: ProfileScreen(actions: actions),
    );
  }
}
