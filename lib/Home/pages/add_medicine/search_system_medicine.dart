import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/widgets/medicine_step_timeline.dart';
import 'link_medicine.dart';
import '../../../OCR/camera_ocr.dart';
import 'summary_medicine.dart';

class FindMedicinePage extends StatefulWidget {
  final MedicineDraft draft;
  final int profileId;
  final bool isEdit;
  final MedicineItem? initialItem;

  FindMedicinePage({
    super.key,
    required this.draft,
    required this.profileId,
    this.isEdit = false,
    this.initialItem,
  });

  @override
  State<FindMedicinePage> createState() => _FindMedicinePageState();
}

class _FindMedicinePageState extends State<FindMedicinePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 🔹 ค้นหาด้วยการพิมพ์
  Future<void> _goNextBySerch() async {
    final keyword = _searchController.text.trim();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicinePage(
          profileId: widget.profileId,
          draft: widget.draft.copyWith(
            searchQuery_medi: keyword,
          ),
          isEdit: widget.isEdit,
          initialItem: widget.initialItem,
        ),
      ),
    );

    if (!mounted) return;
    if (result is MedicineItem) {
      Navigator.pop(context, result);
    }
  }

  /// 🔹 ค้นหาด้วย OCR (กล้อง)
  Future<void> _scanByCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CameraOcrPage(),
      ),
    );

    if (!mounted) return;

    // CameraOcrPage ควร pop กลับมาด้วย String (ข้อความ OCR)
    if (result is String && result.trim().isNotEmpty) {
      setState(() {
        _searchController.text = result.trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = widget.isEdit ? 'แก้ไขรายการยา' : 'เพิ่มรายการยา';
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F497D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'เพิ่มยา',
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 227, 242, 255),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              const MedicineStepTimeline(currentStep: 2),
              const SizedBox(height: 24),
              const Text(
                'ค้นหารายการยาที่เกี่ยวข้อง',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F497D),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ชื่อสามัญ / ชื่อการค้า',
                  filled: true,
                  fillColor: const Color(0xFFF2F4F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFF1F497D)),
                    onPressed: _goNextBySerch,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _goNextBySerch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F497D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.search, color: Colors.white),
                    label: const Text('ค้นหา',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _scanByCamera,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1F497D),
                      side: const BorderSide(color: Color(0xFF1F497D)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('สแกนฉลาก'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 350,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'พิมพ์คำค้นหา หรือใช้กล้องสแกนฉลากยา',
                      style: TextStyle(color: Color(0xFF7A869A)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _skipSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F497D),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'ข้ามการค้นหา',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _skipSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryMedicinePage(
          profileId: widget.profileId,
          draft: widget.draft.copyWith(
            searchQuery_medi: '',
            catalogItem: null, // ✅ เพิ่มบรรทัดนี้ (ไม่ผูก DB)
          ),
          isEdit: widget.isEdit,
          initialItem: widget.initialItem,
        ),
      ),
    );

    if (!mounted) return;
    if (result is MedicineItem) {
      Navigator.pop(context, result);
    }
  }
}
