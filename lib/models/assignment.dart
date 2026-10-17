class Assignment {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final DateTime dueAt;
  final DateTime createdAt;

  Assignment({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.dueAt,
    required this.createdAt,
  });

  bool get isOverdue => dueAt.isBefore(DateTime.now());

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      // Stored as UTC in Supabase, shown in the device's local time
      dueAt: DateTime.parse(map['due_at'] as String).toLocal(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}