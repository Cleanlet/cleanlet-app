import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';

class InletIntro extends StatelessWidget {
  final Coords coords;
  final String description;
  final String address;

  const InletIntro({Key? key, required this.coords, required this.description, required this.address}) : super(key: key);

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
                  final availableMaps = await MapLauncher.installedMaps; // [AvailableMap { mapName: Google Maps, mapType: google }, ...]
                  await availableMaps.first.showDirections(
                    destination: coords,
                    destinationTitle: "Inlet Location",
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(address, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        Row(
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
                  Text('Inlet Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(
                    height: 5,
                  ),
                  Text(description, style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
