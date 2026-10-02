import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';
import 'course_service.dart';
import 'models/course.dart';
import 'models/course_video.dart';
import 'models/course_material.dart';
import 'video_player_page.dart';

class CourseDetailPage extends StatefulWidget {
  final Course course;
  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final _courseService = CourseService();

  List<CourseVideo> _videos = [];
  List<CourseMaterial> _materials = [];
  bool _isLoadingContent = true;
  bool _isUploadingVideo = false;
  bool _isUploadingMaterial = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoadingContent = true);
    final videos = await _courseService.fetchVideos(widget.course.id);
    final materials = await _courseService.fetchMaterials(widget.course.id);
    if (!mounted) return;
    setState(() {
      _videos = videos;
      _materials = materials;
      _isLoadingContent = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmDelete(String itemName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this item?'),
        content: Text('This will permanently remove "$itemName". This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<String?> _promptTitle(String defaultTitle) async {
    final controller = TextEditingController(text: defaultTitle);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name this file'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _addVideo() async {
    final files = await FilePicker.pickFiles(type: FileType.video);
    if (files.isEmpty) return;

    final file = files.first;
    final bytes = await file.readAsBytes();

    final defaultTitle = file.name.split('.').first;
    final title = await _promptTitle(defaultTitle);
    if (title == null || title.isEmpty) return;

    setState(() => _isUploadingVideo = true);
    try {
      await _courseService.addVideo(
        courseId: widget.course.id,
        title: title,
        videoBytes: bytes,
        fileName: file.name,
      );
      await _loadContent();
    } catch (e) {
      _showMessage('Failed to upload video. Try again.');
    } finally {
      if (mounted) setState(() => _isUploadingVideo = false);
    }
  }

  Future<void> _deleteVideo(CourseVideo video) async {
    final confirmed = await _confirmDelete(video.title);
    if (!confirmed) return;
    try {
      await _courseService.deleteVideo(video.id);
      await _loadContent();
    } catch (e) {
      _showMessage('Failed to delete video.');
    }
  }

  Future<void> _addMaterial() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (files.isEmpty) return;

    final file = files.first;
    final bytes = await file.readAsBytes();

    final defaultTitle = file.name.split('.').first;
    final title = await _promptTitle(defaultTitle);
    if (title == null || title.isEmpty) return;

    setState(() => _isUploadingMaterial = true);
    try {
      await _courseService.addMaterial(
        courseId: widget.course.id,
        title: title,
        fileBytes: bytes,
        fileName: file.name,
      );
      await _loadContent();
    } catch (e) {
      _showMessage('Failed to upload PDF. Try again.');
    } finally {
      if (mounted) setState(() => _isUploadingMaterial = false);
    }
  }

  Future<void> _deleteMaterial(CourseMaterial material) async {
    final confirmed = await _confirmDelete(material.title);
    if (!confirmed) return;
    try {
      await _courseService.deleteMaterial(material.id);
      await _loadContent();
    } catch (e) {
      _showMessage('Failed to delete material.');
    }
  }

  void _openVideo(CourseVideo video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerPage(videoUrl: video.videoUrl, title: video.title),
      ),
    );
  }

  Future<void> _openMaterial(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showMessage('Could not open this file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return Scaffold(
      appBar: AppBar(title: Text(course.title)),
      body: _isLoadingContent
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (course.thumbnailUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(course.thumbnailUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 16),
                Text(course.description, style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Text(
                  '৳${course.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 16),
                ),
                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Videos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    _isUploadingVideo
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : TextButton.icon(
                            onPressed: _addVideo,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Video'),
                          ),
                  ],
                ),
                if (_videos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text('No videos yet', style: TextStyle(color: AppColors.textMuted)),
                  )
                else
                  ..._videos.map((video) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.play_circle_outline, color: AppColors.primary),
                          title: Text(video.title),
                          onTap: () => _openVideo(video),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteVideo(video),
                          ),
                        ),
                      )),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('PDF Materials', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    _isUploadingMaterial
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : TextButton.icon(
                            onPressed: _addMaterial,
                            icon: const Icon(Icons.add),
                            label: const Text('Add PDF'),
                          ),
                  ],
                ),
                if (_materials.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text('No materials yet', style: TextStyle(color: AppColors.textMuted)),
                  )
                else
                  ..._materials.map((material) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
                          title: Text(material.title),
                          onTap: () => _openMaterial(material.fileUrl),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteMaterial(material),
                          ),
                        ),
                      )),
              ],
            ),
    );
  }
}