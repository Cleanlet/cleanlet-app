import 'package:flutter/material.dart';

import '../models/inlet.dart';
import 'job_start.dart';

class TestPage extends StatelessWidget {
  final Inlet inlet;
  const TestPage(this.inlet, {super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text('Clean the inlet'),
      ),
      body: Column(
        children: [
          Center(
            child: Text('This is the cleaning page for inlet ${inlet.jobId}'),
          ),
          const Center(
            child: Text('Cleaning Instructions Here'),
          ),
          const Spacer(),
          ElevatedButton.icon(
              onPressed: () async  => {
                Navigator.push(context, MaterialPageRoute(builder: (context) =>  CleaningPhotoView(inlet, 'After')))
              },
              icon: const Icon(Icons.check),
              label: const Text("I finished Cleaning the inlet"),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40))
          )
        ],
      ),
    );
  }
}