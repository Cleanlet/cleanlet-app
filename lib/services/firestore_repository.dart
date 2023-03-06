import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inlet.dart';
import '../models/job.dart';
import '../models/user.dart';
import 'firebase_auth_repository.dart';
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
  Stream<Job> watchJob({required String jobId}) =>
    _dataSource.watchDocument(
        path: 'inletCleaningJobs/$jobId',
        builder: (data, documentId) => Job.fromMap(data, documentId),
  );

  Stream<CleanletUser> watchUser({required String userID}) =>
      _dataSource.watchDocument(
        path: 'users/$userID',
        builder: (data, documentId) => CleanletUser.fromMap(data, documentId),
      );

  Future<void> updateInlet(String referenceId, { required Map<String, dynamic> data}) =>
      _dataSource.setData(
        path: 'inlets/$referenceId',
        data: data,
      );

  Future<void> updateUser(String userId, { required Map<String, dynamic> data}) =>
      _dataSource.setData(
        path: 'users/$userId',
        data: data,
      );

  Future<void> updateJob(String jobId, {required Map<String, dynamic> data}) =>
      _dataSource.setData(
        path: 'inletCleaningJobs/$jobId',
        data: data,
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

final jobStreamProvider = StreamProvider.autoDispose.family<Job, JobID>((ref, jobId) {
  final database = ref.watch(databaseProvider);
  return database.watchJob(jobId: jobId);
});

final userProvider = StreamProvider.autoDispose((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) {
    throw AssertionError('User can\'t be null');

  }
  final database = ref.watch(databaseProvider);
  return database.watchUser(userID: user.uid);
});