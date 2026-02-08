import 'package:flutter/material.dart';

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

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  void _handleCancel() {
    widget.onCancel?.call();
    Navigator.of(context).pop();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F497D),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: _handleCancel,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'ยาเกี่ยวข้อง: ${widget.medicineNickname}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6E7C8B),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'พิมพ์ความคิดเห็น...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E6EF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E6EF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1F497D)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: _handleCancel,
                  child: const Text('ยกเลิก'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _canSubmit ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F497D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('ส่ง'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Color.fromARGB(255, 248, 248, 255),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F497D),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'ยาเกี่ยวข้อง: $medicineNickname',
              style: const TextStyle(
                fontSize: 13,
                color: Color.fromARGB(255, 31, 40, 49),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color.fromARGB(255, 133, 135, 176)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  note,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F497D),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommentInline extends StatefulWidget {
  final String medicineNickname;
  final String initialText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  const CommentInline({
    super.key,
    required this.medicineNickname,
    required this.initialText,
    required this.onChanged,
    required this.onSubmit,
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

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  void _handleSubmit() {
    if (!_canSubmit) return;
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E6EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'comment',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F497D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ยาเกี่ยวข้อง: ${widget.medicineNickname}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6E7C8B),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            maxLines: 4,
            onChanged: (value) {
              widget.onChanged(value);
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'พิมพ์ความคิดเห็น...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E6EF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE0E6EF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1F497D)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _canSubmit ? _handleSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F497D),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('ส่ง'),
            ),
          ),
        ],
      ),
    );
  }
}
