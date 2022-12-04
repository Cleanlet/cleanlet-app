import 'package:cleanlet/components/cleanup_steps.dart';
import 'package:cleanlet/views/test.dart';
import 'package:flutter/material.dart';

import '../components/image_carousel.dart';
import '../components/inlet_intro.dart';
import 'job_start.dart';

class InletJobPage extends StatefulWidget {
  const InletJobPage({super.key});

  @override
  State<InletJobPage> createState() => _InletJobPageState();
}

class _InletJobPageState extends State<InletJobPage> {
  static const _views = [
    {
      'widget': JobStartPage(),
      'title': 'Take before picture of drain',
    },
    {
      'widget': JobStartPage(),
      'title': 'Clean the drain',
    },
    {
      'widget': JobStartPage(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inlet Job Page'),
      ),
      body: Column(children: <Widget>[
        const ImageCarousel(),
        const SizedBox(
          height: 20,
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              InletIntro(),
              SizedBox(
                height: 20,
              ),
              CleanupSteps()
            ],
          ),
        ),
        const Spacer(),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(
                  40), // fromHeight use double.infinity as width and 40 is the height
            ),
            label: const Text('I finished cleaning the drain'),
            onPressed: () {
              const snackBar = SnackBar(
                content: Text('Thank you for helping clean the drain!'),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            },
          ),
        ),
      ]),
    );
  }
}
