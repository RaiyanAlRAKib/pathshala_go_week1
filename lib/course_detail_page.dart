import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';
import 'assignment_service.dart';
import 'course_service.dart';
import 'create_assignment_page.dart';
import 'date_utils.dart';
import 'live_class_service.dart';
import 'models/assignment.dart';
import 'models/course.dart';
import 'models/course_video.dart';
import 'models/course_material.dart';
import 'models/live_class.dart';
import 'schedule_live_class_page.dart';
import 'video_player_page.dart';

class CourseDetailPage extends StatefulWidget {
  final Course course;
  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final _courseService = CourseService();
  final _assignmentService = AssignmentService();
  final _liveClassService = LiveClassService();

  List<CourseVideo> _videos = [];
  List<CourseMaterial> _materials = [];
  List<Assignment> _assignments = [];
  List<LiveClass> _liveClasses = [];
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
    try {
      final results = await Future.wait([
        _courseService.fetchVideos(widget.course.id),
        _courseService.fetchMaterials(widget.course.id),
        _assignmentService.fetchAssignments(widget.course.id),
        _liveClassService.fetchLiveClasses(widget.course.id),
      ]);
      if (!mounted) return;
      setState(() {
        _videos = results[0] as List<CourseVideo>;
        _materials = results[1] as List<CourseMaterial>;
        _assignments = results[2] as List<Assignment>;
        _liveClasses = results[3] as List<LiveClass>;
        _isLoadingContent = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingContent = false);
      _showMessage('Failed to load course content.');
    }
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

  // ---------- Assignments ----------

  Future<void> _addAssignment() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateAssignmentPage(courseId: widget.course.id)),
    );
    if (created == true) await _loadContent();
  }

  Future<void> _deleteAssignment(Assignment assignment) async {
    final confirmed = await _confirmDelete(assignment.title);
    if (!confirmed) return;
    try {
      await _assignmentService.deleteAssignment(assignment.id);
      await _loadContent();
    } catch (e) {
      _showMessage('Failed to delete assignment.');
    }
  }

  void _showAssignmentDetails(Assignment assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(assignment.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Due: ${formatDateTime(assignment.dueAt)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: assignment.isOverdue ? Colors.red : AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(assignment.description),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  // ---------- Live classes ----------

  Future<void> _scheduleLiveClass() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ScheduleLiveClassPage(courseId: widget.course.id)),
    );
    if (created == true) await _loadContent();
  }

  Future<void> _deleteLiveClass(LiveClass liveClass) async {
    final confirmed = await _confirmDelete(liveClass.title);
    if (!confirmed) return;
    try {
      await _liveClassService.deleteLiveClass(liveClass.id);
      await _loadContent();
    } catch (e) {
      _showMessage('Failed to delete live class.');
    }
  }

  Future<void> _openMeetLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showMessage('This link is not valid.');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      _showMessage('Could not open the Meet link.');
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

  Widget _sectionHeader({
    required String title,
    required String addLabel,
    required VoidCallback onAdd,
    bool isBusy = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        isBusy
            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(addLabel),
              ),
      ],
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(text, style: TextStyle(color: AppColors.textMuted)),
    );
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

                // ----- Live classes -----
                _sectionHeader(
                  title: 'Live Classes',
                  addLabel: 'Schedule',
                  onAdd: _scheduleLiveClass,
                ),
                if (_liveClasses.isEmpty)
                  _emptyText('No live classes scheduled')
                else
                  ..._liveClasses.map((liveClass) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.videocam_outlined,
                            color: liveClass.isPast ? AppColors.textMuted : AppColors.primary,
                          ),
                          title: Text(liveClass.title),
                          subtitle: Text(
                            liveClass.isPast
                                ? '${formatDateTime(liveClass.scheduledAt)} (ended)'
                                : formatDateTime(liveClass.scheduledAt),
                          ),
                          onTap: () => _openMeetLink(liveClass.meetLink),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteLiveClass(liveClass),
                          ),
                        ),
                      )),

                const SizedBox(height: 24),

                // ----- Assignments -----
                _sectionHeader(
                  title: 'Assignments',
                  addLabel: 'Add Assignment',
                  onAdd: _addAssignment,
                ),
                if (_assignments.isEmpty)
                  _emptyText('No assignments yet')
                else
                  ..._assignments.map((assignment) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.assignment_outlined,
                            color: assignment.isOverdue ? AppColors.textMuted : AppColors.primary,
                          ),
                          title: Text(assignment.title),
                          subtitle: Text(
                            assignment.isOverdue
                                ? 'Closed ${formatDateTime(assignment.dueAt)}'
                                : 'Due ${formatDateTime(assignment.dueAt)}',
                          ),
                          onTap: () => _showAssignmentDetails(assignment),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteAssignment(assignment),
                          ),
                        ),
                      )),

                const SizedBox(height: 24),

                // ----- Videos -----
                _sectionHeader(
                  title: 'Videos',
                  addLabel: 'Add Video',
                  onAdd: _addVideo,
                  isBusy: _isUploadingVideo,
                ),
                if (_videos.isEmpty)
                  _emptyText('No videos yet')
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

                // ----- PDF materials -----
                _sectionHeader(
                  title: 'PDF Materials',
                  addLabel: 'Add PDF',
                  onAdd: _addMaterial,
                  isBusy: _isUploadingMaterial,
                ),
                if (_materials.isEmpty)
                  _emptyText('No materials yet')
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