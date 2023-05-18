import 'package:cleanlet/utils/async_value_ui.dart';
import 'package:cleanlet/views/job_start.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_launcher/map_launcher.dart';

import '../components/current_inlets_watched.dart';
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
      body: SafeArea(
        child: Consumer(builder: (context, ref, child) {
          ref.listen<AsyncValue>(
            inletViewControllerProvider,
            (_, state) => state.showAlertDialogOnError(context),
          );
          final inletAsyncValue =
              ref.watch(inletStreamProvider(inlet.referenceId));
          return inletAsyncValue.when(
              data: (inlet) {
                return Column(children: <Widget>[
                  const ImageCarousel(),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: InletIntro(
                        coords: Coords(inlet.geoLocation.latitude,
                            inlet.geoLocation.longitude)),
                  ),
                  const SizedBox(
                    height: 20,
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
                ref
                    .read(inletViewControllerProvider.notifier)
                    .inletCleaningSigup(job.referenceId, inletId);
              },
              icon: const Icon(Icons.check_box),
              label: const Text('Volunteer to clean inlet'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40)),
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
          await ref
              .read(inletViewControllerProvider.notifier)
              .startCleaning(inlet.jobId, inlet.referenceId);
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
    if (inlet.status == 'cleaningScheduled') {
      return VolunteerButton(jobId, inlet.referenceId);
    } else if (inlet.status == 'accepted') {
      return StartButton(inlet);
    } else if (inlet.status == 'cleaning') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10.0),
        child: OutlinedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CleaningPhotoView(inlet, 'Before')),
            );
          },
          icon: const Icon(Icons.notification_add),
          label: const Text('Start Cleaning'),
          style:
              OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
        ),
      );
    } else if (inlet.isSubscribed) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10.0),
        child: OutlinedButton.icon(
          onPressed: () async {
            await ref
                .read(inletViewControllerProvider.notifier)
                .unsubscribeFromInlet(inlet);
          },
          icon: const Icon(Icons.notification_add),
          label: const Text('Unsubscribe'),
          style:
              OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 10.0),
        child: OutlinedButton.icon(
          onPressed: () async {
            await ref
                .read(inletViewControllerProvider.notifier)
                .subscribeToInlet(inlet);
          },
          icon: const Icon(Icons.notification_add),
          label: const Text('Subscribe for future cleanings'),
          style:
              OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
        ),
      );
    }
  }
}
