class CleanletUser {
  String uid;
  int inletsWatched;
  String? displayName;
  String? photoURL;
  String email;

  CleanletUser({
    required this.uid,
    required this.inletsWatched,
    required this.displayName,
    required this.photoURL,
    required this.email,
  });

  factory CleanletUser.fromMap(Map<String, dynamic>? data, String uid) {
    if (data == null) {
      throw StateError('missing data for User: $uid');
    }
    final int inletsWatched = data['inletsWatched'] ?? 0;
    return CleanletUser(
      uid: uid,
      inletsWatched: inletsWatched,
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      email: data['email'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'inletsWatched': inletsWatched,
      'displayName': displayName,
      'photoURL': photoURL,
      'email': email,
    };
  }
}
