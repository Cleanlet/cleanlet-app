import 'package:cleanlet/utils/async_value_ui.dart';
import 'package:cleanlet/views/job_start.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_launcher/map_launcher.dart';

import '../components/current_inlets_watched.dart';
import '../components/image_carousel.dart';
import '../components/inlet_carousel.dart';
import '../components/inlet_intro.dart';
import '../controllers/inlet_view_controller.dart';
import '../models/inlet.dart';
import '../models/job.dart';
import '../services/firestore_repository.dart';

class InletView extends StatelessWidget {
  InletView({Key? key, required this.inlet}) : super(key: key);
  final Inlet inlet;

  final List<String> instructions = [
    'Upon arrival to the site, take a photo from a point that allows you to see all the debris located on and upgradient of the inlet.',
    'Chalk or otherwise mark the point from which you took the photo so that you can take a post-cleaning photo from exactly the same point.',
    'Use a shovel to remove debris from in and around the inlet. When removing debris that has been deposited on the inlet itself, take care not to push the debris through the gaps in the grate.',
    'Using the shovel, create separate piles for recyclables (e.g. bottles, cans) and soil, leaves, and other organic debris. Using gloves, put the recyclables in one or more bags reserved for that purpose. Shovel the organic debris into a separate set of bags. Do not overfill any bag such that it is difficult to carry (too heavy for one person to carry with one hand).',
    'Place the bags on the sidewalk near the curb.',
    'Take a post-cleaning photo from the same point from which the pre-cleaning photo was taken.',
    'Upload the pre- and post-cleaning photos to the Cleanlet app.',
  ];

  void showInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cleaning Instructions'),
          content: SingleChildScrollView(
            child: ListBody(
              children: instructions.map((instruction) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${instructions.indexOf(instruction) + 1}'),
                  ),
                  title: Text(instruction),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(inlet.nickName),
      ),
      body: SafeArea(
        child: Consumer(builder: (context, ref, child) {
          ref.listen<AsyncValue>(
            inletViewControllerProvider,
            (_, state) => state.showAlertDialogOnError(context),
          );
          final inletAsyncValue = ref.watch(inletStreamProvider(inlet.referenceId));
          return inletAsyncValue.when(
              data: (inlet) {
                return Column(children: <Widget>[
                  InletCarousel(
                    referenceId: inlet.referenceId,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: InletIntro(description: inlet.description, address: inlet.address, coords: Coords(inlet.geoLocation.latitude, inlet.geoLocation.longitude)),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showInstructions(context);
                    },
                    child: Text("Show Cleaning Instructions"),
                  ),
                  const Spacer(),
                  const CurrentInletsWatched(),
                  ShowButton(inlet),
                ]);
              },
              error: (error, stack) => const Text('Error'),
              loading: () => const Text('Loading...'));
        }),
      ),
    );
  }
}

class VolunteerButton extends ConsumerWidget {
  const VolunteerButton(
    this.jobId,
    this.inletId, {
    Key? key,
  }) : super(key: key);
  final String jobId;
  final String inletId;

  @override
  build(BuildContext context, WidgetRef ref) {
    final job = ref.watch(jobStreamProvider(jobId));
    return job.when(
        data: (job) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10.0),
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(inletViewControllerProvider.notifier).inletCleaningSigup(job.referenceId, inletId);
              },
              icon: const Icon(Icons.check_box),
              label: const Text('Volunteer to clean inlet'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
            ),
          );
        },
        error: (error, stack) => const Text('Error'),
        loading: () => const Text('Loading...'));
  }
}

class StartButton extends ConsumerWidget {
  const StartButton(
    this.inlet, {
    Key? key,
  }) : super(key: key);
  final Inlet inlet;

  @override
  build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10.0),
      child: OutlinedButton.icon(
        onPressed: () async {
          await ref.read(inletViewControllerProvider.notifier).startCleaning(inlet.jobId, inlet.referenceId);
        },
        icon: const Icon(Icons.check_box),
        label: const Text('Start Cleaning'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
      ),
    );
  }
}

class ShowButton extends ConsumerWidget {
  const ShowButton(
    this.inlet, {
    Key? key,
  }) : super(key: key);
  final Inlet inlet;
  @override
  build(BuildContext context, WidgetRef ref) {
    String jobId = inlet.jobId;

    if (inlet.status == 'cleaningScheduled' && inlet.isSubscribed) {
      print('status is cleaningScheduled');
      return VolunteerButton(jobId, inlet.referenceId);
    } else if (inlet.status == 'accepted' && inlet.isSubscribed) {
      return StartButton(inlet);
    } else if (inlet.status == 'cleaning' && inlet.isSubscribed) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10.0),
        child: OutlinedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CleaningPhotoView(inlet, 'Before')),
            );
          },
          icon: const Icon(Icons.notification_add),
          label: const Text('Start Cleaning'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
        ),
      );
    } else if (inlet.status == 'cleaning-with-before' && inlet.isSubscribed) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10.0),
        child: OutlinedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CleaningPhotoView(inlet, 'After')),
            );
          },
          icon: const Icon(Icons.notification_add),
          label: const Text('Finished Cleaning'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
        ),
      );
    } else if (inlet.isSubscribed) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10.0),
        child: OutlinedButton.icon(
          onPressed: () async {
            await ref.read(inletViewControllerProvider.notifier).unsubscribeFromInlet(inlet);
          },
          icon: const Icon(Icons.notification_add),
          label: const Text('Unsubscribe'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10.0),
        child: OutlinedButton.icon(
          onPressed: () async {
            await ref.read(inletViewControllerProvider.notifier).subscribeToInlet(inlet);
          },
          icon: const Icon(Icons.notification_add),
          label: const Text('Subscribe for future cleanings'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
        ),
      );
    }
  }
}
