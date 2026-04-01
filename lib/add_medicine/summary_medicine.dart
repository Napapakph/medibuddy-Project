import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/widgets/medicine_step_timeline.dart';
import 'package:medibuddy/services/medicine_api.dart';
import '../search_medicine/detail_medicine.dart';
import '../add_medicine/medicine_list_screen.dart';
import '../set_remind/setRemind_screen.dart';
import '../OCR/ocr_global.dart';
import 'package:bot_toast/bot_toast.dart';

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
  MedicineCatalogItem? _fetchedCatalogItem;
  bool _fetchingInfo = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🏁 SummaryMedicinePage: initState called');
    debugPrint('   - Draft OfficialName: ${widget.draft.officialName_medi}');
    debugPrint('   - Catalog ID: ${widget.draft.catalogItem?.mediId}');

    // ✅ Check if we need to fetch medicine details (if we have ID but missing name)
    _checkAndFetchMedicineInfo();
  }

  Future<void> _checkAndFetchMedicineInfo() async {
    final draftCatalog = widget.draft.catalogItem;
    // Determine the MediID to use (from draft or initial item)
    final mediId = draftCatalog?.mediId ??
        (widget.isEdit ? widget.initialItem?.mediId : 0) ??
        0;

    if (mediId <= 0) return;

    // Check if we already have a good name
    final currentName = _resolveOfficialName(draftCatalog);
    if (currentName.isNotEmpty && currentName != '-' && currentName != 'null') {
      // If we generally have a name, we might skip.
      // But if user reported missing name, let's force fetch just in case
      // logic issues elsewhere.
      // However, to avoid excessive calls, let's verify if detailed info is missing.
    }

    setState(() => _fetchingInfo = true);

    try {
      final api = MedicineApi();
      final detail = await api.getMedicineDetail(mediId: mediId);

      if (mounted) {
        setState(() {
          // Convert MedicineDetail to MedicineCatalogItem
          _fetchedCatalogItem = MedicineCatalogItem(
            mediId: detail.mediId,
            mediThName: detail.mediThName,
            mediEnName: detail.mediEnName,
            mediTradeName: detail.mediTradeName,
            mediPicture: detail.mediPicture,
            // Map other fields if needed, but these are main ones for display
          );
        });
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch medicine info for ID $mediId: $e');
    } finally {
      if (mounted) setState(() => _fetchingInfo = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('🏁 SummaryMedicinePage: didChangeDependencies');
  }

  String _resolveOfficialName(MedicineCatalogItem? catalog) {
    // 1. Prefer fetched item if available
    if (_fetchedCatalogItem != null) {
      return _fetchedCatalogItem!.displayOfficialName;
    }

    // 2. Draft's explicit name
    if (widget.draft.officialName_medi.isNotEmpty) {
      return widget.draft.officialName_medi;
    }

    // 3. Catalog from draft
    if (catalog != null &&
        catalog.displayOfficialName.isNotEmpty &&
        catalog.displayOfficialName != '-') {
      return catalog.displayOfficialName;
    }

    // 4. Fallback to initialItem if editing (last resort)
    if (widget.isEdit && widget.initialItem != null) {
      if (widget.initialItem!.officialName_medi.isNotEmpty) {
        return widget.initialItem!.officialName_medi;
      }
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

  bool _isRemotePath(String path) {
    final trimmed = path.trim();
    return trimmed.startsWith('https://') ||
        trimmed.startsWith('/uploads') ||
        trimmed.startsWith('uploads/');
  }

  Future<void> _saveMedicine() async {
    if (_saving) return;

    // Prefer fetched item logic if available for final connection?
    // Actually we just need ID.
    final catalog = _fetchedCatalogItem ?? widget.draft.catalogItem;
    final hasCatalog = catalog != null && catalog.mediId > 0;

    setState(() => _saving = true);
    final isEditMode = widget.isEdit && widget.initialItem != null;

    final officialName = _resolveOfficialName(catalog);
    final nickname = _resolveNickname(officialName);
    final localImagePath = widget.draft.imagePath;

    // ✅ FIX: Only create File if it is a local path.
    // If it's a remote path (existing image), we send null to API (meaning no change/use existing).
    File? localImage;
    if (localImagePath.isNotEmpty && !_isRemotePath(localImagePath)) {
      localImage = File(localImagePath);
    }

    final displayImage = localImagePath.isNotEmpty
        ? localImagePath
        : (catalog?.mediPicture ?? '').trim();

    final localItem = MedicineItem(
      mediListId: isEditMode ? widget.initialItem!.mediListId : 0,
      id: catalog?.mediId?.toString() ??
          (isEditMode ? widget.initialItem!.mediListId.toString() : ''),
      nickname_medi: nickname,
      officialName_medi: officialName,
      imagePath: displayImage,
    );

    if (nickname.trim().isEmpty && officialName.trim().isEmpty) {
      if (!mounted) return;

      setState(() => _saving = false);
      return;
    }

    try {
      final api = MedicineApi();

      final res = isEditMode
          ? await api.updateMedicineListItem(
              mediListId: widget.initialItem!.mediListId,
              mediNickname: nickname,
              pictureFile: localImage, // Pass null if path is remote
              mediId: hasCatalog ? catalog!.mediId : null,
            )
          : await api.addMedicineToProfile(
              profileId: widget.profileId,
              mediId: hasCatalog ? catalog!.mediId : null,
              mediNickname: nickname,
              pictureFile: localImage,
            );

      final serverPath =
          (res['picture'] ?? res['data']?['imagePath'])?.toString().trim();
      final serverMediListId = _readInt(
        res['mediListId'] ??
            res['id'] ??
            res['data']?['mediListId'] ??
            res['data']?['id'],
      );

      final savedItem = localItem.copyWith(
        imagePath: (serverPath != null && serverPath.isNotEmpty)
            ? serverPath
            : localItem.imagePath,
        mediListId:
            serverMediListId > 0 ? serverMediListId : localItem.mediListId,
        id: serverMediListId > 0 ? serverMediListId.toString() : localItem.id,
      );

      if (!mounted) return;
      globalOcrImage = null;

      BotToast.showCustomText(
        duration: const Duration(seconds: 2),
        align: const Alignment(0, 0.5),
        toastBuilder: (_) {
          return Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 114, 178, 121),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'เพิ่มรายการยาสำเร็จ',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          );
        },
      );

      if (isEditMode) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ListMedicinePage(profileId: widget.profileId),
          ),
        );
        return;
      }

      await _goToSetReminder(savedItem);
    } catch (e) {
      if (!mounted) return;
      BotToast.showCustomNotification(
        align: const Alignment(0, -0.5),
        duration: const Duration(seconds: 2),
        toastBuilder: (_) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 195, 120, 134),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 8,
                        offset: Offset(0, 2),
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: const Text(
                    'รายการบันทึกไม่สำเร็จ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  Future<void> _goToSetReminder(MedicineItem savedItem) async {
    List<MedicineItem> medicines = [];
    try {
      medicines = await MedicineApi().fetchProfileMedicineList(
        profileId: widget.profileId,
      );
    } catch (_) {
      medicines = [];
    }

    MedicineItem initialMedicine = savedItem;
    if (medicines.isNotEmpty) {
      final matched = medicines.where((item) {
        if (savedItem.mediListId > 0) {
          return item.mediListId == savedItem.mediListId;
        }
        if (savedItem.id.isNotEmpty) {
          return item.id == savedItem.id;
        }
        return false;
      }).toList();
      if (matched.isNotEmpty) {
        initialMedicine = matched.first;
      }
    }

    final list = medicines.isNotEmpty ? medicines : [savedItem];
    final hasInitial = list.any((item) {
      if (initialMedicine.mediListId > 0) {
        return item.mediListId == initialMedicine.mediListId;
      }
      if (initialMedicine.id.isNotEmpty) {
        return item.id == initialMedicine.id;
      }
      return false;
    });
    if (!hasInitial) {
      list.add(initialMedicine);
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetRemindScreen(
          medicines: list,
          initialMedicine: initialMedicine,
        ),
      ),
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ListMedicinePage(profileId: widget.profileId),
      ),
    );
  }

  String toFullImageUrl(String raw) {
    try {
      final base = (dotenv.env['API_BASE_URL'] ?? '').trim();
      final p = raw.trim();

      if (p.isEmpty || p.toLowerCase() == 'null') return '';

      if (p.startsWith('http://') || p.startsWith('https://')) return p;

      if (base.isEmpty) return '';

      final baseUri = Uri.parse(base);
      final path = p.startsWith('/') ? p : '/$p';
      return baseUri.resolve(path).toString();
    } catch (e) {
      debugPrint('Error in toFullImageUrl: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = widget.isEdit ? 'แก้ไขรายการยา' : 'เพิ่มรายการยา';
    // Determine catalog item to use (prefer fetched)
    final catalog = _fetchedCatalogItem ?? widget.draft.catalogItem;

    final officialName = _resolveOfficialName(catalog);
    final nickname = _resolveNickname(officialName);
    final localImagePath = widget.draft.imagePath;

    // Use fetched picture if local/manual one is empty
    String catalogImage = '';
    try {
      final pic = (catalog?.mediPicture ?? '').trim();
      if (pic.isNotEmpty) {
        catalogImage = toFullImageUrl(pic);
      }
    } catch (e) {
      // ignore
    }

    // Determine if localImagePath is actually remote
    final isLocalImageRemote = _isRemotePath(localImagePath);

    return Scaffold(
      appBar: AppBar(
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
        title: const Text(
          'เพิ่มยา',
          style:
              TextStyle(color: Color(0xFF2B4C7E), fontWeight: FontWeight.w700),
        ),
      ),
      backgroundColor: const Color(0xFFF0F6FF),
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
                  fontSize: 16,
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
              Row(
                children: [
                  Text(
                    'ชื่อการค้า',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 5),
                  IconButton(
                    onPressed: () {
                      final mediId = catalog?.mediId ?? 0;

                      if (mediId <= 0) {
                        BotToast.showCustomNotification(
                          align: Alignment(0, -0.5),
                          duration: const Duration(seconds: 2),
                          toastBuilder: (_) {
                            return SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: Container(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 15),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                            255, 195, 120, 134),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                            color: Colors.black26,
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'ยังไม่มีการผูกข้อมูลยา',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                        return;
                      }

                      showMedicineDetailDialog(
                        context: context,
                        mediId: mediId,
                      );
                    },
                    icon: const Icon(Icons.info_outline,
                        color: Color(0xFF5A81BB)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Text(officialName),
                    if (_fetchingInfo)
                      const Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'รูปยา',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: localImagePath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: isLocalImageRemote
                            ? Image.network(
                                toFullImageUrl(localImagePath),
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
                              )
                            : Image.file(
                                File(localImagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons
                                          .broken_image, // Show different icon for local file error
                                      size: 64,
                                      color: Color.fromARGB(255, 255, 255, 255),
                                    ),
                                  );
                                },
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
                                    color: Color.fromARGB(255, 255, 255, 255),
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
                    backgroundColor: const Color(0xFF5A81BB),
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
