import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/widgets/medicine_step_timeline.dart';
import 'package:medibuddy/services/medicine_api.dart';

import 'find_medicine.dart';

class CreateNameMedicinePage extends StatefulWidget {
  final int profileId;

  const CreateNameMedicinePage({
    super.key,
    required this.profileId,
  });

  @override
  State<CreateNameMedicinePage> createState() => _CreateNameMedicinePageState();
}

class _CreateNameMedicinePageState extends State<CreateNameMedicinePage> {
  final TextEditingController _nameController = TextEditingController();

  String _imagePath = '';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _imagePath = image.path;
    });
  }

  Future<void> _goNext() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาตั้งชื่อยา')),
      );
      return;
    }

    // step 1: draft
    final draft = MedicineDraft(
      displayName: name,
      imagePath: _imagePath,
    );

    // step 2: เลือกยาจาก database
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FindMedicinePage(draft: draft),
      ),
    );

    if (!mounted) return;
    if (result is! MedicineItem) return;

    setState(() => _saving = true);

    // step 3: เตรียม local item (สำเร็จในแอพเสมอ)
    final MedicineItem localItem = result.copyWith(
      displayName: name,
      imagePath: _imagePath,
    );

    try {
      // step 4: พยายามบันทึกลง backend
      final api = MedicineApi();

      await api.addMedicineToProfile(
        profileId: widget.profileId,
        medId: result.mediId, // ใช้ getter ที่ parse int แล้ว
        mediNickname: name,
        pictureFile: _imagePath.isEmpty ? null : File(_imagePath),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกลงระบบสำเร็จ')),
      );

      Navigator.pop(context, localItem);
    } catch (e) {
      // ❗ backend ล้มเหลว → ยังถือว่าสำเร็จในแอพ
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('บันทึกแบบชั่วคราว (ยังไม่ sync): $e'),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, localItem);
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F497D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'เพิ่มยา',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: maxWidth * 0.06,
                vertical: maxHeight * 0.03,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const MedicineStepTimeline(currentStep: 1),
                  SizedBox(height: maxHeight * 0.03),
                  const Text(
                    'ตั้งชื่อยา',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F497D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'ชื่อยา',
                      filled: true,
                      fillColor: const Color(0xFFF2F4F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: maxHeight * 0.03),
                  const Text(
                    'รูปยา',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F497D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F8),
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
                  SizedBox(height: maxHeight * 0.03),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _goNext,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                        backgroundColor: const Color(0xFF1F497D),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
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
