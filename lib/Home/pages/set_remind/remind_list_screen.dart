import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/Model/medicine_regimen_model.dart';
import 'package:medibuddy/services/regimen_api.dart';
import 'setFuctionRemind.dart';
import 'setRemind_screen.dart';

class _ReminderPlanStore {
  static final Map<String, List<ReminderPlan>> _plansByMedicine = {};

  static List<ReminderPlan> allPlans() {
    return _plansByMedicine.values.expand((plans) => plans).toList();
  }

  static void upsertPlan(ReminderPlan plan, {String? previousMedicineId}) {
    final targetId = plan.medicine.id;

    if (previousMedicineId != null && previousMedicineId != targetId) {
      _removePlanById(previousMedicineId, plan.id);
    }

    final list = _plansByMedicine.putIfAbsent(targetId, () => []);
    final index = list.indexWhere((item) => item.id == plan.id);
    if (index == -1) {
      list.add(plan);
    } else {
      list[index] = plan;
    }
  }

  static void removePlan(ReminderPlan plan) {
    _removePlanById(plan.medicine.id, plan.id);
  }

  static void _removePlanById(String medicineId, String planId) {
    final list = _plansByMedicine[medicineId];
    if (list == null) return;
    list.removeWhere((item) => item.id == planId);
    if (list.isEmpty) {
      _plansByMedicine.remove(medicineId);
    }
  }
}

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
  List<ReminderPlan> _plans = [];
  MedicineItem? _selectedMedicine;
  final Set<String> _deletingPlanIds = {};
  bool _loading = false;
  String? _error;
  bool _hasFetched = false;
  List<MedicineRegimenItem> _serverItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialPlans != null) {
      for (final plan in widget.initialPlans!) {
        _ReminderPlanStore.upsertPlan(plan);
      }
    }

    _selectedMedicine = _resolveMedicine(widget.initialMedicine) ??
        (widget.medicines.isNotEmpty ? widget.medicines.first : null);
    _loadPlans();
    _fetchRegimens();
  }

  MedicineItem? _resolveMedicine(MedicineItem? medicine) {
    if (medicine == null) return null;
    return _resolveMedicineById(medicine.id) ?? medicine;
  }

  MedicineItem? _resolveMedicineById(String id) {
    for (final item in widget.medicines) {
      if (item.id == id) return item;
    }
    return null;
  }

  MedicineItem? _resolveMedicineByMediListId(int mediListId) {
    for (final item in widget.medicines) {
      if (item.mediListId == mediListId) return item;
    }
    return null;
  }

  MedicineItem _buildMedicineItemFromDetail(
    MedicineRegimenDetailResponse detail,
  ) {
    final list = detail.medicineList;
    final medicine = list?.medicine;
    final nickname = (list?.mediNickname ?? '').trim();
    final fallbackName = nickname.isNotEmpty
        ? nickname
        : (medicine?.mediThName.isNotEmpty ?? false)
            ? medicine!.mediThName
            : (medicine?.mediEnName ?? '');
    final officialName = (medicine?.mediThName.isNotEmpty ?? false)
        ? medicine!.mediThName
        : (medicine?.mediEnName.isNotEmpty ?? false)
            ? medicine!.mediEnName
            : nickname;

    final pictureOption = list?.pictureOption ?? '';
    final imagePath = pictureOption.trim().isNotEmpty
        ? pictureOption
        : (medicine?.mediPicture ?? '');

    return MedicineItem(
      mediListId: detail.mediListId,
      id: detail.mediListId.toString(),
      nickname_medi: fallbackName,
      officialName_medi: officialName,
      imagePath: imagePath,
    );
  }

  MedicineItem _buildMedicineItemFromListItem(
    MedicineRegimenItem item,
  ) {
    final list = item.medicineList;
    final medicine = list?.medicine;
    final nickname = (list?.mediNickname ?? '').trim();
    final fallbackName = nickname.isNotEmpty
        ? nickname
        : (medicine?.mediThName.isNotEmpty ?? false)
            ? medicine!.mediThName
            : (medicine?.mediEnName ?? '');
    final officialName = (medicine?.mediThName.isNotEmpty ?? false)
        ? medicine!.mediThName
        : (medicine?.mediEnName.isNotEmpty ?? false)
            ? medicine!.mediEnName
            : nickname;

    final pictureOption = list?.pictureOption ?? '';
    final imagePath = pictureOption.trim().isNotEmpty
        ? pictureOption
        : (medicine?.mediPicture ?? '');

    return MedicineItem(
      mediListId: item.mediListId,
      id: item.mediListId.toString(),
      nickname_medi: fallbackName,
      officialName_medi: officialName,
      imagePath: imagePath,
    );
  }

  int _currentMedicineListId() {
    final selected = _selectedMedicine;
    if (selected != null && selected.mediListId > 0) {
      return selected.mediListId;
    }
    final initial = widget.initialMedicine;
    if (initial != null && initial.mediListId > 0) {
      return initial.mediListId;
    }
    return 0;
  }

  Future<void> _fetchRegimens() async {
    final medicineListId = _currentMedicineListId();
    debugPrint('🧪 fetch regimens medicineListId=$medicineListId');

    if (medicineListId <= 0) {
      setState(() {
        _serverItems = [];
        _error = 'missing medicineListId';
        _hasFetched = true;
      });
      debugPrint('❌ fetch regimens error=$_error');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await RegimenApiService().getRegimensByMedicineListId(
        medicineListId: medicineListId,
      );
      if (!mounted) return;
      setState(() {
        _serverItems = res.items;
        _hasFetched = true;
      });
      debugPrint('🧪 fetched count=${_serverItems.length}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _hasFetched = true;
      });
      debugPrint('❌ fetch regimens error=$_error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  ReminderPlan _planFromServerItem(MedicineRegimenItem item) {
    final scheduleType = item.scheduleType.trim().toUpperCase();
    FrequencyPattern pattern;
    switch (scheduleType) {
      case 'DAILY':
        pattern = FrequencyPattern.everyDay;
        break;
      case 'WEEKLY':
        pattern = FrequencyPattern.someDays;
        break;
      case 'INTERVAL':
        pattern = FrequencyPattern.everyInterval;
        break;
      case 'CYCLE':
        pattern = FrequencyPattern.everyInterval;
        break;
      default:
        pattern = FrequencyPattern.everyDay;
    }

    final weekdays = pattern == FrequencyPattern.someDays
        ? parseDaysOfWeekRaw(item.daysOfWeekRaw)
        : <int>{};

    final doses = item.times
        .map(
          (time) => ReminderDose(
            time: _parseTimeOfDay(time.time),
            amount: _formatDoseAmount(time.dose),
            unit: _mapBackendUnitToUi(time.unit),
            mealTiming: _mealTimingFromRelation(time.mealRelation),
          ),
        )
        .toList();

    final effectiveDoses = doses.isNotEmpty
        ? doses
        : [ReminderDose(time: const TimeOfDay(hour: 8, minute: 0))];

    var everyCount = 1;
    const everyUnit = 'วัน';
    if (scheduleType == 'INTERVAL') {
      everyCount = item.intervalDays ?? 1;
    } else if (scheduleType == 'CYCLE') {
      everyCount = item.cycleOnDays ?? 1;
    }
    if (everyCount < 1) everyCount = 1;

    final hasEndDate = item.endDate != null && item.endDate!.trim().isNotEmpty;
    final durationMode =
        hasEndDate ? DurationMode.custom : DurationMode.forever;
    var durationValue = 1;
    var durationUnit = 'วัน';
    if (hasEndDate) {
      final start = DateTime.tryParse(item.startDate) ?? DateTime.now();
      final end = DateTime.tryParse(item.endDate!) ?? start;
      final diffDays = end.difference(start).inDays;
      durationValue = diffDays < 1 ? 1 : diffDays;
    }

    final resolved = _resolveMedicineByMediListId(item.mediListId) ??
        _buildMedicineItemFromListItem(item);

    return ReminderPlan(
      id: item.mediRegimenId.toString(),
      mediListId: item.mediListId,
      mediRegimenId: item.mediRegimenId,
      medicine: resolved,
      frequencyMode: FrequencyMode.timesPerDay,
      timesPerDay: effectiveDoses.length,
      everyHours: 6,
      frequencyPattern: pattern,
      weekdays: weekdays,
      everyCount: everyCount,
      everyUnit: everyUnit,
      durationMode: durationMode,
      durationValue: durationValue,
      durationUnit: durationUnit,
      startTime: effectiveDoses.first.time,
      doses: effectiveDoses,
    );
  }

  MealTiming _mealTimingFromRelation(String relation) {
    final normalized = relation.trim().toUpperCase();
    switch (normalized) {
      case 'BEFORE_MEAL':
        return MealTiming.beforeMeal;
      case 'AFTER_MEAL':
        return MealTiming.afterMeal;
      case 'NONE':
        return MealTiming.betweenMeals;
      default:
        return MealTiming.afterMeal;
    }
  }

  String _mapBackendUnitToUi(String unit) {
    final normalized = unit.trim().toLowerCase();
    switch (normalized) {
      case 'tablet':
        return 'เม็ด';
      case 'ml':
        return 'มิลลิลิตร';
      case 'mg':
        return 'มิลลิกรัม';
      case 'drop':
        return 'ยาหยอด';
      case 'injection':
        return 'เข็ม';
      default:
        return unit.trim().isEmpty ? 'เม็ด' : unit;
    }
  }

  String _formatDoseAmount(num dose) {
    if (dose % 1 == 0) {
      return dose.toInt().toString();
    }
    return dose.toString();
  }

  TimeOfDay _parseTimeOfDay(String value) {
    final parts = value.split(':');
    if (parts.length < 2) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(
      hour: hour.clamp(0, 23).toInt(),
      minute: minute.clamp(0, 59).toInt(),
    );
  }

  bool _sameMedicine(MedicineItem a, MedicineItem b) {
    return a.id == b.id &&
        a.nickname_medi == b.nickname_medi &&
        a.officialName_medi == b.officialName_medi &&
        a.imagePath == b.imagePath;
  }

  ReminderPlan _syncPlanMedicine(ReminderPlan plan) {
    final updated = _resolveMedicineById(plan.medicine.id);
    if (updated == null) return plan;
    if (_sameMedicine(updated, plan.medicine)) return plan;
    return plan.copyWith(medicine: updated);
  }

  void _loadPlans() {
    final stored = _ReminderPlanStore.allPlans();
    _plans = stored.map(_syncPlanMedicine).toList();

    for (final plan in _plans) {
      _ReminderPlanStore.upsertPlan(plan);
    }
  }

  List<ReminderPlan> get _filteredPlans {
    final selected = _selectedMedicine;
    if (selected == null) return _plans;

    return _plans.where((plan) => plan.medicine.id == selected.id).toList();
  }

  List<ReminderPlan> get _displayPlans {
    if (_error != null) return _filteredPlans;
    if (_hasFetched) {
      return _serverItems.map(_planFromServerItem).toList();
    }
    return _filteredPlans;
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
      _ReminderPlanStore.upsertPlan(result);
      setState(() {
        _selectedMedicine =
            _resolveMedicine(result.medicine) ?? _selectedMedicine;
        _loadPlans();
      });
    }
  }

  Future<void> _editPlan(ReminderPlan plan) async {
    if (plan.mediRegimenId == null) {
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
        _ReminderPlanStore.upsertPlan(
          result,
          previousMedicineId: plan.medicine.id,
        );
        setState(() {
          _selectedMedicine =
              _resolveMedicine(result.medicine) ?? _selectedMedicine;
          _loadPlans();
        });
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );

    MedicineRegimenDetailResponse detail;
    try {
      final api = RegimenApiService();
      detail = await api.getRegimenDetail(mediRegimenId: plan.mediRegimenId!);
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ โหลดข้อมูลไม่สำเร็จ: $e')),
      );
      return;
    }

    if (mounted) Navigator.of(context, rootNavigator: true).pop();
    if (!mounted) return;

    final resolved = _resolveMedicineByMediListId(detail.mediListId) ??
        _buildMedicineItemFromDetail(detail);
    final serverPlan = fromRegimenDetail(
      detail: detail,
      medicineItemResolvedFromList: resolved,
      localId: plan.id,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetRemindScreen(
          medicines: widget.medicines,
          initialPlan: serverPlan,
          reminderId: serverPlan.id,
          initialMedicine: resolved,
        ),
      ),
    );

    if (!mounted) return;
    if (result is ReminderPlan) {
      _ReminderPlanStore.upsertPlan(
        result,
        previousMedicineId: plan.medicine.id,
      );
      setState(() {
        _selectedMedicine =
            _resolveMedicine(result.medicine) ?? _selectedMedicine;
        _loadPlans();
      });
    }
  }

  Future<void> _deletePlan(ReminderPlan plan) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ลบแจ้งเตือน'),
          content: const Text('ต้องการลบการแจ้งเตือนนี้หรือไม่'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child:
                  const Text('ลบ', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || _deletingPlanIds.contains(plan.id)) return;

    setState(() => _deletingPlanIds.add(plan.id));

    if (plan.mediRegimenId == null) {
      debugPrint('⚠️ delete local only: missing mediRegimenId for ${plan.id}');
      _ReminderPlanStore.removePlan(plan);
      if (!mounted) return;
      setState(() {
        _deletingPlanIds.remove(plan.id);
        _loadPlans();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบเฉพาะในเครื่อง (ยังไม่ sync)')),
      );
      return;
    }

    try {
      final api = RegimenApiService();
      await api.deleteRegimen(mediRegimenId: plan.mediRegimenId!);
      if (!mounted) return;
      _ReminderPlanStore.removePlan(plan);
      setState(() {
        _deletingPlanIds.remove(plan.id);
        if (plan.mediRegimenId != null) {
          _serverItems.removeWhere(
              (item) => item.mediRegimenId == plan.mediRegimenId);
        }
        _loadPlans();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ ลบแจ้งเตือนสำเร็จ')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingPlanIds.remove(plan.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ลบไม่สำเร็จ: $e')),
      );
    }
  }

  Widget _buildReminderCard(ReminderPlan plan) {
    final image = buildMedicineImage(plan.medicine.imagePath);
    final isDeleting = _deletingPlanIds.contains(plan.id);

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
                      plan.medicine.nickname_medi,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                      child: Text(
                        'ปริมาณ ${dose.amount} ${dose.unit}',
                        textAlign: TextAlign.end,
                      ),
                    ),
                    const SizedBox(width: 8),
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
                onPressed: isDeleting ? null : () => _deletePlan(plan),
                icon: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete, size: 18),
                label: Text(isDeleting ? 'กำลังลบ...' : 'ลบแจ้งเตือน'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: isDeleting ? null : () => _editPlan(plan),
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
        child: Stack(
          children: [
            Padding(
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
                                  child: Text(
                                    item.nickname_medi,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedMedicine = value;
                              debugPrint('MedID : $value');
                            });
                            _fetchRegimens();
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
                          child: _displayPlans.isEmpty
                              ? const Center(
                                  child: Text('ยังไม่มีการแจ้งเตือน'),
                                )
                              : ListView.builder(
                                  itemCount: _displayPlans.length,
                                  itemBuilder: (context, index) =>
                                      _buildReminderCard(_displayPlans[index]),
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
                              style: TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            if (_loading)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.transparent,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
