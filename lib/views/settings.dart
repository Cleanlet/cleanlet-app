import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final List<FirebaseUIAction> actions;
  const SettingsPage({super.key, this.actions = const []});
  static const _views = [
    {
      'route': '/profile',
      'title': 'User Profile',
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cleanlet Settings'),
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
    );
  }
}
