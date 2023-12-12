import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';

import '../components/current_inlets_watched.dart';
import '../models/inlet.dart';
import '../services/firestore_repository.dart';
import '../services/geolocation.dart';
import '../components/carousel_modal_widget.dart';
import 'inlet_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  List<Marker> mapMarkers = [];
  final List<String> messages = ["Hi and welcome to Cleanlet! Thank you for supporting this project! Here's a few things that you should know:", "Be safe: Always follow the cleaning guidelines an clean only when it feels safe to you. You can find the guidelines in the (?) section of the app", "Feel free to let us know of any bugs or feedbacks using the buttin in the top right menu", "Read the instructions on how to use the app in the (?) section"];

  Future<bool> checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seen = (prefs.getBool('seen') ?? false);

    if (!seen) {
      await prefs.setBool('seen', true);
      return true; // return true when the dialog needs to be shown
    }
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
          print('Message also contained a notification: ${message.notification}');
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

  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

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
            position: LatLng(inlet.geoLocation.latitude, inlet.geoLocation.longitude),
            infoWindow: InfoWindow(
              title: inlet.nickName,
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
        title: Consumer(
          builder: (context, ref, child) {
            final user = ref.watch(userProvider);
            return user.when(
                data: (user) {
                  // create a string to display the user's name or email address display email if user's display name is null or blank
                  String textToDisplay = (user.displayName != null && user.displayName!.isNotEmpty) ? user.displayName! : user.email;

                  return Text(textToDisplay);
                },
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => const Text('Error'));
          },
        ),
        leading: Consumer(
          builder: (context, ref, child) {
            final user = ref.watch(userProvider);
            return user.when(
                data: (user) {
                  // if user has a photoURL, display it in a CircleAvatar else display a generic person icon
                  return user.photoURL != null
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(user.photoURL!),
                          ),
                        )
                      : const Icon(Icons.person);
                },
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => const Text('Error'));
          },
        ),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/inletSearch');
              },
              icon: const Icon(
                Icons.help_outline_rounded,
                color: Colors.white,
              )),
          IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              icon: const Icon(Icons.menu_rounded))
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        //set color to the theme's primary color
        color: Theme.of(context).colorScheme.primary,
        //center text
        child: const Padding(
          padding: EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CurrentInletsWatched(),
              // question mark icon button make it white
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer(builder: (context, ref, child) {
          final position = ref.watch(positionProvider);
          final List<Marker> mapMarkers = [];
          return position.when(
              data: (currentPosition) {
                final inletsAsyncValue = ref.watch(inletsStreamProvider);
                if (inletsAsyncValue.value != null) {
                  mapMarkers.addAll(inletsAsyncValue.value!
                      .map((inlet) => Marker(
                            onTap: () {
                              print(inlet.referenceId);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => InletView(inlet: inlet)));
                            },
                            markerId: MarkerId(inlet.referenceId),
                            position: LatLng(inlet.geoLocation.latitude, inlet.geoLocation.longitude),
                          ))
                      .toList());
                }
                return SizedBox(
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(target: LatLng(currentPosition.latitude, currentPosition.longitude), zoom: 19),
                    onMapCreated: (GoogleMapController controller) async {
                      _controller.complete(controller);

                      if (await checkFirstSeen()) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          // showCarouselModal(context); // Call the function to show the carousel modal

                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return CarouselModalWidget(messages: messages);
                              });
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
      ),
    );
  }
}
