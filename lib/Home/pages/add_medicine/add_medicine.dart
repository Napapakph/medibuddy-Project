import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/widgets/medicine_step_timeline.dart';
import 'package:medibuddy/services/medicine_api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'summary_medicine.dart';
import 'request_medicine.dart';

class AddMedicinePage extends StatefulWidget {
  final MedicineDraft draft;
  final int profileId;
  final bool isEdit;
  final MedicineItem? initialItem;

  const AddMedicinePage({
    super.key,
    required this.draft,
    required this.profileId,
    this.isEdit = false,
    this.initialItem,
  });

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final MedicineApi _api = MedicineApi();
  final List<MedicineCatalogItem> _items = [];
  MedicineCatalogItem? _selectedItem;

  bool _loading = true;
  String _errorMessage = '';

  bool _skipCatalogLink = false; // ✅ ไม่ผูกกับฐานข้อมูล
  late final String _searchQuery;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.draft.searchQuery_medi.isNotEmpty
        ? widget.draft.searchQuery_medi
        : (widget.isEdit ? (widget.initialItem?.officialName_medi ?? '') : '');

    _skipCatalogLink = widget.isEdit && (widget.initialItem?.mediId ?? 0) <= 0;
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final items = await _api.fetchMedicineCatalog(search: _searchQuery);
      if (!mounted) return;

