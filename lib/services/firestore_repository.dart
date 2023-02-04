import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inlet.dart';
import 'firestore_data_source.dart';

class FirestoreRepository {
  const FirestoreRepository(this._dataSource);

  final FirestoreDataSource _dataSource;

  Stream<List<Inlet>> watchInlets() =>
      _dataSource.watchCollection(
        path: 'inlets',
        builder: (data, documentId) => Inlet.fromMap(data, documentId),
      );

  Stream<Inlet> watchInlet({required InletID inletID}) =>
      _dataSource.watchDocument(
        path: 'inlets/$inletID',
        builder: (data, documentId) => Inlet.fromMap(data, documentId),
      );

}

final databaseProvider = Provider<FirestoreRepository>((ref) {
  return FirestoreRepository(ref.watch(firestoreDataSourceProvider));
});

final inletsStreamProvider = StreamProvider.autoDispose<List<Inlet>>((ref) {
  final database = ref.watch(databaseProvider);
  return database.watchInlets();
});

final inletStreamProvider =
StreamProvider.autoDispose.family<Inlet, InletID>((ref, inletId) {
  final database = ref.watch(databaseProvider);
  return database.watchInlet(inletID: inletId);
});