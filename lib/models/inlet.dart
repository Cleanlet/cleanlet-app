import 'package:cloud_firestore/cloud_firestore.dart';

class Inlet {
  GeoPoint geoLocation;
  String niceName;
  String referenceId;

  Inlet(
      {required this.geoLocation,
      required this.niceName,
      required this.referenceId});

  factory Inlet.fromMap(Map<String, dynamic>? data, String documentId) {
    if (data == null) {
      throw StateError('missing data for jobId: $documentId');
    }
    final niceName = data['niceName'] as String?;
    if (niceName == null) {
      throw StateError('missing niceName for inletId: $documentId');
    }
    final geoLocation = data['geoLocation'] as GeoPoint;
    return Inlet(referenceId: documentId, geoLocation: geoLocation, niceName: niceName);
  }

  Map<String, dynamic> toJson() => _inletToJson(this);
}

Map<String, dynamic> _inletToJson(Inlet instance) => <String, dynamic>{
      'niceName': instance.niceName,
      'geoLocation': instance.geoLocation,
    };
