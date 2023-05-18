import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class GeolocationService {
  Future<Position> _determineCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw ("ServiceError");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw ("DeniedPermissionError");
      }
    } else if (permission == LocationPermission.whileInUse) {
      if (Platform.isAndroid) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw ("DeniedPermissionError");
        }
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return position;
  }
}



final locationProvider = Provider<GeolocationService>((ref) {
  return GeolocationService();
});

final positionProvider = FutureProvider.autoDispose<Position>((ref) async {
  return ref.watch(locationProvider)._determineCurrentPosition();
});