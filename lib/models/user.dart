class CleanletUser {
  String uid;
  int inletsWatched;
  CleanletUser({required this.inletsWatched, required this.uid});

  factory CleanletUser.fromMap(Map<String, dynamic>? data, String uid) {
    if (data == null) {
      throw StateError('missing data for User: $uid');
    }
    final int inletsWatched;
    if (data['inletsWatched'] == null) {
      inletsWatched = 0;
    } else {
      inletsWatched = data['inletsWatched'] as int;
    }
    return CleanletUser(inletsWatched: inletsWatched, uid: uid);
  }

  Map<String, dynamic> toMap() {
    return {
      'inletsWatched': inletsWatched,
    };
  }
}