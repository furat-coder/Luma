import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../data/post_store.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final TextEditingController _textController = TextEditingController();

  String selectedType = 'Text Post';

  String? selectedFileName;
  String? selectedFilePath;

  VideoPlayerController? _videoController;

  bool isPublishing = false;

  @override
  void dispose() {
    _textController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ==================================================
  // PICK PHOTO
  // ==================================================

  Future<void> _pickPhoto() async {
    final file = await FilePicker.pickFile(type: FileType.image);

    if (file == null || file.path == null) {
      return;
    }

    await _clearVideoController();

    setState(() {
      selectedType = 'Photo Post';
      selectedFileName = file.name;
      selectedFilePath = file.path;
    });
  }

  // ==================================================
  // PICK VIDEO
  // ==================================================

  Future<void> _pickVideo(String type) async {
    final file = await FilePicker.pickFile(type: FileType.video);

    if (file == null || file.path == null) {
      return;
    }

    await _clearVideoController();

    final controller = VideoPlayerController.file(File(file.path!));

    try {
      await controller.initialize();

      controller.setLooping(true);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        selectedType = type;
        selectedFileName = file.name;
        selectedFilePath = file.path;
        _videoController = controller;
      });
    } catch (e) {
      controller.dispose();

      if (!mounted) {
        return;
      }

      _showMessage('Could not load this video.');
    }
  }

  // ==================================================
  // CLEAR VIDEO CONTROLLER
  // ==================================================

  Future<void> _clearVideoController() async {
    final oldController = _videoController;

    _videoController = null;

    await oldController?.dispose();
  }

  // ==================================================
  // REMOVE MEDIA
  // ==================================================

  Future<void> _removeMedia() async {
    await _clearVideoController();

    if (!mounted) {
      return;
    }

    setState(() {
      selectedFileName = null;
      selectedFilePath = null;
      selectedType = 'Text Post';
    });
  }

  // ==================================================
  // TOGGLE VIDEO
  // ==================================================

  void _toggleVideo() {
    final controller = _videoController;

    if (controller == null) {
      return;
    }

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }

    setState(() {});
  }

  // ==================================================
  // PUBLISH POST
  // ==================================================

  Future<void> _publishPost() async {
    final text = _textController.text.trim();

    if (selectedType == 'Text Post' && text.isEmpty) {
      _showMessage('Write something before posting ✍️');
      return;
    }

    if (selectedType != 'Text Post' && selectedFilePath == null) {
      _showMessage('Please select a file first 📁');
      return;
    }

    setState(() {
      isPublishing = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    String caption = text;

    if (caption.isEmpty) {
      caption = 'Created a new $selectedType on Luma 🚀';
    }

    // ==================================================
    // DETERMINE MEDIA TYPE
    // ==================================================

    String mediaType = 'none';

    if (selectedType == 'Photo Post') {
      mediaType = 'image';
    } else if (selectedType == 'Short') {
      mediaType = 'video';
    } else if (selectedType == 'Video') {
      mediaType = 'video';
    }

    // ==================================================
    // SAVE POST WITH MEDIA INFORMATION
    // ==================================================

    PostStore.instance.addPost(
      caption,
      mediaPath: selectedFilePath,
      mediaType: mediaType,
    );

    if (!mounted) {
      return;
    }

    await _clearVideoController();

    setState(() {
      isPublishing = false;
      selectedType = 'Text Post';
      selectedFileName = null;
      selectedFilePath = null;

      _textController.clear();
    });

    _showMessage('Your post was published! 🎉');
  }

  // ==================================================
  // SHOW MESSAGE
  // ==================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ==================================================
  // MAIN UI
  // ==================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Create something',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'Share your ideas with the Luma community.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),

            const SizedBox(height: 25),

            const Text(
              'Choose what to create',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _createOption(
              icon: Icons.edit_outlined,
              title: 'Text Post',
              subtitle: 'Share your thoughts',
              type: 'Text Post',
              onTap: () async {
                await _removeMedia();

                if (!mounted) {
                  return;
                }

                setState(() {
                  selectedType = 'Text Post';
                });
              },
            ),

            _createOption(
              icon: Icons.image_outlined,
              title: 'Photo Post',
              subtitle: 'Choose a photo',
              type: 'Photo Post',
              onTap: _pickPhoto,
            ),

            _createOption(
              icon: Icons.play_circle_outline,
              title: 'Short',
              subtitle: 'Choose a short video',
              type: 'Short',
              onTap: () {
                _pickVideo('Short');
              },
            ),

            _createOption(
              icon: Icons.video_library_outlined,
              title: 'Video',
              subtitle: 'Choose a longer video',
              type: 'Video',
              onTap: () {
                _pickVideo('Video');
              },
            ),

            const SizedBox(height: 25),

            // ==================================================
            // MEDIA PREVIEW
            // ==================================================
            if (selectedFilePath != null) ...[
              const Text(
                'Preview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              _buildMediaPreview(),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedFileName ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  TextButton.icon(
                    onPressed: _removeMedia,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Remove'),
                  ),
                ],
              ),

              const SizedBox(height: 15),
            ],

            // ==================================================
            // CAPTION
            // ==================================================
            Text(
              selectedType == 'Text Post' ? 'Write your post' : 'Add a caption',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF15151B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),

              child: TextField(
                controller: _textController,
                maxLines: 7,
                maxLength: 500,

                decoration: InputDecoration(
                  hintText: 'What are you thinking about?',

                  hintStyle: TextStyle(color: Colors.grey.shade600),

                  border: InputBorder.none,

                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // QUICK ACTIONS
            // ==================================================
            Row(
              children: [
                _smallAction(
                  icon: Icons.emoji_emotions_outlined,
                  label: 'Feeling',
                  onTap: () {
                    _textController.text += ' 😊';
                  },
                ),

                const SizedBox(width: 10),

                _smallAction(
                  icon: Icons.tag,
                  label: 'Tag',
                  onTap: () {
                    _textController.text += ' #Luma';
                  },
                ),

                const SizedBox(width: 10),

                _smallAction(
                  icon: Icons.image_outlined,
                  label: 'Media',
                  onTap: _pickPhoto,
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ==================================================
            // PUBLISH BUTTON
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 54,

              child: FilledButton.icon(
                onPressed: isPublishing ? null : _publishPost,

                icon: isPublishing
                    ? const SizedBox(
                        width: 20,
                        height: 20,

                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),

                label: Text(
                  isPublishing ? 'Publishing...' : 'Post to Luma',

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // INFO CARD
            // ==================================================
            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(18),
              ),

              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF22D3EE)),

                  SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'Create and share your ideas with the Luma community. More creator tools will be added as we build the app.',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // MEDIA PREVIEW
  // ==================================================

  Widget _buildMediaPreview() {
    if (selectedType == 'Photo Post') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),

        child: Image.file(
          File(selectedFilePath!),

          width: double.infinity,
          height: 300,

          fit: BoxFit.cover,

          errorBuilder: (context, error, stackTrace) {
            return _previewError('Unable to display this photo.');
          },
        ),
      );
    }

    final controller = _videoController;

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: 300,

        decoration: BoxDecoration(
          color: const Color(0xFF15151B),
          borderRadius: BorderRadius.circular(20),
        ),

        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),

      child: Stack(
        alignment: Alignment.center,

        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,

            child: VideoPlayer(controller),
          ),

          GestureDetector(
            onTap: _toggleVideo,

            child: Container(
              width: 64,
              height: 64,

              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),

              child: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,

                size: 38,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // PREVIEW ERROR
  // ==================================================

  Widget _previewError(String message) {
    return Container(
      width: double.infinity,
      height: 300,

      decoration: BoxDecoration(
        color: const Color(0xFF15151B),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.broken_image_outlined,
              size: 45,
              color: Colors.white54,
            ),

            const SizedBox(height: 10),

            Text(message, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // CREATE OPTION
  // ==================================================

  Widget _createOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String type,
    required VoidCallback onTap,
  }) {
    final bool isSelected = selectedType == type;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),

        tileColor: isSelected
            ? const Color(0xFF29213B)
            : const Color(0xFF15151B),

        leading: Container(
          width: 52,
          height: 52,

          decoration: BoxDecoration(
            color: const Color(0xFF29213B),
            borderRadius: BorderRadius.circular(15),
          ),

          child: Icon(icon),
        ),

        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),

          child: Text(subtitle),
        ),

        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF8B5CF6))
            : const Icon(Icons.arrow_forward_ios, size: 16),

        onTap: onTap,
      ),
    );
  }

  // ==================================================
  // SMALL ACTION
  // ==================================================

  Widget _smallAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,

        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),

          decoration: BoxDecoration(
            color: const Color(0xFF15151B),
            borderRadius: BorderRadius.circular(14),
          ),

          child: Column(
            children: [
              Icon(icon, size: 22),

              const SizedBox(height: 5),

              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
