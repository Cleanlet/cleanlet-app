import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';

class CarouselModalWidget extends StatefulWidget {
  final List<String> messages;

  CarouselModalWidget({Key? key, required this.messages}) : super(key: key);

  @override
  _CarouselModalWidgetState createState() => _CarouselModalWidgetState();
}

class _CarouselModalWidgetState extends State<CarouselModalWidget> {
  int _current = 0;
  CarouselController _sliderController = CarouselController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CarouselSlider(
            options: CarouselOptions(
                autoPlay: false,
                height: 150,
                disableCenter: true,
                viewportFraction: 1.0,
                onPageChanged: (index, reason) {
                  setState(() {
                    _current = index;
                  });
                }),
            carouselController: _sliderController,
            items: widget.messages.map((message) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            message,
                            style: TextStyle(fontSize: 16, height: 1.5),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          if (widget.messages.indexOf(message) == 3)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Close'),
                            ),
                        ],
                      ));
                },
              );
            }).toList(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DotsIndicator(
                dotsCount: widget.messages.length,
                position: _current,
                onTap: (index) {
                  _sliderController.animateToPage(index);
                },
                decorator: DotsDecorator(
                  color: Colors.black.withOpacity(0.4),
                  activeColor: Colors.amber,
                  size: const Size.square(12.0),
                  activeSize: const Size(24.0, 12.0),
                  activeShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
