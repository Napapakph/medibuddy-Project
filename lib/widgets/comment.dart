import 'package:flutter/material.dart';

/// ============================
/// Helper: Show comment editor as a Modal Bottom Sheet
/// ============================
Future<String?> showCommentBottomSheet({
  required BuildContext context,
  required String medicineNickname,
  String initialText = '',
  VoidCallback? onCancel,
  required ValueChanged<String> onSubmit,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => CommentPopup(
      title: 'คอมเม้น',
      medicineNickname: medicineNickname,
      initialText: initialText,
      onCancel: onCancel,
      onSubmit: onSubmit,
    ),
  );
}

/// ============================
/// Helper: Show comment viewer as a Modal Bottom Sheet
/// ============================
Future<bool?> showCommentViewerBottomSheet({
  required BuildContext context,
  required String medicineNickname,
  required String note,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => CommentViewer(
      title: 'คอมเม้น',
      medicineNickname: medicineNickname,
      note: note,
    ),
  );
}

/// ============================
/// CommentPopup – ModalBottomSheet for writing comments
/// ============================
class CommentPopup extends StatefulWidget {
  final String title;
  final String medicineNickname;
  final String initialText;
  final VoidCallback? onCancel;
  final ValueChanged<String> onSubmit;

  const CommentPopup({
    super.key,
    required this.title,
    required this.medicineNickname,
    required this.initialText,
    this.onCancel,
    required this.onSubmit,
  });

  @override
  State<CommentPopup> createState() => _CommentPopupState();
}

class _CommentPopupState extends State<CommentPopup> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit => true; // Always allow submission (to clear the note)

  void _handleCancel() {
    widget.onCancel?.call();
    Navigator.of(context).pop();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    widget.onSubmit(text);
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'คอมเม้น',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2B4C7E),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _handleCancel,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade300,
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: Color(0xFF5D4037)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Medicine name
              Text(
                widget.medicineNickname,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 74, 128, 196),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              // Text input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'เขียนความคิดเห็นของคุณ (ไม่บังคับ)',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A81BB),
                    disabledBackgroundColor: const Color(0xFFB7DAFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'บันทึกคอมเม้น',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================
/// CommentViewer – ModalBottomSheet to view existing comments (read-only)
/// ============================
class CommentViewer extends StatelessWidget {
  final String title;
  final String medicineNickname;
  final String note;

  const CommentViewer({
    super.key,
    required this.title,
    required this.medicineNickname,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'คอมเม้น',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2B4C7E),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade300,
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: Color(0xFF5D4037)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Medicine name
              Text(
                medicineNickname,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 74, 128, 196),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              // Note content
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop(true);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      note,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2B4C7E),
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================
/// CommentInline – Inline comment editor (used in confirm_action.dart)
/// ============================
class CommentInline extends StatefulWidget {
  final String medicineNickname;
  final String initialText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback? onClose;

  const CommentInline({
    super.key,
    required this.medicineNickname,
    required this.initialText,
    required this.onChanged,
    required this.onSubmit,
    this.onClose,
  });

  @override
  State<CommentInline> createState() => _CommentInlineState();
}

class _CommentInlineState extends State<CommentInline> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB7DAFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title + close button
          Row(
            children: [
              const Expanded(
                child: Text(
                  'คอมเม้น',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2B4C7E),
                  ),
                ),
              ),
              if (widget.onClose != null)
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300,
                    ),
                    child: const Icon(Icons.close,
                        size: 16, color: Color.fromARGB(255, 55, 66, 93)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Medicine name
          Text(
            widget.medicineNickname,
            style: const TextStyle(
              fontSize: 13,
              color: Color.fromARGB(255, 102, 100, 145),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Text input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color.fromARGB(255, 255, 255, 255), width: 1.5),
            ),
            child: TextField(
              controller: _controller,
              maxLines: 3,
              onChanged: (value) {
                widget.onChanged(value);
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'เขียนความคิดเห็นของคุณ (ไม่บังคับ)',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A81BB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'บันทึกคอมเม้น',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
