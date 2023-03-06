import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inlet.dart';
import '../models/user.dart';
import '../services/firestore_repository.dart';
import '../services/geolocation.dart';

class InletViewController extends AutoDisposeAsyncNotifier<void> {

  @override
  FutureOr<void> build() {
    // ok to leave this empty if the return type is FutureOr<void>
  }

  Future<void> subscribeToInlet(Inlet inlet) async {
    final user = ref.read(userProvider).value;
    if (user == null) {
      throw AssertionError('User can\'t be null');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
            () => addInletSubscription(inlet, user));
  }

  Future<void> unsubscribeFromInlet(Inlet inlet) async {
    final user = ref.read(userProvider).value;
    if (user == null) {
      throw AssertionError('User can\'t be null');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
            () => removeInletSubscription(inlet, user));
  }

  Future<void> inletCleaningSigup(String jobId, String inletId) async {

    state = const AsyncLoading();
    state = await AsyncValue.guard(
            () =>  inletCleaningAccepted(jobId, inletId));
  }
  Future<void> startCleaning(String jobId, String inletId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
            () =>  startCleaningJob(jobId, inletId));
  }

  Future<void> startCleaningJob(String jobId, String inletId) async {
    final database = ref.read(databaseProvider);
    final position = ref.read(positionProvider).value;
    GeoPoint geoPoint;
    if (position == null) {
      throw AssertionError('Position can\'t be null');
    } else {
      geoPoint = GeoPoint(position.latitude, position.longitude);
    }
    await database.updateInlet(inletId, data: {'status': 'cleaning'});
    await database.updateJob(jobId, data: {"startedLocation": geoPoint, "startedAt": Timestamp.now(), "status": "cleaning"});
  }


  Future<void> removeInletSubscription(Inlet inlet, CleanletUser user) async {
    final database = ref.read(databaseProvider);
    await database.updateInlet(inlet.referenceId, data: {'subscribed': FieldValue.arrayRemove([user.uid])});
    await database.updateUser(user.uid, data: {'inletsWatched': FieldValue.increment(-1)});
  }
  Future<void> addInletSubscription(Inlet inlet, CleanletUser user) async {
    final database = ref.read(databaseProvider);
    await database.updateInlet(inlet.referenceId, data: {'subscribed': FieldValue.arrayUnion([user.uid])});
    await database.updateUser(user.uid, data: {'inletsWatched': FieldValue.increment(1)});
  }
  Future<void> inletCleaningAccepted(String jobId, String inletId) async {
    final user = ref.read(userProvider).value;
    if (user == null) {
      throw AssertionError('User can\'t be null');
    }
    final database = ref.read(databaseProvider);
    final position = ref.read(positionProvider).value;
    GeoPoint geoPoint;
    if (position == null) {
      throw AssertionError('Position can\'t be null');
    } else {
      geoPoint = GeoPoint(position.latitude, position.longitude);
    }
    await database.updateInlet(inletId, data: {'status': 'accepted'});
    await database.updateJob(jobId, data: {"acceptedLocation": geoPoint, "acceptedBy": user.uid, "acceptedAt": Timestamp.now(), "status": "accepted"});
  }
}

final inletViewControllerProvider =
AutoDisposeAsyncNotifierProvider<InletViewController, void>(
    InletViewController.new);