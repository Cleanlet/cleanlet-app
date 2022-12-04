import 'package:flutter/material.dart';

class InletIntro extends StatelessWidget {
  const InletIntro({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(

          children:  <Widget>[
            const Icon(Icons.location_on, color: Colors.green, size: 24,),
            const SizedBox(width: 10,),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:  const <Widget>[
                  Text('1234 Example Street Philadelphia PA 19106', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5,),
                  Text('Click to view map', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:  [
            const Icon(Icons.description, color: Colors.green, size: 24,),
            const SizedBox(width: 10,),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:  const <Widget>[
                  Text('Inlet Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5,),
                  Text('Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),

          ],
        ),
      ],
    );
  }
}