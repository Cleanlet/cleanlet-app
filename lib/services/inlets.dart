import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inlet.dart';

class InletService {
  final CollectionReference collection =
      FirebaseFirestore.instance.collection('inlets');

  Stream<QuerySnapshot> getInlets() {
    return collection.snapshots();
  }

  Future<DocumentReference> addInlet(Inlet inlet) {
    return collection.add(inlet.toJson());
  }

  void updateInlet(Inlet inlet) async {
    await collection.doc(inlet.referenceId).update(inlet.toJson());
  }
}
