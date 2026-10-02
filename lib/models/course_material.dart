class CourseMaterial {
  final String id;
  final String courseId;
  final String title;
  final String fileUrl;
  final DateTime createdAt;

  CourseMaterial({
    required this.id,
    required this.courseId,
    required this.title,
    required this.fileUrl,
    required this.createdAt,
  });

  factory CourseMaterial.fromMap(Map<String, dynamic> map) {
    return CourseMaterial(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      title: map['title'] as String,
      fileUrl: map['file_url'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}