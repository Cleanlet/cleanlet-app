import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/firestore_repository.dart';

class CurrentInletsWatched extends ConsumerWidget {
  const CurrentInletsWatched({
    Key? key,
  }) : super(key: key);

  @override
  build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    return user.when(
        data: (user) {
          return Text(
              'You currently volutneer to clean: ${user.inletsWatched.toString()} inlets');
        },
        error: (error, stack) => const Text("error"),
        loading: () => const Text('Loading...'));
  }
}
