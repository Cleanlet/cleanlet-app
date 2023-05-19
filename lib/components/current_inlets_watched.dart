import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_repository.dart';

class CurrentInletsWatched extends ConsumerWidget {
  const CurrentInletsWatched({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    return user.when(
      data: (user) {
        final int inletsWatched = user.inletsWatched;
        final String inletsText = inletsWatched == 1 ? 'inlet' : 'inlets';

        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Text(
            'You currently volunteer to clean: $inletsWatched $inletsText',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
            textScaleFactor: 1.1,
          ),
        );
      },
      error: (error, stack) => const Text("error"),
      loading: () => const Text('Loading...'),
    );
  }
}
