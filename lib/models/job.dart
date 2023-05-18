typedef JobID = String;
class Job {
  String referenceId;

  Job ({
    required this.referenceId
});
  factory Job.fromMap( Map<String, dynamic>? data, String docId ) {
    return Job(referenceId: docId);
}
}