import 'package:flutter/material.dart';
import 'live_class_service.dart';
import 'widgets/date_time_field.dart';
import 'widgets/loading_button.dart';

class ScheduleLiveClassPage extends StatefulWidget {
  final String courseId;
  const ScheduleLiveClassPage({super.key, required this.courseId});

  @override
  State<ScheduleLiveClassPage> createState() => _ScheduleLiveClassPageState();
}

class _ScheduleLiveClassPageState extends State<ScheduleLiveClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  final _service = LiveClassService();

  DateTime? _scheduledAt;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateMeetLink(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please paste the Google Meet link';
    final uri = Uri.tryParse(value.trim());
    final isValid = uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.contains('meet.google.com');
    if (!isValid) return 'Enter a valid Google Meet link (meet.google.com/...)';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduledAt == null) {
      _showMessage('Please choose a date and time');
      return;
    }
    if (_scheduledAt!.isBefore(DateTime.now())) {
      _showMessage('Class time must be in the future');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.scheduleLiveClass(
        courseId: widget.courseId,
        title: _titleController.text.trim(),
        scheduledAt: _scheduledAt!,
        meetLink: _linkController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Failed to schedule live class. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule Live Class')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Class Title'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 14),
              DateTimeField(
                label: 'Date & time',
                value: _scheduledAt,
                onChanged: (dt) => setState(() => _scheduledAt = dt),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _linkController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Google Meet link',
                  hintText: 'https://meet.google.com/abc-defg-hij',
                  prefixIcon: Icon(Icons.videocam_outlined),
                ),
                validator: _validateMeetLink,
              ),
              const SizedBox(height: 26),
              LoadingButton(
                label: 'Schedule Class',
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