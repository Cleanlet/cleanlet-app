import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  final List<SettingsItem> items;

  const SettingsPage({Key? key, required this.items}) : super(key: key);

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
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  leading: Icon(items[index].icon),
                  title: Text(items[index].title),
                  onTap: () {
                    items[index].action(context);
                  },
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

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SettingsPage(
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
              final url = 'https://cleanletapp.cae.drexel.edu/privacy-policy/';
              if (await canLaunch(url)) {
                await launch(url);
              }
            },
          ),
          SettingsItem(
            title: 'FAQs',
            icon: Icons.link,
            action: (context) async {
              final url = 'https://cleanletapp.cae.drexel.edu/';
              if (await canLaunch(url)) {
                await launch(url);
              }
            },
          ),
          SettingsItem(
            title: 'Add an Inlet',
            icon: Icons.add,
            action: (context) async {
              final url =
                  'https://docs.google.com/forms/d/e/1FAIpQLSe4ISFYoUAdZ93AZw14SBwfqHoH4ShKLfVVXKKhCz-3ibXZjQ/viewform';
              if (await canLaunch(url)) {
                await launch(url);
              }
            },
          ),
          SettingsItem(
            title: 'Submit Feedback',
            icon: Icons.email,
            action: (context) async {
              const email = 'mailto:casdrexel@gmail.com';
              if (await canLaunch(email)) {
                await launch(email);
              }
            },
          ),
        ],
      ),
    );
  }
}

class SettingsItem {
  final String title;
  final IconData icon;
  final Function(BuildContext context) action;

  SettingsItem({
    required this.title,
    required this.icon,
    required this.action,
  });
}
