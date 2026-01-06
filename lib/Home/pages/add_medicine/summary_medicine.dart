import 'dart:io';

import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/widgets/medicine_step_timeline.dart';

class SummaryMedicinePage extends StatelessWidget {
  final MedicineDraft draft;

  const SummaryMedicinePage({
    super.key,
    required this.draft,
  });

  @override
  Widget build(BuildContext context) {
    final selectedName = draft.selectedName.isEmpty
        ? draft.displayName
        : draft.selectedName;

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
              const MedicineStepTimeline(currentStep: 4),
              const SizedBox(height: 24),
              const Text(
                'บันทึกข้อมูลยา',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F497D),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ชื่อการค้ายา',
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
                child: Text(selectedName),
              ),
              const SizedBox(height: 12),
              const Text(
                'ชื่อยาที่ตั้ง',
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
                child: Text(draft.displayName),
              ),
              const SizedBox(height: 16),
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
                child: draft.imagePath.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.photo,
                          size: 60,
                          color: Color(0xFF9AA7B8),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(draft.imagePath),
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final item = MedicineItem(
                      displayName: draft.displayName,
                      selectedName: selectedName,
                      imagePath: draft.imagePath,
                    );
                    Navigator.pop(context, item);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F497D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'บันทึก',
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
