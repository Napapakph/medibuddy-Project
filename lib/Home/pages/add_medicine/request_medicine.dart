import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RequestMedicinePage extends StatefulWidget {
  final String medicineName;

  const RequestMedicinePage({
    super.key,
    required this.medicineName,
  });

  @override
  State<RequestMedicinePage> createState() => _RequestMedicinePageState();
}

class _RequestMedicinePageState extends State<RequestMedicinePage> {
  String _imagePath = '';
  bool _saving = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _imagePath = image.path;
    });
  }

  Future<void> _submitRequest() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('การส่งคำร้องขอเพิ่มยาสำเร็จ')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F497D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'ส่งคำร้องขอเพิ่มยา',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ชื่อยา',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F497D),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(widget.medicineName),
              ),
              const SizedBox(height: 20),
              const Text(
                'รูปยา',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F497D),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      if (_imagePath.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(_imagePath),
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
                        right: 12,
                        bottom: 12,
                        child: Row(
                          children: [
                            _ImageCircleButton(
                              icon: Icons.camera_alt,
                              onTap: () => _pickImage(ImageSource.camera),
                            ),
                            const SizedBox(width: 8),
                            _ImageCircleButton(
                              icon: Icons.photo_library,
                              onTap: () => _pickImage(ImageSource.gallery),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F497D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'ยืนยัน',
                          style: TextStyle(color: Colors.white, fontSize: 16),
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

class _ImageCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ImageCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFF1F497D),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
