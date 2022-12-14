import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final List<FirebaseUIAction> actions;

  const LoginPage({super.key, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: SignInScreen(actions: actions),
    );
  }
}