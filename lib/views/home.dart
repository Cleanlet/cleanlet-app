import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/inlet.dart';
import '../services/firestore_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  List<Marker> mapMarkers = [];

  void registerNotification() async {
    // 3. On iOS, this helps to take the user permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(message.notification!.title!),
              content: Text(message.notification!.body!),
              actions: [
                TextButton(
                  child: const Text("Ok"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            );
          });

      if (message.notification != null) {
        if (kDebugMode) {
          print(
              'Message also contained a notification: ${message.notification}');
        }
      }
    });

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }
      // TODO: handle the received notifications
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted permission');
      }
    }
  }

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    registerNotification();
  }

  Future<CameraPosition> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position currentPosition = await Geolocator.getCurrentPosition();
    // await updateMapMarkers(inlets);
    return CameraPosition(
        target: LatLng(currentPosition.latitude, currentPosition.longitude),
        zoom: 19);
  }

  Future<void> updateMapMarkers(List<Inlet> inlets) async {
    mapMarkers = inlets
        .map((inlet) => Marker(
            markerId: MarkerId(inlet.referenceId),
            position:
                LatLng(inlet.geoLocation.latitude, inlet.geoLocation.longitude),
            infoWindow: InfoWindow(
              title: inlet.niceName,
              snippet: inlet.referenceId,
            )))
        .toList();

    setState(() {
      mapMarkers = mapMarkers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cleanlet'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              icon: const Icon(Icons.menu_rounded))
        ],
      ),
      body: Consumer(
          builder: (context, ref, child) {
            final  inletsAsyncValue = ref.watch(inletsStreamProvider);
            final List<Marker> mapMarkers = [];
            if (inletsAsyncValue.value != null) {

              mapMarkers.addAll(inletsAsyncValue.value!
                  .map((inlet) => Marker(
                      markerId: MarkerId(inlet.referenceId),
                      position: LatLng(inlet.geoLocation.latitude,
                          inlet.geoLocation.longitude),
                      infoWindow: InfoWindow(
                        title: inlet.niceName,
                        snippet: inlet.referenceId,
                        // onTap: () {
                        //   Navigator.pushNamed(context, '/inlet',
                        //       arguments: inlet.referenceId);
                        // }
                      )))
                  .toList());
            }

            return FutureBuilder<CameraPosition>(
                future: _determinePosition(),
                builder: (BuildContext context, AsyncSnapshot<dynamic> snap) {
                  if (snap.hasData) {
                    final CameraPosition position = snap.data;
                    return SizedBox(
                      // width: MediaQuery.of(context).size.width,
                      // height: 350,
                      child: GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: position,
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                        markers: mapMarkers.toSet(),
                        // zoomControlsEnabled: false,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                      ),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                });
          }),
    );
  }
}
