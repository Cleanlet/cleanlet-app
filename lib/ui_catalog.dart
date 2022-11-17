import 'package:cleanlet/views/login.dart';
import 'package:cleanlet/views/test.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CleanletUiCatalog());
}

class CleanletUiCatalog extends StatelessWidget {
  const CleanletUiCatalog({super.key});
  static const _views = [
    {
      'route': '/test',
      'title': 'Test'
    },
    {
      'route': '/login',
      'title': 'Login'
    }
  ];
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cleanlet UI Catalog',
      routes: {
        '/test': (context) => const TestPage(),
        '/login': (context) => const LoginPage(),
      },
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Cleanlet UI Catalog'),
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
                    color: Theme.of(context).cardColor,
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
