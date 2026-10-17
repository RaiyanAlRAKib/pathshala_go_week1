import 'package:flutter/material.dart';
import 'assignment_service.dart';
import 'widgets/date_time_field.dart';
import 'widgets/loading_button.dart';

class CreateAssignmentPage extends StatefulWidget {
  final String courseId;
  const CreateAssignmentPage({super.key, required this.courseId});

  @override
  State<CreateAssignmentPage> createState() => _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends State<CreateAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _service = AssignmentService();

  DateTime? _dueAt;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueAt == null) {
      _showMessage('Please choose a due date and time');
      return;
    }
    if (_dueAt!.isBefore(DateTime.now())) {
      _showMessage('Due time must be in the future');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.createAssignment(
        courseId: widget.courseId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueAt: _dueAt!,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Failed to create assignment. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Assignment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Assignment Title'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter instructions'
                    : null,
              ),
              const SizedBox(height: 14),
              DateTimeField(
                label: 'Due date & time',
                value: _dueAt,
                onChanged: (dt) => setState(() => _dueAt = dt),
              ),
              const SizedBox(height: 26),
              LoadingButton(
                label: 'Create Assignment',
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}