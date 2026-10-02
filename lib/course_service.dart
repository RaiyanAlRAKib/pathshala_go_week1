import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/course.dart';
import 'models/course_video.dart';
import 'models/course_material.dart';

class CourseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Course> createCourse({
    required String title,
    required String description,
    required double price,
    required Uint8List thumbnailBytes,
    required String thumbnailFileName,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final thumbnailPath = '$userId/${DateTime.now().millisecondsSinceEpoch}_$thumbnailFileName';

    await _client.storage.from('course-thumbnails').uploadBinary(
          thumbnailPath,
          thumbnailBytes,
          fileOptions: const FileOptions(upsert: false),
        );

    final thumbnailUrl = _client.storage.from('course-thumbnails').getPublicUrl(thumbnailPath);

    final data = await _client
        .from('courses')
        .insert({
          'teacher_id': userId,
          'title': title,
          'description': description,
          'price': price,
          'thumbnail_url': thumbnailUrl,
        })
        .select()
        .single();

    return Course.fromMap(data);
  }

  Future<List<Course>> fetchMyCourses() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client
        .from('courses')
        .select()
        .eq('teacher_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((row) => Course.fromMap(row)).toList();
  }

  Future<void> deleteCourse(String courseId) async {
    await _client.from('courses').delete().eq('id', courseId);
  }

  Future<CourseVideo> addVideo({
    required String courseId,
    required String title,
    required Uint8List videoBytes,
    required String fileName,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final path = '$userId/$courseId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from('course-videos').uploadBinary(
          path,
          videoBytes,
          fileOptions: const FileOptions(upsert: false),
        );

    final videoUrl = _client.storage.from('course-videos').getPublicUrl(path);

    final data = await _client
        .from('course_videos')
        .insert({
          'course_id': courseId,
          'title': title,
          'video_url': videoUrl,
        })
        .select()
        .single();

    return CourseVideo.fromMap(data);
  }

  Future<void> deleteVideo(String videoId) async {
    await _client.from('course_videos').delete().eq('id', videoId);
  }

  Future<CourseMaterial> addMaterial({
    required String courseId,
    required String title,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final path = '$userId/$courseId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from('course-materials').uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(upsert: false),
        );

    final fileUrl = _client.storage.from('course-materials').getPublicUrl(path);

    final data = await _client
        .from('course_materials')
        .insert({
          'course_id': courseId,
          'title': title,
          'file_url': fileUrl,
        })
        .select()
        .single();

    return CourseMaterial.fromMap(data);
  }

  Future<void> deleteMaterial(String materialId) async {
    await _client.from('course_materials').delete().eq('id', materialId);
  }

  Future<List<CourseVideo>> fetchVideos(String courseId) async {
    final data = await _client
        .from('course_videos')
        .select()
        .eq('course_id', courseId)
        .order('created_at', ascending: true);
    return (data as List).map((row) => CourseVideo.fromMap(row)).toList();
  }

  Future<List<CourseMaterial>> fetchMaterials(String courseId) async {
    final data = await _client
        .from('course_materials')
        .select()
        .eq('course_id', courseId)
        .order('created_at', ascending: true);
    return (data as List).map((row) => CourseMaterial.fromMap(row)).toList();
  }
}