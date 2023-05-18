import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/current_inlets_watched.dart';
import '../models/inlet.dart';
import '../services/firestore_repository.dart';
import '../services/geolocation.dart';
import 'inlet_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  List<Marker> mapMarkers = [];

  Future<bool> checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seen = (prefs.getBool('seen') ?? false);

    if (!seen) {
      await prefs.setBool('seen', true);
      print('not seen yet');
      return true; // return true when the dialog needs to be shown
    }
    print('seen');
    return false; // return false when the dialog doesn't need to be shown
  }

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

  Future<void> saveTokenToDatabase(String token) async {
    // Assume user is logged in for this example
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'tokens': FieldValue.arrayUnion([token]),
    });
  }

  Future<void> setupToken() async {
    // Get the token each time the application loads
    String? token = await FirebaseMessaging.instance.getToken();

    // Save the initial token to the database
    await saveTokenToDatabase(token!);

    // Any time the token refreshes, store this in the database too.
    FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToDatabase);
  }

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
    registerNotification();
    setupToken();
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
      bottomNavigationBar: const BottomAppBar(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CurrentInletsWatched(),
        ),
      ),
      body: Consumer(builder: (context, ref, child) {
        final position = ref.watch(positionProvider);
        final List<Marker> mapMarkers = [];
        return position.when(
            data: (currentPosition) {
              final inletsAsyncValue = ref.watch(inletsStreamProvider);
              if (inletsAsyncValue.value != null) {
                mapMarkers.addAll(inletsAsyncValue.value!
                    .map((inlet) => Marker(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        InletView(inlet: inlet)));
                          },
                          markerId: MarkerId(inlet.referenceId),
                          position: LatLng(inlet.geoLocation.latitude,
                              inlet.geoLocation.longitude),
                        ))
                    .toList());
              }
              return SizedBox(
                child: GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                      target: LatLng(
                          currentPosition.latitude, currentPosition.longitude),
                      zoom: 19),
                  onMapCreated: (GoogleMapController controller) async {
                    _controller.complete(controller);
                    if (await checkFirstSeen()) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Hello World'),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      });
                    }
                  },

                  markers: mapMarkers.toSet(),
                  // zoomControlsEnabled: false,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
              );
            },
            error: (error, stack) => Text('Error: ${error.toString()}'),
            loading: () => const Text('Loading...'));
      }),
    );
  }
}
