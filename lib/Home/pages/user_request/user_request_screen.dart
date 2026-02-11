import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/request_api.dart';

class UserRequestScreen extends StatefulWidget {
  const UserRequestScreen({super.key});

  @override
  State<UserRequestScreen> createState() => _UserRequestScreenState();
}

class _UserRequestScreenState extends State<UserRequestScreen> {
  static const Map<String, String> _requestTypeMap = {
    'ปัญหาการใช้งาน': 'PROBLEM',
    'ฟังก์ชันการทำงาน': 'FUNCTION',
    'การแจ้งเตือน': 'NOTIFICATION',
    'อื่นๆ': 'OTHER',
  };

  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();

  String? _selectedLabel;
  String? _selectedType;
  String? _typeError;
  String? _titleError;
  String? _detailsError;

  File? _pictureFile;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String? _getToken() {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่รองรับการอัปโหลดรูปบนเว็บ')),
      );
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image == null) return;

    final file = File(image.path);
    final exists = file.existsSync();
    debugPrint('🖼️ picked file path=${file.path} exists=$exists');
    if (exists) {
      final size = file.lengthSync();
      debugPrint('🖼️ picked file size=$size');
    }

    setState(() {
      _pictureFile = file;
    });
  }

  bool _validate() {
    final title = _titleController.text.trim();
    final details = _detailsController.text.trim();

    final typeError = _selectedType == null ? 'กรุณาเลือกหมวดหมู่' : null;
    final titleError = title.isEmpty ? 'กรุณากรอกชื่อเรื่อง' : null;
    final detailsError = (_selectedType != 'ADD_MEDICINE' && details.isEmpty)
        ? 'กรุณากรอกรายละเอียด'
        : null;

    setState(() {
      _typeError = typeError;
      _titleError = titleError;
      _detailsError = detailsError;
    });

    return typeError == null && titleError == null && detailsError == null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_validate()) return;

    final token = _getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบใหม่')),
      );
      return;
    }

    final type = _selectedType ?? '';
    final title = _titleController.text.trim();
    final details = _detailsController.text.trim();
    final picturePath = _pictureFile?.path;

    debugPrint(
      '📤 submit request type=$type title="$title" detailsLen=${details.length} picture=${picturePath ?? "null"}',
    );

    setState(() => _submitting = true);
    try {
      await sendUserRequest(
        accessToken: token,
        requestType: type,
        requestTitle: title,
        requestDetails: details,
        pictureFile: _pictureFile,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งคำขอสำเร็จ')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่งไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F497D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'ข้อเสนอแนะ',
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 227, 242, 255),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'หมวดหมู่',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F497D),
                          fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedLabel,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _typeError,
                      ),
                      hint: const Text('เลือกหมวดหมู่'),
                      items: _requestTypeMap.keys
                          .map(
                            (label) => DropdownMenuItem<String>(
                              value: label,
                              child: Text(label,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        final mapped = _requestTypeMap[value];
                        debugPrint('🧾 requestType=$mapped label=$value');
                        setState(() {
                          _selectedLabel = value;
                          _selectedType = mapped;
                          _typeError = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ชื่อเรื่อง',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F497D),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _titleError,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'รายละเอียด',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F497D),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _detailsController,
                      style: const TextStyle(fontSize: 18),
                      maxLines: 5,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _detailsError,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'รูปภาพ (ถ้ามี)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F497D),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _submitting
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            if (_pictureFile != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _pictureFile!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              const Center(
                                child: Icon(
                                  Icons.photo,
                                  size: 64,
                                  color: Color(0xFF9AA7B8),
                                ),
                              ),
                            Positioned(
                              right: 64,
                              bottom: 12,
                              child: InkWell(
                                onTap: _submitting
                                    ? null
                                    : () => _pickImage(ImageSource.gallery),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1F497D),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.photo_library,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: InkWell(
                                onTap: _submitting
                                    ? null
                                    : () => _pickImage(ImageSource.camera),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1F497D),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F497D),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'ส่ง',
                            style: TextStyle(color: Colors.white, fontSize: 16),
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
