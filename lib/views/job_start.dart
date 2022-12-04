import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class JobStartPage extends StatefulWidget {
  const JobStartPage({super.key});

  @override
  State<JobStartPage> createState() => _JobStartPageState();
}

class _JobStartPageState extends State<JobStartPage> {
  File? _image;

  final _picker = ImagePicker();
  // Implementing the image picker
  Future<void> _openImagePicker(ImageSource source) async {
    final XFile? pickedImage =
    await _picker.pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }
  @override
  Widget build(BuildContext context) {


    return  Scaffold(
      appBar: AppBar(
        title: const Text('Take a drain photo before cleaning'),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: 300,
              color: Colors.grey[300],
              child: _image != null
                  ? Image.file(_image!, fit: BoxFit.cover)
                  : const Align(alignment: Alignment.center, child: Text('Please select an take a photo or choose an image from your photo gallery', textAlign: TextAlign.center,)),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        _openImagePicker(ImageSource.camera);
                      },
                      child: const Text('Take a picture'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        _openImagePicker(ImageSource.gallery);
                      },
                      child: const Text('Choose an image'),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: (_image == null) ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.check),
              label: const Text("Complete"),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40))
            )
          ],
        ),
      ),
    );
  }
}