class LiveClass {
  final String id;
  final String courseId;
  final String title;
  final DateTime scheduledAt;
  final String meetLink;
  final DateTime createdAt;

  LiveClass({
    required this.id,
    required this.courseId,
    required this.title,
    required this.scheduledAt,
    required this.meetLink,
    required this.createdAt,
  });

  bool get isPast => scheduledAt.isBefore(DateTime.now());

  factory LiveClass.fromMap(Map<String, dynamic> map) {
    return LiveClass(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      title: map['title'] as String,
      scheduledAt: DateTime.parse(map['scheduled_at'] as String).toLocal(),
      meetLink: map['meet_link'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}