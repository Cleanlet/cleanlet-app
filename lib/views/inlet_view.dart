
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_launcher/map_launcher.dart';

import '../components/image_carousel.dart';
import '../components/inlet_intro.dart';
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
            final AsyncValue<Inlet>  inlet = ref.watch(inletStreamProvider(inletId));
            if (inlet.value != null) {
              return Column(children: <Widget>[
                const ImageCarousel(),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20.0),
                  child:  InletIntro(coords: Coords(inlet.value!.geoLocation.latitude, inlet.value!.geoLocation.longitude)),
                ),
                const Spacer(),
                (inlet.value!.isSubscribed) ?
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: OutlinedButton.icon(onPressed: () {
                    inlet.value!.unsubscribe(ref);
                  }, icon: const Icon(Icons.notification_add), label: const Text('Unsubscribe'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(
                      40)),),
                ) :
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: OutlinedButton.icon(onPressed: () {
                    inlet.value!.subscribe(ref);
                  }, icon: const Icon(Icons.notification_add), label: const Text('Subscribe for future cleanings'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(
                      40)),),
                )

              ]);
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