import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/live_class.dart';

class LiveClassService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<LiveClass> scheduleLiveClass({
    required String courseId,
    required String title,
    required DateTime scheduledAt,
    required String meetLink,
  }) async {
    final data = await _client
        .from('live_classes')
        .insert({
          'course_id': courseId,
          'title': title,
          'scheduled_at': scheduledAt.toUtc().toIso8601String(),
          'meet_link': meetLink,
        })
        .select()
        .single();
    return LiveClass.fromMap(data);
  }

  Future<List<LiveClass>> fetchLiveClasses(String courseId) async {
    final data = await _client
        .from('live_classes')
        .select()
        .eq('course_id', courseId)
        .order('scheduled_at', ascending: true);
    return (data as List).map((row) => LiveClass.fromMap(row)).toList();
  }

  Future<void> deleteLiveClass(String liveClassId) async {
    await _client.from('live_classes').delete().eq('id', liveClassId);
  }
}