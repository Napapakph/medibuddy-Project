import 'dart:io';

import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/widgets/medicine_step_timeline.dart';
import 'package:medibuddy/services/medicine_api.dart';

import 'detail_medicine.dart';

class SummaryMedicinePage extends StatefulWidget {
  final MedicineDraft draft;
  final int profileId;

  const SummaryMedicinePage({
    super.key,
    required this.draft,
    required this.profileId,
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

  Future<void> _saveMedicine() async {
    if (_saving) return;

    final catalog = widget.draft.catalogItem;
    if (catalog == null || catalog.mediId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('?????????????????????')),
      );
      return;
    }

    setState(() => _saving = true);

    final officialName = _resolveOfficialName(catalog);
    final nickname = _resolveNickname(officialName);
    final localImagePath = widget.draft.imagePath;
    final localImage =
        localImagePath.isEmpty ? null : File(localImagePath);
    final displayImage =
        localImagePath.isNotEmpty ? localImagePath : catalog.imageUrl;

    final localItem = MedicineItem(
      id: catalog.mediId.toString(),
      nickname_medi: nickname,
      officialName_medi: officialName,
      imagePath: displayImage,
    );

    try {
      final api = MedicineApi();
      await api.addMedicineToProfile(
        profileId: widget.profileId,
        mediId: catalog.mediId,
        mediNickname: nickname,
        pictureFile: localImage,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('???????????????????????')),
      );
      Navigator.pop(context, localItem);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('???????????????: $e'),
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
    final catalog = widget.draft.catalogItem;
    final officialName = _resolveOfficialName(catalog);
    final nickname = _resolveNickname(officialName);
    final localImagePath = widget.draft.imagePath;
    final catalogImage = catalog?.imageUrl.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F497D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '????????????',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showMedicineDetailDialog(
                context: context,
                catalog: catalog,
                nickname: nickname,
              );
            },
            icon: const Icon(Icons.info_outline, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MedicineStepTimeline(currentStep: 4),
              const SizedBox(height: 24),
              const Text(
                '????????????',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F497D),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '??????????????',
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
                  color: const Color(0xFFF2F4F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(officialName),
              ),
              const SizedBox(height: 12),
              const Text(
                '??????????',
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
                  color: const Color(0xFFF2F4F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(nickname),
              ),
              const SizedBox(height: 16),
              const Text(
                '?????',
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
                          '??????',
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
