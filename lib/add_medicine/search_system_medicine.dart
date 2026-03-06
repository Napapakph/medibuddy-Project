import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/widgets/medicine_step_timeline.dart';
import 'link_medicine.dart';
import '../OCR/camera_ocr.dart';
import 'summary_medicine.dart';
import '../OCR/tutorial_dialog.dart';

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
  final PageController _tutorialPageController = PageController();
  int _currentPage = 0;
  final List<String> _pages = [
    'assets/tutorial_1.jpg',
    'assets/tutorial_2.jpg',
    'assets/tutorial_3.jpg',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _tutorialPageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _tutorialPageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _tutorialPageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  /// 🔹 ค้นหาด้วยการพิมพ์
  Future<void> _goNextBySerch() async {
    final keyword = _searchController.text.trim();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LinkMedicinePage(
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
        builder: (_) => CameraOcrPage(
          draft: widget.draft,
          profileId: widget.profileId,
          isEdit: widget.isEdit,
          initialItem: widget.initialItem,
        ),
      ),
    );

    if (!mounted) return;

    if (result is MedicineItem) {
      Navigator.pop(context, result);
      return;
    }

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
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 234, 244, 255),
                Color.fromARGB(255, 193, 222, 255)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF5A81BB)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              pageTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2B4C7E),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.arrow_right_rounded,
                  size: 20,
                  color: Color(0xFF5A81BB),
                ),
                Text(
                  'ค้นหาข้อมูลยาที่เกี่ยวข้อง',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF5A81BB),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF0F6FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              const MedicineStepTimeline(currentStep: 2),
              const SizedBox(height: 24),
              const Text(
                'ค้นหารายการยาที่เกี่ยวข้อง',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2B4C7E),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ชื่อสามัญภาษาไทย/อังกฤษ หรือชื่อการค้า',
                  filled: true,
                  fillColor: const Color.fromARGB(255, 255, 255, 255),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon:
                      const Icon(Icons.search, color: Color(0xFF5A81BB)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _goNextBySerch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A81BB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.search, color: Colors.white),
                    label: const Text('ค้นหา',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _scanByCamera,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5A81BB),
                      side: const BorderSide(color: Color(0xFF5A81BB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label:
                        const Text('สแกนฉลาก', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 400,
                child: GestureDetector(
                  onTap: () => TutorialDialog.show(context, forceShow: true),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0F4F8),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'วิธีการเพิ่มยาด้วยการสแกนฉลาก',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B4C7E),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        /// 👇 กรอบรูป
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: Container(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  children: [
                                    PageView(
                                      controller: _tutorialPageController,
                                      onPageChanged: (index) {
                                        setState(() {
                                          _currentPage = index;
                                        });
                                      },
                                      children: _pages.map((path) {
                                        return Image.asset(
                                          path,
                                          fit: BoxFit.contain,
                                        );
                                      }).toList(),
                                    ),
                                    if (_currentPage > 0)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8),
                                          child: GestureDetector(
                                            onTap: _prevPage,
                                            child: const Icon(
                                                Icons.arrow_back_ios,
                                                size: 30,
                                                color: Colors.black87),
                                          ),
                                        ),
                                      ),
                                    if (_currentPage < _pages.length - 1)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: GestureDetector(
                                            onTap: _nextPage,
                                            child: const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 30,
                                                color: Colors.black87),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app,
                                  size: 16, color: Color(0xFF7A869A)),
                              SizedBox(width: 4),
                              Text(
                                'แตะเพื่อดูรายละเอียด',
                                style: TextStyle(
                                  color: Color(0xFF7A869A),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: _skipSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A81BB),
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

  Future<void> _skipSearch() async {
    MedicineCatalogItem? catalogToKeep;
    String preservedOfficialName = '';

    // ✅ ถ้าเป็นการแก้ไข และมีข้อมูลยาเดิม -> ดึงชื่อเดิมมาใช้ต่อ
    if (widget.isEdit && widget.initialItem != null) {
      if (widget.initialItem!.mediId > 0) {
        preservedOfficialName = widget.initialItem!.officialName_medi;
        catalogToKeep = MedicineCatalogItem(
          mediId: widget.initialItem!.mediId,
          mediThName: preservedOfficialName,
          mediTradeName: preservedOfficialName, // ใส่ทั้งคู่เพื่อความชัวร์
          mediPicture: widget.initialItem!.imagePath,
        );
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryMedicinePage(
          profileId: widget.profileId,
          draft: widget.draft.copyWith(
            searchQuery_medi: '',
            //✅ ส่งชื่อเป็น trade name ไปด้วยใน draft เพื่อให้หน้า Summary แสดงผลถูก
            officialName_medi: preservedOfficialName.isNotEmpty
                ? preservedOfficialName
                : widget.draft.officialName_medi,
            catalogItem: catalogToKeep,
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
