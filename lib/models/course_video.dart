class CourseVideo {
  final String id;
  final String courseId;
  final String title;
  final String videoUrl;
  final DateTime createdAt;

  CourseVideo({
    required this.id,
    required this.courseId,
    required this.title,
    required this.videoUrl,
    required this.createdAt,
  });

  factory CourseVideo.fromMap(Map<String, dynamic> map) {
    return CourseVideo(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      title: map['title'] as String,
      videoUrl: map['video_url'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}