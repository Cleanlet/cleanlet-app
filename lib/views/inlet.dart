import 'package:flutter/material.dart';

import '../components/image_carousel.dart';
import '../components/inlet_intro.dart';

class InletPage extends StatefulWidget {
  const InletPage({super.key});

  @override
  State<InletPage> createState() => _InletPageState();
}

class _InletPageState extends State<InletPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inlet Page'),
      ),
      body: Column(children: <Widget>[
        const ImageCarousel(),
        const SizedBox(
          height: 20,
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20.0),
          child: const InletIntro(),
        ),
        const Spacer(),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.notification_add),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(
                  40), // fromHeight use double.infinity as width and 40 is the height
            ),
            label: const Text('Subscribe for future cleanings'),
            onPressed: () {},
          ),
        ),
      ]),
    );
  }
}
