import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/widgets/medicine_step_timeline.dart';
import 'package:medibuddy/services/medicine_api.dart';
import 'detail_medicine.dart';

class SummaryMedicinePage extends StatefulWidget {
  final MedicineDraft draft;
  final int profileId;
  final bool isEdit;
  final MedicineItem? initialItem;

  const SummaryMedicinePage({
    super.key,
    required this.draft,
    required this.profileId,
    this.isEdit = false,
    this.initialItem,
  });

  @override
  State<SummaryMedicinePage> createState() => _SummaryMedicinePageState();
}

class _SummaryMedicinePageState extends State<SummaryMedicinePage> {
  bool _saving = false;

  String _resolveOfficialName(MedicineCatalogItem? catalog) {
    if (widget.draft.officialName_medi.isNotEmpty) {
      return widget.draft.officialName_medi;
    }
    if (catalog != null && catalog.displayOfficialName.isNotEmpty) {
      return catalog.displayOfficialName;
    }
    return widget.draft.searchQuery_medi;
  }

  String _resolveNickname(String officialName) {
    if (widget.draft.nickname_medi.isNotEmpty) {
      return widget.draft.nickname_medi;
    }
    return officialName;
  }

  int _readInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<void> _saveMedicine() async {
    if (_saving) return;

    final catalog = widget.draft.catalogItem;
    final hasCatalog = catalog != null && catalog.mediId > 0;

    setState(() => _saving = true);
    final isEditMode = widget.isEdit && widget.initialItem != null;
// Debugging output ----------------------------------------------------------
    debugPrint(
        '================= check ProfileID & MedicineID  ==================');
    debugPrint('Profile ID: ${widget.profileId}');
    debugPrint('Medicine ID: ${catalog?.mediId}');
// ---------------------------------------------------------------------------

    final officialName = _resolveOfficialName(catalog);
    final nickname = _resolveNickname(officialName);
    final localImagePath = widget.draft.imagePath;
    final localImage = localImagePath.isEmpty ? null : File(localImagePath);
    final displayImage = localImagePath.isNotEmpty
        ? localImagePath
        : (catalog?.mediPicture ?? '').trim();

    final localItem = MedicineItem(
      mediListId: isEditMode ? widget.initialItem!.mediListId : 0,
      id: catalog?.mediId.toString() ?? '',
      nickname_medi: nickname,
      officialName_medi: officialName,
      imagePath: displayImage,
    );

    if (nickname.trim().isEmpty && officialName.trim().isEmpty) {
      // ต้องมีชื่ออย่างน้อย 1 อย่าง
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุชื่อยาหรือชื่อเล่นยา')),
      );
      setState(() => _saving = false);
      return;
    }

    try {
      final api = MedicineApi();

      final res = isEditMode
          ? await api.updateMedicineListItem(
              mediListId: widget.initialItem!.mediListId,
              mediNickname: nickname,
              pictureFile: localImage,
              mediId: hasCatalog ? catalog!.mediId : null, // ✅ PASS_MEDI_ID
            )
          : await api.addMedicineToProfile(
              profileId: widget.profileId,
              mediId: hasCatalog ? catalog!.mediId : null, // ✅ PASS_MEDI_ID
              mediNickname: nickname,
              pictureFile: localImage,
            );

// 🔥 FIX: try to read server image path (backend key may differ)
// ✅ NOTE: ปรับ key ให้ตรงกับ backend ของเดียร์ ถ้าไม่ตรงให้ดู log res แล้วแก้ key
      final serverPath =
          (res['picture'] ?? res['data']?['imagePath'])?.toString().trim();
      final serverMediListId = _readInt(
        res['mediListId'] ??
            res['id'] ??
            res['data']?['mediListId'] ??
            res['data']?['id'],
      );

// ✅ DEBUG: show what backend returned

      debugPrint('===========================================================');
      debugPrint('🧾 MED_CREATE response = $res');
      debugPrint('🖼️ serverPath = $serverPath');

// ✅ PROFILE_ID + MEDI_ID: keep local item but prefer server path if exists
      final savedItem = localItem.copyWith(
        imagePath: (serverPath != null && serverPath.isNotEmpty)
            ? serverPath // ✅ USE_SERVER_PATH
            : localItem.imagePath, // fallback
        mediListId:
            serverMediListId > 0 ? serverMediListId : localItem.mediListId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกยาสำเร็จ')),
      );

// ✅ RETURN: send updated item back to list
      Navigator.pop(context, savedItem);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกยาลง Database ไม่สำเร็จ: $e')),
      );
      // ⚠️ GUARD: do NOT pop on failure (prevent ghost items)
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  String toFullImageUrl(String raw) {
    final base = (dotenv.env['API_BASE_URL'] ?? '').trim();
    final p = raw.trim();

    if (p.isEmpty || p.toLowerCase() == 'null') return '';

    // ถ้าเป็น URL เต็มอยู่แล้ว
    if (p.startsWith('http://') || p.startsWith('https://')) return p;

    if (base.isEmpty) return '';

    final baseUri = Uri.parse(base);
    final path = p.startsWith('/') ? p : '/$p';
    return baseUri.resolve(path).toString();
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = widget.isEdit ? 'แก้ไขรายการยา' : 'เพิ่มรายการยา';
    final catalog = widget.draft.catalogItem;
    final officialName = _resolveOfficialName(catalog);
    final nickname = _resolveNickname(officialName);
    final localImagePath = widget.draft.imagePath;
    final catalogImage = toFullImageUrl((catalog?.mediPicture ?? '').trim());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F497D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'เพิ่มยา',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              final catalog = widget.draft.catalogItem;
              final mediId = catalog?.mediId ?? 0;

              if (mediId <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('ยังไม่มีข้อมูลยาในฐานระบบให้แสดงรายละเอียด')),
                );
                return;
              }

              showMedicineDetailDialog(
                context: context,
                mediId: mediId,
              );
            },
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 227, 242, 255),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MedicineStepTimeline(currentStep: 4),
              const SizedBox(height: 24),
              const Text(
                'ชื่อเล่นยา',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(nickname),
              ),
              const SizedBox(height: 12),
              const Text(
                'ชื่อการค้า',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(officialName),
              ),
              const SizedBox(height: 10),
              const Text(
                'รูปยา',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: localImagePath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(localImagePath),
                          fit: BoxFit.cover,
                        ),
                      )
                    : catalogImage.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              catalogImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.photo,
                                    size: 64,
                                    color: Color(0xFF9AA7B8),
                                  ),
                                );
                              },
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.photo,
                              size: 64,
                              color: Color(0xFF9AA7B8),
                            ),
                          ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveMedicine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F497D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
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
