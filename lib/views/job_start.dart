import 'dart:io';

import 'package:cleanlet/views/test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/inlet.dart';
import '../services/firestore_repository.dart';

class CleaningPhotoView extends ConsumerStatefulWidget {
  final Inlet inlet;
  final String photoToTake;
  const CleaningPhotoView(this.inlet, this.photoToTake, {super.key});

  @override
  ConsumerState<CleaningPhotoView> createState() => _JobStartPageState();
}

class _JobStartPageState extends ConsumerState<CleaningPhotoView> {
  File? _image;
  final _picker = ImagePicker();
  final storageRef = FirebaseStorage.instance.ref();

  // Implementing the image picker
  Future<void> _openImagePicker(ImageSource source) async {
    final XFile? pickedImage = await _picker.pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  Future<void> _completeJob(ref) async {
    final database = ref.read(databaseProvider);
    await database
        .updateInlet(widget.inlet.referenceId, data: {'status': 'cleaned'});
    await database.updateJob(widget.inlet.jobId,
        data: {"finishedAt": Timestamp.now(), "status": "cleaned"});
    _showMyDialog();
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cleaning complete'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Thank you for cleaning this inlet'),
                Text('Your points will be awarded shortly'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Continue'),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (route) => false);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagesRef = storageRef.child('cleaning-images');
    final imageRef =
        imagesRef.child('${widget.inlet.jobId}-${widget.photoToTake}.jpg');

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.photoToTake} Cleaning Photo'),
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
                  : const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Please select an take a photo or choose an image from your photo gallery',
                        textAlign: TextAlign.center,
                      )),
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
                onPressed: (_image == null)
                    ? null
                    : () async => {
                          await imageRef.putFile(_image!),
                          if (widget.photoToTake == 'Before')
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        TestPage(widget.inlet)))
                          else if (widget.photoToTake == 'After')
                            await _completeJob(ref)
                        },
                icon: const Icon(Icons.check),
                label: const Text("Complete"),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40)))
          ],
        ),
      ),
    );
  }
}
