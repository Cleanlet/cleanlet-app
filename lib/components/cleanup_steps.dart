import 'package:flutter/material.dart';
import '../views/job_start.dart';
import '../views/test.dart';

class CleanupSteps extends StatelessWidget {
  const CleanupSteps({
    Key? key,
  }) : super(key: key);
  static const _views = [
    {
      'title': 'Take before picture of drain',
    },
    {
      'title': 'Clean the drain',
    },
    {
      'title': 'Take an after picture of the drain',
    }
  ];
  static const List<Widget> _viewLinks = [
    JobStartPage(),
    TestPage(),
    JobStartPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Steps to clean this storm drain',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ListView.separated(
          shrinkWrap: true,
          itemCount: _views.length,
          itemBuilder: (BuildContext context, int index) {
            final title = _views[index]['title'];
            final route = _views[index]['widget'];

            return Ink(
              child: ListTile(
                title: Text(title.toString()),
                leading: Text('${index + 1}.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => _viewLinks[index],
                    ),
                  );
                },
              ),
            );
          },
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(),
        ),
      ],
    );
  }
}
