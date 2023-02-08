
import 'package:cleanlet/utils/async_value_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_launcher/map_launcher.dart';

import '../components/image_carousel.dart';
import '../components/inlet_intro.dart';
import '../controllers/inlet_view_controller.dart';
import '../models/inlet.dart';
import '../services/firestore_repository.dart';

class InletView extends StatelessWidget {
  const InletView({Key? key, required this.inlet}) : super(key: key);
  final Inlet inlet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inlet'),
      ),
      body: Consumer(
          builder: (context, ref, child) {
            ref.listen<AsyncValue>(
              inletViewControllerProvider,
                  (_, state) => state.showAlertDialogOnError(context),
            );
            final inletAsyncValue = ref.watch(inletStreamProvider(inlet.referenceId));
            return inletAsyncValue.when(
              data: (inlet) {
                return Column(children: <Widget>[
                  const ImageCarousel(),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    child:  InletIntro(coords: Coords(inlet.geoLocation.latitude, inlet.geoLocation.longitude)),
                  ),
                  const Spacer(),
                  const CurrentInletsWatched(),
                  (inlet.isSubscribed) ?
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: OutlinedButton.icon(onPressed: () async {
                      await ref.read(inletViewControllerProvider.notifier).unsubscribeFromInlet(inlet);
                    }, icon: const Icon(Icons.notification_add), label: const Text('Unsubscribe'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(
                        40)),),
                  ) :
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: OutlinedButton.icon(onPressed: () async {
                      await ref.read(inletViewControllerProvider.notifier).subscribeToInlet(inlet);
                    }, icon: const Icon(Icons.notification_add), label: const Text('Subscribe for future cleanings'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(
                        40)),),
                  )

                ]);

              }, error: (error, stack) => const Text('Error'), loading: () => const Text('Loading...')
            );

          }),
    );
  }
}

class CurrentInletsWatched extends ConsumerWidget {
  const CurrentInletsWatched({
    Key? key,
  }) : super(key: key);


  @override
  build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    return user.when(
      data: (user) {
        return Text('You currently volutneer to clean: ${user.inletsWatched.toString()} inlets');
      }, error: (error, stack) => const Text('Error'), loading: () => const Text('Loading...')
    );
  }
}