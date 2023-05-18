import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';

class InletIntro extends StatelessWidget {
  final Coords coords;
  const InletIntro({
    Key? key,
    required this.coords,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: <Widget>[
            const Icon(
              Icons.location_on,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(
              width: 10,
            ),
            Flexible(
              child: GestureDetector(
                onTap: () async {
                  final availableMaps = await MapLauncher
                      .installedMaps; // [AvailableMap { mapName: Google Maps, mapType: google }, ...]
                  await availableMaps.first.showDirections(
                    destination: coords,
                    destinationTitle: "Inlet Location",
                  );
                },
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('1234 Example Street Philadelphia PA 19106',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 5,
                    ),
                    Text('Click to view map', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.description,
              color: Colors.green,
              size: 24,
            ),
            SizedBox(
              width: 10,
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Inlet Description',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                      style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
