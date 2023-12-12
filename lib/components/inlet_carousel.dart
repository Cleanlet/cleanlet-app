import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class InletCarousel extends StatelessWidget {
  final String referenceId;

  const InletCarousel({
    Key? key,
    required this.referenceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: getImageUrlsFromFirestore(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text('No images available.');
        } else {
          final imageUrls = snapshot.data!;

          return FlutterCarousel(
            options: CarouselOptions(
              height: 200,
              showIndicator: true,
              slideIndicator: const CircularSlideIndicator(),
              enableInfiniteScroll: true,
            ),
            items: imageUrls.map((imageUrl) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    height: 100,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(imageUrl),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        }
      },
    );
  }

  Future<List<String>> getImageUrlsFromFirestore() async {
    try {
      final DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('inlets') // Replace with your Firestore collection name
          .doc(referenceId) // Use the referenceId as the document ID
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('images')) {
          final List<dynamic> imageList = data['images'] as List<dynamic>;

          final List<String> imageUrls = await Future.wait(
            imageList.map((image) async {
              final String imageFileName = image.toString();
              final String imageUrl = await FirebaseStorage.instance.ref('inlet-photos/$imageFileName').getDownloadURL();
              return imageUrl;
            }),
          );
          return imageUrls;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  }
}
