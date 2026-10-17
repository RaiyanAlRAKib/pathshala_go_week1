import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/assignment.dart';

class AssignmentService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Assignment> createAssignment({
    required String courseId,
    required String title,
    required String description,
    required DateTime dueAt,
  }) async {
    final data = await _client
        .from('assignments')
        .insert({
          'course_id': courseId,
          'title': title,
          'description': description,
          'due_at': dueAt.toUtc().toIso8601String(),
        })
        .select()
        .single();
    return Assignment.fromMap(data);
  }

  Future<List<Assignment>> fetchAssignments(String courseId) async {
    final data = await _client
        .from('assignments')
        .select()
        .eq('course_id', courseId)
        .order('due_at', ascending: true);
    return (data as List).map((row) => Assignment.fromMap(row)).toList();
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await _client.from('assignments').delete().eq('id', assignmentId);
  }
}