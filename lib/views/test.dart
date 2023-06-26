import 'package:flutter/material.dart';

import '../models/inlet.dart';
import 'job_start.dart';

class TestPage extends StatelessWidget {
  final Inlet inlet;
  const TestPage(this.inlet, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean the inlet'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: CleanupInstructions()),
            // const Spacer(),
            ElevatedButton.icon(
                onPressed: () async => {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  CleaningPhotoView(inlet, 'After')))
                    },
                icon: const Icon(Icons.check),
                label: const Text("I finished Cleaning the inlet"),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40)))
          ],
        ),
      ),
    );
  }
}

class CleanupInstructions extends StatelessWidget {
  final List<String> instructions = [
    'Upon arrival to the site, take a photo from a point that allows you to see all the debris located on and upgradient of the inlet.',
    'Chalk or otherwise mark the point from which you took the photo so that you can take a post-cleaning photo from exactly the same point.',
    'Use a shovel to remove debris from in and around the inlet. When removing debris that has been deposited on the inlet itself, take care not to push the debris through the gaps in the grate.',
    'Using the shovel, create separate piles for recyclables (e.g. bottles, cans) and soil, leaves, and other organic debris. Using gloves, put the recyclables in one or more bags reserved for that purpose. Shovel the organic debris into a separate set of bags. Do not overfill any bag such that it is difficult to carry (too heavy for one person to carry with one hand).',
    'Place the bags on the sidewalk near the curb.',
    'Take a post-cleaning photo from the same point from which the pre-cleaning photo was taken.',
    'Upload the pre- and post-cleaning photos to the Cleanlet app.',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: instructions.length,
      separatorBuilder: (context, index) => Divider(),
      itemBuilder: (context, index) {
        return ListTile(
          leading: Text(
            '${index + 1}.',
            style: const TextStyle(fontSize: 14), // Adjust the font size here
          ),
          title: Text(
            instructions[index],
            style: const TextStyle(fontSize: 16), // Adjust the font size here
          ),
        );
      },
    );
  }
}
