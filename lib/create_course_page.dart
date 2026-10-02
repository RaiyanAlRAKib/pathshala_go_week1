import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'course_service.dart';
import 'course_detail_page.dart';
import 'widgets/loading_button.dart';

class CreateCoursePage extends StatefulWidget {
  const CreateCoursePage({super.key});

  @override
  State<CreateCoursePage> createState() => _CreateCoursePageState();
}

class _CreateCoursePageState extends State<CreateCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _courseService = CourseService();

  Uint8List? _thumbnailBytes;
  String? _thumbnailFileName;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickThumbnail() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty) return;

    final bytes = await files.first.readAsBytes();
    setState(() {
      _thumbnailBytes = bytes;
      _thumbnailFileName = files.first.name;
    });
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;
    if (_thumbnailBytes == null) {
      _showMessage('Please choose a thumbnail image');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final course = await _courseService.createCourse(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        thumbnailBytes: _thumbnailBytes!,
        thumbnailFileName: _thumbnailFileName!,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CourseDetailPage(course: course)),
      );
    } catch (e) {
      _showMessage('Failed to create course. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Course')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickThumbnail,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _thumbnailBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            Text('Add a thumbnail image', style: TextStyle(color: AppColors.textMuted)),
                          ],
                        )
                      : Image.memory(_thumbnailBytes!, fit: BoxFit.cover, width: double.infinity),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Course Title'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price (৳)'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter a price';
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed < 0) return 'Enter a valid price';
                  return null;
                },
              ),
              const SizedBox(height: 26),
              LoadingButton(
                label: 'Create Course',
                isLoading: _isSaving,
                onPressed: _createCourse,
              ),
            ],
          ),
        ),
      ),
    );
  }
}