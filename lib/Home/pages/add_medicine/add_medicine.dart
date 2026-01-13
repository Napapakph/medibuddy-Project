import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/widgets/medicine_step_timeline.dart';
import 'package:medibuddy/services/medicine_api.dart';

import 'summary_medicine.dart';
import 'request_medicine.dart';

class AddMedicinePage extends StatefulWidget {
  final MedicineDraft draft;
  final int profileId;

  const AddMedicinePage({
    super.key,
    required this.draft,
    required this.profileId,
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
  bool _shownNotFoundDialog = false;
  late final String _searchQuery;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.draft.searchQuery_medi;
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
      final enName = item.mediEnName.toLowerCase();
      final tradeName = item.mediTradeName.toLowerCase();
      final thName = item.mediThName.toLowerCase();
      return enName.startsWith(query) ||
          tradeName.startsWith(query) ||
          thName.startsWith(query);
    }).toList();
  }

  void _maybeShowNotFoundDialog(List<MedicineCatalogItem> filtered) {
    final query = _searchQuery.trim();
    if (query.isEmpty) return;
    if (_loading || _errorMessage.isNotEmpty) return;
    if (filtered.isNotEmpty) return;
    if (_shownNotFoundDialog) return;

    _shownNotFoundDialog = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showNotFoundDialog(query);
    });
  }

  Future<void> _showNotFoundDialog(String query) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ไม่พบรายการยา'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('ต้องการส่งคำขอเพิ่มรายการยานี้ไปยังระบบหรือไม่ ?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RequestMedicinePage(
                      medicineName: query,
                    ),
                  ),
                );
              },
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _goNext() async {
    if (_selectedItem == null) return;

    final selected = _selectedItem!;
    final draft = widget.draft.copyWith(
      officialName_medi: selected.displayOfficialName,
      catalogItem: selected,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryMedicinePage(
          draft: draft,
          profileId: widget.profileId,
        ),
      ),
    );

    if (!mounted) return;
    if (result is MedicineItem) {
      Navigator.pop(context, result);
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MedicineStepTimeline(currentStep: 3),
              const SizedBox(height: 24),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (_loading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
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
                    _maybeShowNotFoundDialog(filtered);

                    if (filtered.isEmpty) {
                      return const Center(
                          child: Column(
                        children: [
                          Text(
                            'ไม่พบรายการยา',
                            style: TextStyle(color: Color(0xFF7A869A)),
                          ),
                        ],
                      ));
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = _selectedItem?.mediId == item.mediId;
                        final imageUrl = item.imageUrl.trim();

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedItem = item;
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9EEF6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: imageUrl.isEmpty
                                      ? const Icon(
                                          Icons.medication,
                                          color: Color(0xFF1F497D),
                                        )
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.medication,
                                                color: Color(0xFF1F497D),
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
                                        'ชื่อสามัญ : ${item.mediEnName.isNotEmpty ? item.mediEnName : '-'}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ชื่อการค้า : ${item.mediTradeName.isNotEmpty ? item.mediTradeName : '-'}',
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
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
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
