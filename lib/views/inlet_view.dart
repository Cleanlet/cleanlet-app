
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inlet.dart';
import '../services/firestore_repository.dart';

class InletView extends StatelessWidget {
  const InletView({Key? key, required this.inletId}) : super(key: key);
  final InletID inletId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inlet'),
      ),
      body: Consumer(
          builder: (context, ref, child) {
            final AsyncValue<Inlet>  inletsAsyncValue = ref.watch(inletStreamProvider(inletId));
            if (inletsAsyncValue.value != null) {
              return Column(
                children: [
                  Center(child: Text(inletsAsyncValue.value!.isSubscribed.toString())),
                  Center(child: Text(inletsAsyncValue.value!.subscribed.toString())),
                  (!inletsAsyncValue.value!.isSubscribed) ?
                  Center(child: ElevatedButton(
                      onPressed: () async {
                        inletsAsyncValue.value!.subscribe(ref);
                        // ref.read(databaseProvider).updateInlet(inletsAsyncValue.value!);

                      },
                      child: const Text("Subscribe"))) :
                  Center(child: ElevatedButton(
                      onPressed: () async {
                        inletsAsyncValue.value!.unsubscribe(ref);
                        // ref.read(databaseProvider).updateInlet(inletsAsyncValue.value!);

                      },
                      child: const Text("Unsubscribe"))),
                ],

              );
          } else {
              return Column(
                children: const [
                  Text("hi")
                ],
              );
            }
          }),
    );
  }
}