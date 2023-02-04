
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
            final  inletsAsyncValue = ref.watch(inletStreamProvider(inletId));
            if (inletsAsyncValue.value != null) {
              return Center(child: Text(inletsAsyncValue.value!.referenceId));
          } else {
              return Text("hi");
            }
          }),
    );
  }
}