      setState(() {
        _items
          ..clear()
          ..addAll(items);

        // ✅ ถ้าเป็น edit และเดิมผูกไว้ ให้ pre-select item เดิม
        if (!_skipCatalogLink &&
            _selectedItem == null &&
            widget.isEdit &&
            widget.initialItem != null &&
            widget.initialItem!.mediId > 0) {
          final initialId = widget.initialItem!.mediId;
          for (final item in items) {
            if (item.mediId == initialId) {
              _selectedItem = item;
              break;
            }
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  List<MedicineCatalogItem> _filteredItems() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return List<MedicineCatalogItem>.from(_items);

    return _items.where((item) {
      final enName = (item.mediEnName ?? '').toLowerCase();
      final tradeName = (item.mediTradeName ?? '').toLowerCase();
      final thName = (item.mediThName ?? '').toLowerCase();
      return enName.startsWith(query) ||
          tradeName.startsWith(query) ||
          thName.startsWith(query);
    }).toList();
  }

  bool _hasExactMatch(List<MedicineCatalogItem> filtered) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return true; // ไม่ search ก็ถือว่าไม่ต้องโชว์โหมด notfound

    for (final item in filtered) {
      final en = (item.mediEnName ?? '').trim().toLowerCase();
      final trade = (item.mediTradeName ?? '').trim().toLowerCase();
      final th = (item.mediThName ?? '').trim().toLowerCase();

      if (en == q || trade == q || th == q) return true;
    }
    return false;
  }

  void _goRequest() {
    final query = _searchQuery.trim();
    if (query.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestMedicinePage(
          medicineName: query,
        ),
      ),
    );
  }

  Future<void> _goNext() async {
    // ✅ ถ้าไม่ skip ต้องเลือกยา
    if (!_skipCatalogLink && _selectedItem == null) return;

    final MedicineDraft draft;
    if (_skipCatalogLink) {
      // ✅ ไม่ผูกกับฐานข้อมูล → ส่ง catalogItem = null
      draft = widget.draft.copyWith(
        catalogItem: null,
      );
    } else {
      final selected = _selectedItem!;
      draft = widget.draft.copyWith(
        officialName_medi: selected.displayOfficialName,
        catalogItem: selected,
      );
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryMedicinePage(
          draft: draft,
          profileId: widget.profileId,
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

  String toFullImageUrl(String raw) {
    final base = (dotenv.env['API_BASE_URL'] ?? '').trim();
    final p = raw.trim();

    if (p.isEmpty || p.toLowerCase() == 'null') return '';

    // ถ้าเป็น URL เต็มอยู่แล้ว
    if (p.startsWith('http://') || p.startsWith('https://')) return p;

    if (base.isEmpty) return '';

    try {
      final baseUri = Uri.parse(base);
      final path = p.startsWith('/') ? p : '/$p';
      return baseUri.resolve(path).toString();
    } catch (e) {
      debugPrint('❌ image url build failed: base=$base raw=$raw err=$e');
      return '';
    }
  }

  Widget _buildHelperZone({
    required bool onlyHelper,
    required bool showRequestHint,
  }) {
    // โซน “แมวผู้ช่วยนำทาง” (เดียร์จะเปลี่ยนไอคอนเป็นรูปเองทีหลังได้)
    // - ไอคอนอยู่ชิดขอบขวา
    // - บอลลูนเป็นปุ่มกด ส่งคำร้อง
    final bubbleText = 'หายาไม่เจอใช่มัย!?\nกดตรงนี้สิ';

    return Padding(
      padding: EdgeInsets.only(
        top: onlyHelper ? 12 : 8,
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // บอลลูนคำพูด (เป็นปุ่ม)
          Expanded(
            child: Opacity(
              opacity: showRequestHint ? 1.0 : 0.85,
              child: InkWell(
                onTap: _goRequest,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFD2E6FF)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          bubbleText,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.25,
                            color: Color(0xFF1F497D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.touch_app,
                        color: Color(0xFF1F497D),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ไอคอนชิดขอบขวา (placeholder)
          // เดียร์เปลี่ยนเป็นรูป/asset ภายหลังได้
          InkWell(
            onTap: _goRequest,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1F497D),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.pets,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = widget.isEdit ? 'แก้ไขรายการยา' : 'เพิ่มรายการยา';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F497D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          pageTitle,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 227, 242, 255),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MedicineStepTimeline(currentStep: 3),
              const SizedBox(height: 16),

              Expanded(
                child: Builder(
                  builder: (context) {
                    if (_loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (_errorMessage.isNotEmpty) {
                      return Center(
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF7A869A)),
                        ),
                      );
                    }

                    final filtered = _filteredItems();
                    final hasAny = filtered.isNotEmpty;
                    final exact = _hasExactMatch(filtered);

                    // เงื่อนไขตามที่เดียร์ต้องการ:
                    // - ถ้าไม่มีชื่อใกล้เคียงเลย: แสดงแค่แมว (no list)
                    // - ถ้ามี list: แสดง list ด้านบน + แมวด้านล่าง
                    // - ถ้าค้นหาแล้ว "ไม่ตรงชื่อ" (ไม่มี exact match): ให้เห็นโซนส่งคำร้องชัด ๆ
                    final onlyHelper = !hasAny;
                    final showRequestHint = !exact || !hasAny;

                    return Column(
                      children: [
                        // ===== โซนบน: list =====
                        if (!onlyHelper)
                          Expanded(
                            child: ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final isSelected =
                                    _selectedItem?.mediId == item.mediId;

                                final imagePath =
                                    toFullImageUrl(item.mediPicture ?? '');

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedItem = item;
                                      debugPrint(
                                          'Medi ID: ${item.mediId}, Name: ${item.displayOfficialName}');
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF1F497D)
                                            : const Color(0xFFE0E6EF),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE9EEF6),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: imagePath.isEmpty
                                              ? const Icon(
                                                  Icons.medication,
                                                  color: Color(0xFF1F497D),
                                                )
                                              : ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.network(
                                                    imagePath,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context,
                                                        child, progress) {
                                                      if (progress == null) {
                                                        return child;
                                                      }
                                                      return const Center(
                                                        child: SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child:
                                                              CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      debugPrint(
                                                          '❌ Image load failed: $imagePath');
                                                      return const Icon(
                                                        Icons.medication,
                                                        color:
                                                            Color(0xFF1F497D),
                                                      );
                                                    },
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'ชื่อสามัญ : ${(item.mediEnName ?? '').isNotEmpty ? item.mediEnName : '-'}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'ชื่อการค้า : ${(item.mediTradeName ?? '').isNotEmpty ? item.mediTradeName : '-'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF5E6C84),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF1F497D),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        // ===== โซนล่าง: แมว + บอลลูนกดส่งคำร้อง =====
                        _buildHelperZone(
                          onlyHelper: onlyHelper,
                          showRequestHint: showRequestHint,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ปุ่มยืนยัน: ตามเดิม (ต้องเลือก item ก่อน)
              // หมายเหตุ: ถ้าเดียร์อยากให้ "ไม่ผูก" แล้วไปต่อได้ด้วย
              // ค่อยเพิ่ม toggle แยก (เดี๋ยวฉันทำให้ได้)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedItem == null ? null : _goNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F497D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
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
