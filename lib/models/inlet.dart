import 'package:cloud_firestore/cloud_firestore.dart';

class Inlet {
  GeoPoint geoLocation;
  String niceName;
  String referenceId;

  Inlet(
      {required this.geoLocation,
      required this.niceName,
      required this.referenceId});

  factory Inlet.fromSnapshot(DocumentSnapshot snapshot) {
    final Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    data['referenceId'] = snapshot.reference.id;
    final newInlet = Inlet.fromJson(data);
    return newInlet;
  }

  factory Inlet.fromJson(Map<String, dynamic> json) => _inletFromJson(json);

  Map<String, dynamic> toJson() => _inletToJson(this);
}

Inlet _inletFromJson(Map<String, dynamic> json) {
  return Inlet(
      geoLocation: json['geoLocation'] as GeoPoint,
      niceName: json['niceName'] as String,
      referenceId: json['referenceId'] as String);
}

Map<String, dynamic> _inletToJson(Inlet instance) => <String, dynamic>{
      'niceName': instance.niceName,
      'geoLocation': instance.geoLocation,
    };
