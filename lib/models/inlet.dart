import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

typedef InletID = String;

class Inlet {
  GeoPoint geoLocation;
  String niceName;
  String referenceId;
  List<String> subscribed;


  Inlet({required this.geoLocation,
    required this.niceName,
    required this.referenceId,
    required this.subscribed
  });

  bool get isSubscribed =>
      subscribed.contains(FirebaseAuth.instance.currentUser!.uid);


  factory Inlet.fromMap(Map<String, dynamic>? data, String documentId) {
    if (data == null) {
      throw StateError('missing data for jobId: $documentId');
    }
    final niceName = data['niceName'] as String?;
    if (niceName == null) {
      throw StateError('missing niceName for inletId: $documentId');
    }
    final geoLocation = data['geoLocation'] as GeoPoint;
    final List<String> subscribed;
    if (data['subscribed'] == null) {
      subscribed = [];
    } else {
      subscribed = List<String>.from(data['subscribed']);
    }
    return Inlet(  subscribed: subscribed, referenceId: documentId, geoLocation: geoLocation, niceName: niceName);
  }

  Map<String, dynamic> toJson() => _inletToJson(this);
  Map<String, dynamic> toMap() {
    return {
      'subscribed': subscribed,
    };
  }


}


Map<String, dynamic> _inletToJson(Inlet instance) => <String, dynamic>{
      'niceName': instance.niceName,
      'geoLocation': instance.geoLocation,
    };
