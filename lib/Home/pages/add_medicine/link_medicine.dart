import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/widgets/medicine_step_timeline.dart';
import 'package:medibuddy/services/medicine_api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'summary_medicine.dart';
import 'request_medicine_screen.dart';
import 'package:lottie/lottie.dart';
import '../set_remind/remind_list_screen.dart';

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
  List<MedicineItem> _existingMedicines = [];
  final List<MedicineCatalogItem> _items = [];
  MedicineCatalogItem? _selectedItem;

  bool _loading = true;
  String _errorMessage = '';

  bool _skipCatalogLink = false; // ✅ ไม่ผูกกับฐานข้อมูล
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _skipCatalogLink = widget.isEdit && (widget.initialItem?.mediId ?? 0) <= 0;

    // ✅ ถ้ามีคำค้นหาจากหน้าก่อนหน้า ให้ค้นหาทันที
    final initialSearch = widget.draft.searchQuery_medi;
    _searchController.text = initialSearch;
    _fetchList(search: initialSearch);

    // ✅ โหลดรายการยาที่มีอยู่มารอไว้เลย (ป้องกัน Delay/Hang ตอนกดปุ่ม)
    _loadExistingList();
  }

  Future<void> _loadExistingList() async {
    try {
      final list =
          await _api.fetchProfileMedicineList(profileId: widget.profileId);
      if (mounted) {
        setState(() {
          _existingMedicines = list;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Pre-load existing medicines failed: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearch() async {
    final keyword = _searchController.text.trim();
    await _fetchList(search: keyword);
  }

  Future<void> _fetchList({required String search}) async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final items = await _api.fetchMedicineCatalog(search: search);
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
    final query = _searchController.text.trim().toLowerCase();
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
    final q = _searchController.text.trim().toLowerCase();
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
    final query = _searchController.text.trim();
    //  if (query.isEmpty) return;

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
    try {
      debugPrint('🚀 _goNext started');
      // 1. ตรวจสอบการเลือกยา
      if (_selectedItem == null && !_skipCatalogLink) {
        debugPrint('⚠️ No item selected');
        return;
      }

      // 2. ถ้าเลือกยา -> ตรวจสอบว่ามีรายการยานี้อยู่แล้วหรือไม่ (ป้องกันซ้ำ)
      if (_selectedItem != null) {
        final selected = _selectedItem!;
        MedicineItem? duplicateItem;
        bool isDuplicate = false;

        debugPrint(
            '🔍 Checking duplicate for: ${selected.mediId} (${selected.displayOfficialName})');

        // ✅ ใช้ข้อมูลที่โหลดมารอเพื่อให้แน่ใจ (Safety Check)
        if (_existingMedicines.isEmpty) {
          debugPrint('⚠️ _existingMedicines is empty, trying to re-fetch...');
          try {
            _existingMedicines = await _api.fetchProfileMedicineList(
                profileId: widget.profileId);
            debugPrint('✅ Re-fetch done. Count: ${_existingMedicines.length}');
          } catch (e) {
            debugPrint('❌ Re-fetch failed: $e');
          }
        }

        try {
          final currentListId = widget.initialItem?.mediListId ?? 0;
          debugPrint(
              'ℹ️ Current List ID: $currentListId (EditMode: ${widget.isEdit})');

          // ใช้ Logic เดียวกับ onTap เพื่อความแม่นยำ
          // หาตัวที่ซ้ำ (ID ตรงกัน) และไม่ใช่ตัวเดิม (ListID ต่างกัน)
          final duplicates = _existingMedicines.where((ex) {
            // 1. Must match Catalog ID (Logic: Same Medicine)
            if (ex.mediId != selected.mediId) return false;

            // 2. Extra check for Edit Mode (Self Link)
            // ถ้าเป็นยาตัวเดิมที่กำลังแก้ไขอยู่ (ListID ตรงกัน) -> ถือว่าไม่ใช่ซ้ำ (อนุญาตให้เลือกตัวเองได้)
            if (ex.mediListId == currentListId) {
              debugPrint(
                  '   -> Ignoring Self (ListID: $currentListId) - Allowed to update self.');
              return false;
            }

            // 3. If match ID but diff ListID -> Real Duplicate
            return true;
          }).toList();

          if (duplicates.isNotEmpty) {
            isDuplicate = true;
            duplicateItem = duplicates.first;
            debugPrint(
                '🚨 Duplicate found: ${duplicateItem.nickname_medi} (ListID: ${duplicateItem.mediListId})');
          } else {
            debugPrint('✅ No duplicate found (or Self-Link allowed).');
          }
        } catch (e) {
          debugPrint('❌ Duplicate check error: $e');
        }

        // ถ้าเจอซ้ำ -> แจ้งเตือน + ถามว่าจะแก้ไขรายการเดิมไหม
        if (isDuplicate && duplicateItem != null && mounted) {
          debugPrint('🛑 Showing Duplicate Dialog');
          final action = await showDialog<int>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('มีการเชื่อมกับรายการในระบบตัวนี้แล้ว'),
              content: Text(
                  'ยา "${selected.displayOfficialName}"\n มีการเชื่อมกับรายการในระบบตัวนี้แล้ว\n\nคุณต้องการตั้งเวลาการทายาใหม่มั้ย?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 0), // ยกเลิก
                  child: const Text('ยกเลิก',
                      style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 1), // ตั้งเวลาใหม่
                  child: const Text(
                    'ตั้งเวลาใหม่',
                    style: TextStyle(color: Color(0xFF1F497D)),
                  ),
                ),
              ],
            ),
          );

          if (action == 1) {
            if (!mounted) return;
            debugPrint('👉 Action: Set New Reminder for Duplicate');
            try {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RemindListScreen(
                    medicines: [duplicateItem!],
                    initialMedicine: duplicateItem!,
                  ),
                ),
              );
            } catch (e) {
              debugPrint('❌ Navigation to RemindListScreen failed: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('เกิดข้อผิดพลาดในการเปิดหน้า: $e')),
              );
            }
          }
          // ไม่ว่าจะเลือกอะไร ก็หยุดการทำงาน ไม่ไปต่อ (เพราะซ้ำ)
          return;
        }
      }

      // 3. สร้าง Draft และไปหน้าสรุป (Summary)
      if (!mounted) return;
      debugPrint('📝 Preparing Draft...');
      final MedicineDraft draft;
      if (_selectedItem != null) {
        final selected = _selectedItem!;
        draft = widget.draft.copyWith(
          officialName_medi: selected.displayOfficialName,
          catalogItem: selected,
        );
      } else {
        draft = widget.draft.copyWith(
          catalogItem: null,
        );
      }
      debugPrint('📦 Draft prepared. OfficialName: ${draft.officialName_medi}');

      debugPrint('🚀 Pushing SummaryMedicinePage...');
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) {
            debugPrint(
                '🏗️ ADD_MED_PAGE: Building SummaryMedicinePage widget...');
            try {
              return SummaryMedicinePage(
                draft: draft,
                profileId: widget.profileId,
                isEdit: widget.isEdit,
                initialItem: widget.initialItem,
              );
            } catch (e) {
              debugPrint(
                  '❌ ADD_MED_PAGE: Error building SummaryMedicinePage: $e');
              rethrow;
            }
          },
        ),
      );

      debugPrint('🔙 Returned from Summary. Result: $result');
      if (!mounted) return;
      if (result is MedicineItem) {
        Navigator.pop(context, result);
      }
    } catch (e, stack) {
      debugPrint('❌ _goNext CRITICAL error: $e\n$stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
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
    final bubbleText = 'หายาไม่เจอหรอ? กดตรงนี้สิ';

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
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1F497D)
                            .withOpacity(0.12), // ⭐ สีเงา
                        blurRadius: 5, // ความฟุ้ง
                        spreadRadius: 1, // การกระจาย
                        offset: const Offset(0, 6), // ทิศทางเงา (ลงล่าง)
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          bubbleText,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.25,
                            color: Color(0xFF1F497D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: _goRequest,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
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
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = widget.isEdit ? 'แก้ไขรายการยา' : 'เพิ่มรายการยา';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF1F497D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              pageTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.arrow_right_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                Text(
                  'ตัวเลือกจากผลการค้นหา',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 227, 242, 255),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MedicineStepTimeline(currentStep: 3),
                  const SizedBox(height: 16),

                  Expanded(
                    child: Builder(
                      builder: (context) {
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
                                              "=========== ตรวจสอบยาในระบบที่ถูกใช้แล้ว =============");
                                          debugPrint(
                                              'Medi ID: ${item.mediId}, Name: ${item.displayOfficialName}');

                                          // Check duplicate immediately for debug
                                          try {
                                            final currentListId = widget
                                                    .initialItem?.mediListId ??
                                                0;
                                            debugPrint(
                                                'DEBUG: currentListId=$currentListId (Edit Mode: ${widget.isEdit})');

                                            // Check against existing items
                                            for (final ex
                                                in _existingMedicines) {
                                              if (ex.mediId == item.mediId) {
                                                debugPrint(
                                                    '  - Found Match: ID=${ex.mediId}, ListID=${ex.mediListId}');
                                                if (ex.mediListId ==
                                                    currentListId) {
                                                  debugPrint(
                                                      '    -> This is SELF (Ignored)');
                                                } else {
                                                  debugPrint(
                                                      '    -> This is DUPLICATE');
                                                }
                                              }
                                            }

                                            final isDuplicate =
                                                _existingMedicines.any((ex) {
                                              if (ex.mediId != item.mediId)
                                                return false;
                                              // Self check: same ListID
                                              if (ex.mediListId ==
                                                  currentListId) return false;
                                              return true;
                                            });

                                            if (isDuplicate) {
                                              debugPrint(
                                                  "=========== ตรวจสอบยาในระบบที่ถูกใช้แล้ว =============");
                                              debugPrint(
                                                  '✅ ยาตัวนี้ถูกใช้ไปแล้วใน Profile นี้ (${item.displayOfficialName})');
                                            }
                                          } catch (e) {
                                            debugPrint(
                                                '❌ Error checking duplicate in onTap: $e');
                                          }
                                        });
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF1F497D)
                                                : const Color(0xFFE0E6EF),
                                            width: isSelected ? 2 : 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
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
                                                          BorderRadius.circular(
                                                              12),
                                                      child: Image.network(
                                                        imagePath,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder:
                                                            (context, child,
                                                                progress) {
                                                          if (progress ==
                                                              null) {
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
                                                            color: Color(
                                                                0xFF1F497D),
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
                                                      fontWeight:
                                                          FontWeight.w600,
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
            if (_loading)
              Positioned.fill(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const ModalBarrier(
                      dismissible: false,
                      color: Colors.black26,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          'assets/lottie/loader_cat.json',
                          width: 180,
                          height: 180,
                          repeat: true,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'กำลังโหลด…',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
