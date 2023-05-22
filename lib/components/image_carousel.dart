import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';

class ImageCarousel extends StatelessWidget {
  const ImageCarousel({
    Key? key,
  }) : super(key: key);
  static const List<String> imgList = [
    'https://storage.googleapis.com/cleanlet-app.appspot.com/inlet-photos/1.jpg',
    'https://storage.googleapis.com/cleanlet-app.appspot.com/inlet-photos/2.jpg',
    'https://storage.googleapis.com/cleanlet-app.appspot.com/inlet-photos/4.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return FlutterCarousel(
      options: CarouselOptions(
        height: 200,
        showIndicator: true,
        slideIndicator: const CircularSlideIndicator(),
        enableInfiniteScroll: true,
      ),
      items: imgList.map((i) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              height: 100,
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: NetworkImage(i),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
