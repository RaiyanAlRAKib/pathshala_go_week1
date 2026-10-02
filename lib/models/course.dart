class Course {
  final String id;
  final String teacherId;
  final String title;
  final String description;
  final double price;
  final String? thumbnailUrl;
  final DateTime createdAt;

  Course({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.description,
    required this.price,
    required this.thumbnailUrl,
    required this.createdAt,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      teacherId: map['teacher_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      thumbnailUrl: map['thumbnail_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}