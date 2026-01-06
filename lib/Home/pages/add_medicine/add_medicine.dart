import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/widgets/medicine_step_timeline.dart';

import 'summary_medicine.dart';

class AddMedicinePage extends StatefulWidget {
  final MedicineDraft draft;

  const AddMedicinePage({
    super.key,
    required this.draft,
  });

  @override
  State<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends State<AddMedicinePage> {
  final List<String> _options = const [
    'TYLENOL 500 (paracetamol 500 mg)',
    'TYLENOL 200 (paracetamol 200 mg)',
    'Cetirizine 10 mg',
    'Ibuprofen 400 mg',
  ];

  int? _selectedIndex;

  Future<void> _goNext() async {
    // ไปหน้าสรุป
    if (_selectedIndex == null) return;

    final selectedName = _options[_selectedIndex!];
    final draft = widget.draft.copyWith(selectedName: selectedName);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryMedicinePage(draft: draft),
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
              const Text(
                'ตัวเลือกจากผลการค้นหา',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F497D),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _selectedIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
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
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9EEF6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.medication,
                                color: Color(0xFF1F497D),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _options[index],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedIndex == null ? null : _goNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F497D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'ถัดไป',
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
