import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';

import 'setFuctionRemind.dart';
import 'setRemind_screen.dart';

class RemindListScreen extends StatefulWidget {
  final List<MedicineItem> medicines;
  final MedicineItem? initialMedicine;
  final List<ReminderPlan>? initialPlans;

  const RemindListScreen({
    super.key,
    required this.medicines,
    this.initialMedicine,
    this.initialPlans,
  });

  @override
  State<RemindListScreen> createState() => _RemindListScreenState();
}

class _RemindListScreenState extends State<RemindListScreen> {
  late List<ReminderPlan> _plans;
  MedicineItem? _selectedMedicine;

  @override
  void initState() {
    super.initState();
    _plans = List<ReminderPlan>.from(widget.initialPlans ?? []);
    _selectedMedicine = widget.initialMedicine ??
        (widget.medicines.isNotEmpty ? widget.medicines.first : null);
  }

  List<ReminderPlan> get _filteredPlans {
    final selected = _selectedMedicine;
    if (selected == null) return _plans;

    return _plans.where((plan) => plan.medicine == selected).toList();
  }

  Future<void> _addPlan() async {
    if (widget.medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีรายการยา')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetRemindScreen(
          medicines: widget.medicines,
          initialMedicine: _selectedMedicine,
        ),
      ),
    );

    if (!mounted) return;
    if (result is ReminderPlan) {
      setState(() {
        _plans.add(result);
        _selectedMedicine ??= result.medicine;
      });
    }
  }

  Future<void> _editPlan(ReminderPlan plan) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetRemindScreen(
          medicines: widget.medicines,
          initialPlan: plan,
          reminderId: plan.id,
          initialMedicine: plan.medicine,
        ),
      ),
    );

    if (!mounted) return;
    if (result is ReminderPlan) {
      setState(() {
        final index = _plans.indexWhere((item) => item.id == plan.id);
        if (index != -1) {
          _plans[index] = result;
        }
      });
    }
  }

  void _deletePlan(ReminderPlan plan) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ลบแจ้งเตือน'),
          content: const Text('ต้องการลบการแจ้งเตือนนี้หรือไม่'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _plans.removeWhere((item) => item.id == plan.id);
                });
              },
              child:
                  const Text('ลบ', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReminderCard(ReminderPlan plan) {
    final image = buildMedicineImage(plan.medicine.imagePath);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E3F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3EAF6),
                  borderRadius: BorderRadius.circular(12),
                  image: image != null
                      ? DecorationImage(image: image, fit: BoxFit.cover)
                      : null,
                ),
                child: image == null
                    ? const Icon(Icons.medication, color: Color(0xFF1F497D))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.medicine.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.frequencyLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1F497D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ระยะเวลา ${plan.durationLabel}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7C93),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: plan.doses.map((dose) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        formatTime(dose.time),
                        style: const TextStyle(
                          color: Color(0xFF1F497D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('ปริมาณ ${dose.amount} ${dose.unit}'),
                    ),
                    MealTimingIcon(timing: dose.mealTiming),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _deletePlan(plan),
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('ลบแจ้งเตือน'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _editPlan(plan),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('แก้ไขแจ้งเตือน'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F497D),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB7DAFF),
        centerTitle: true,
        title: const Text(
          'รายการแจ้งเตือนทานยา',
          style: TextStyle(
            color: Color(0xFF1F497D),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: widget.medicines.isEmpty
              ? const Center(child: Text('ยังไม่มีรายการยา'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<MedicineItem>(
                      value: _selectedMedicine,
                      isExpanded: true,
                      hint: const Text('เลือกรายการยา'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: widget.medicines
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMedicine = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'รายละเอียดการรับประทานยา',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _filteredPlans.isEmpty
                          ? const Center(
                              child: Text('ยังไม่มีการแจ้งเตือน'),
                            )
                          : ListView.builder(
                              itemCount: _filteredPlans.length,
                              itemBuilder: (context, index) =>
                                  _buildReminderCard(_filteredPlans[index]),
                            ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addPlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F497D),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'เพิ่มการแจ้งเตือน',
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
