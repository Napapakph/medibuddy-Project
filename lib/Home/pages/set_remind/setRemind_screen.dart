import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';

import '../../../services/regimen_api.dart';
import 'setFuctionRemind.dart';

class SetRemindScreen extends StatefulWidget {
  final List<MedicineItem> medicines;
  final MedicineItem? initialMedicine;
  final ReminderPlan? initialPlan;
  final String? reminderId;

  const SetRemindScreen({
    super.key,
    required this.medicines,
    this.initialMedicine,
    this.initialPlan,
    this.reminderId,
  });

  @override
  State<SetRemindScreen> createState() => _SetRemindScreenState();
}

class _SetRemindScreenState extends State<SetRemindScreen> {
  final PageController _pageController = PageController();
  int _stepIndex = 0;

  late MedicineItem? _selectedMedicine;
  FrequencyMode _frequencyMode = FrequencyMode.timesPerDay;
  FrequencyPattern _frequencyPattern = FrequencyPattern.everyDay;
  DurationMode _durationMode = DurationMode.forever;

  final Set<int> _selectedWeekdays = {1, 2, 3, 4, 5, 6, 7};

  int _timesPerDay = 3;
  int _everyHours = 6;
  int _everyCount = 1;
  String _everyUnit = 'วัน';

  int _durationValue = 1;
  String _durationUnit = 'สัปดาห์';

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _regimenStartDate = DateTime.now();
  DateTime? _regimenEndDate;
  List<ReminderDose> _doses = [];

  late TextEditingController _timesPerDayController;
  late TextEditingController _everyHoursController;
  late TextEditingController _everyCountController;
  late TextEditingController _durationValueController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _selectedMedicine = _resolveMedicine(widget.initialMedicine) ??
        (widget.medicines.isNotEmpty ? widget.medicines.first : null);

    _timesPerDayController = TextEditingController(text: '3');
    _everyHoursController = TextEditingController(text: '6');
    _everyCountController = TextEditingController(text: '1');
    _durationValueController = TextEditingController(text: '1');

    if (widget.initialPlan != null) {
      _applyInitialPlan(widget.initialPlan!);
    } else {
      _syncDoseCount(_timesPerDay);
    }

    _timesPerDayController
        .addListener(() => _updateTimesPerDay(_timesPerDayController.text));
    _everyHoursController
        .addListener(() => _updateEveryHours(_everyHoursController.text));
    _everyCountController
        .addListener(() => _updateEveryCount(_everyCountController.text));
    _durationValueController
        .addListener(() => _updateDurationValue(_durationValueController.text));
  }

  MedicineItem? _resolveMedicine(MedicineItem? medicine) {
    if (medicine == null) return null;
    for (final item in widget.medicines) {
      if (item.id == medicine.id) return item;
    }
    return medicine;
  }

  void _applyInitialPlan(ReminderPlan plan) {
    _selectedMedicine = _resolveMedicine(plan.medicine);
    _frequencyMode = plan.frequencyMode;
    _frequencyPattern = plan.frequencyPattern;
    _durationMode = plan.durationMode;

    _timesPerDay = plan.timesPerDay;
    _everyHours = plan.everyHours;
    _everyCount = plan.everyCount;
    _everyUnit = plan.everyUnit;

    _durationValue = plan.durationValue;
    _durationUnit = plan.durationUnit;
    _startTime = plan.startTime;
    _regimenStartDate = plan.regimenStartDate ?? DateTime.now();
    _regimenEndDate = plan.regimenEndDate;

    _selectedWeekdays
      ..clear()
      ..addAll(plan.weekdays);

    _timesPerDayController.text = _timesPerDay.toString();
    _everyHoursController.text = _everyHours.toString();
    _everyCountController.text = _everyCount.toString();
    _durationValueController.text = _durationValue.toString();

    _doses = plan.doses
        .map((dose) => ReminderDose(
              time: dose.time,
              amount: dose.amount,
              unit: dose.unit,
              mealTiming: dose.mealTiming,
            ))
        .toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timesPerDayController.dispose();
    _everyHoursController.dispose();
    _everyCountController.dispose();
    _durationValueController.dispose();
    super.dispose();
  }

  void _syncDoseCount(int count) {
    if (count < 1) count = 1;
    final updated = List<ReminderDose>.from(_doses);

    while (updated.length < count) {
      updated.add(ReminderDose(time: _defaultTimeForIndex(updated.length)));
    }
    if (updated.length > count) {
      updated.removeRange(count, updated.length);
    }

    _doses = updated;
  }

  TimeOfDay _defaultTimeForIndex(int index) {
    final hour = (7 + (index * 5)) % 24;
    return TimeOfDay(hour: hour, minute: 0);
  }

  void _updateTimesPerDay(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    final safe = parsed < 1 ? 1 : parsed;
    setState(() {
      _timesPerDay = safe;
      if (_frequencyMode == FrequencyMode.timesPerDay)
        _syncDoseCount(_timesPerDay);
    });
  }

  void _updateEveryHours(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    setState(() => _everyHours = parsed < 1 ? 1 : parsed);
  }

  void _updateEveryCount(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    setState(() => _everyCount = parsed < 1 ? 1 : parsed);
  }

  void _updateDurationValue(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    setState(() => _durationValue = parsed < 1 ? 1 : parsed);
  }

  void _setFrequencyMode(FrequencyMode mode) {
    setState(() {
      _frequencyMode = mode;
      if (_frequencyMode == FrequencyMode.everyHours) {
        _syncDoseCount(1);
      } else {
        _syncDoseCount(_timesPerDay);
      }
    });
  }

  void _nextStep() {
    if (_stepIndex >= 2) return;
    setState(() => _stepIndex += 1);
    _pageController.animateToPage(
      _stepIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    if (_stepIndex == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => _stepIndex -= 1);
    _pageController.animateToPage(
      _stepIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _savePlan() async {
    if (_saving) return;

    final selected = _selectedMedicine;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรายการยา')),
      );
      return;
    }

    if (selected.mediListId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบ mediListId ของรายการยานี้')),
      );
      return;
    }

    if (_doses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากำหนดเวลาอย่างน้อย 1 เวลา')),
      );
      return;
    }

    if (_frequencyPattern == FrequencyPattern.someDays &&
        _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกวันอย่างน้อย 1 วัน')),
      );
      return;
    }

    if (_frequencyPattern == FrequencyPattern.everyInterval) {
      final interval = intervalDaysFrom(_everyCount, _everyUnit);
      if (interval < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ช่วงวันต้องมากกว่า 0')),
        );
        return;
      }
    }

    final id = widget.reminderId ??
        widget.initialPlan?.id ??
        DateTime.now().microsecondsSinceEpoch.toString();

    final plan = ReminderPlan(
      id: id,
      mediListId: selected.mediListId,
      mediRegimenId: widget.initialPlan?.mediRegimenId,
      medicine: selected,
      frequencyMode: _frequencyMode,
      timesPerDay: _timesPerDay,
      everyHours: _everyHours,
      frequencyPattern: _frequencyPattern,
      weekdays: Set<int>.from(_selectedWeekdays),
      everyCount: _everyCount,
      everyUnit: _everyUnit,
      durationMode: _durationMode,
      durationValue: _durationValue,
      durationUnit: _durationUnit,
      startTime: _startTime,
      doses: _doses,
      regimenStartDate: _regimenStartDate,
      regimenEndDate: _regimenEndDate,
    );

    setState(() => _saving = true);

    try {
      final input = buildRegimenCreateInput(plan);

      debugPrint('===== DATE DEBUG =====');
      debugPrint('Local Start Date: ${_regimenStartDate.toIso8601String()}');
      debugPrint('Sent startDateUtc: ${input.startDateUtc}');
      debugPrint('Schedule Type: ${input.scheduleType}');
      debugPrint('======================');
      final api = RegimenApiService();
      final hasRegimenId = plan.mediRegimenId != null;

      final response = hasRegimenId
          ? await api.updateRegimen(
              mediRegimenId: plan.mediRegimenId!,
              scheduleType: input.scheduleType,
              startDateUtc: input.startDateUtc,
              endDateUtc: input.endDateUtc,
              daysOfWeek: input.scheduleType == 'WEEKLY'
                  ? toWeekdayCodes(plan.weekdays)
                  : null,
              intervalDays: input.intervalDays,
              cycleOnDays: input.cycleOnDays,
              cycleBreakDays: input.cycleBreakDays,
              times: input.times,
            )
          : await api.createMedicineRegimen(
              mediListId: plan.mediListId,
              scheduleType: input.scheduleType,
              startDateUtc: input.startDateUtc,
              endDateUtc: input.endDateUtc,
              daysOfWeek: input.daysOfWeek,
              intervalDays: input.intervalDays,
              cycleOnDays: input.cycleOnDays,
              cycleBreakDays: input.cycleBreakDays,
              times: input.times,
            );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasRegimenId ? '✅ อัปเดตข้อมูลสำเร็จ' : '✅ บันทึกข้อมูลสำเร็จ',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ บันทึกไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmExit() async {
    if (_saving) return false;
    final isEditing = widget.initialPlan != null;
    final message = isEditing
        ? 'ข้อมูลยังไม่ถูกบันทึก\n\nต้องการที่จะออกจากการแก้ไขเวลาการรับประทานยาหรือไม่?'
        : 'ข้อมูลยังไม่ถูกบันทึก\n\nต้องการที่จะออกจากการตั้งเวลาการรับประทานยาหรือไม่?';

    final shouldPop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color.fromARGB(255, 232, 232, 241),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. White Box for Text
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black, // or Color(0xFF1F497D)
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 2. Row of Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Exit Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(0, 255, 255, 255),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ออก',
                          style: TextStyle(
                              fontSize: 18, decorationColor: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Stay Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F497D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'อยู่ต่อ',
                          style: TextStyle(
                              fontSize: 18, decorationColor: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialPlan != null;
    final pageTitle =
        isEditing ? 'แก้ไขเวลาการรับประทานยา' : 'ตั้งเวลาการรับประทานยา';

    final steps = [
      type_frequency(
        context: context,
        title: pageTitle,
        subtitle: 'รูปแบบและความถี่การรับประทานยา',
        medicines: widget.medicines,
        selectedMedicine: _selectedMedicine,
        onMedicineChanged: (medicine) =>
            setState(() => _selectedMedicine = medicine),
        frequencyMode: _frequencyMode,
        onFrequencyModeChanged: _setFrequencyMode,
        timesPerDayController: _timesPerDayController,
        everyHoursController: _everyHoursController,
        frequencyPattern: _frequencyPattern,
        onFrequencyPatternChanged: (value) =>
            setState(() => _frequencyPattern = value),
        selectedWeekdays: _selectedWeekdays,
        onWeekdaysChanged: (value) => setState(() {
          _selectedWeekdays
            ..clear()
            ..addAll(value);
        }),
        everyCountController: _everyCountController,
        everyUnit: _everyUnit,
        onEveryUnitChanged: (value) {
          if (value == null) return;
          setState(() => _everyUnit = value);
        },
        durationMode: _durationMode,
        onDurationModeChanged: (value) => setState(() => _durationMode = value),
        durationValueController: _durationValueController,
        durationUnit: _durationUnit,
        onDurationUnitChanged: (value) {
          if (value == null) return;
          setState(() => _durationUnit = value);
        },
        onAddMedicine: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ฟีเจอร์เพิ่มยากำลังพัฒนา')),
          );
        },
        regimenStartDate: _regimenStartDate,
        onRegimenStartDateChanged: (date) =>
            setState(() => _regimenStartDate = date),
        regimenEndDate: _regimenEndDate,
        onRegimenEndDateChanged: (date) {
          setState(() {
            _regimenEndDate = date;
            if (date != null) {
              _durationMode = DurationMode.custom;
              // Calculate duration in days, update UI
              final diff = date.difference(_regimenStartDate).inDays;
              final v = diff < 1 ? 1 : diff;
              _durationValue = v;
              _durationUnit = 'วัน';
              _durationValueController.text = v.toString();
            } else {
              _durationMode = DurationMode.forever;
            }
          });
        },
      ),
      detail_time(
        context: context,
        title: pageTitle,
        subtitle: 'รายละเอียดเวลาการรับประทานยา',
        selectedMedicine: _selectedMedicine,
        frequencyMode: _frequencyMode,
        timesPerDay: _timesPerDay,
        everyHours: _everyHours,
        startTime: _startTime,
        onStartTimeChanged: (value) => setState(() => _startTime = value),
        doses: _doses,
        onDoseChanged: (index, dose) => setState(() => _doses[index] = dose),
      ),
      summary_rejimen(
        context: context,
        title: pageTitle,
        subtitle: 'สรุปแผนการรับประทานยา',
        selectedMedicine: _selectedMedicine,
        frequencyMode: _frequencyMode,
        timesPerDay: _timesPerDay,
        everyHours: _everyHours,
        doses: _doses,
      ),
    ];

    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1F497D),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final confirm = await _confirmExit();
              if (confirm && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(pageTitle, style: const TextStyle(color: Colors.white)),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: steps
                      .map((step) => SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 20),
                            child: step,
                          ))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    _CircleNavButton(
                      icon: Icons.arrow_back,
                      onTap: _saving ? () {} : _prevStep,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _stepIndex == 2
                          ? ElevatedButton(
                              onPressed: _saving ? null : _savePlan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1F497D),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      'บันทึกข้อมูล',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                            )
                          : Align(
                              alignment: Alignment.centerRight,
                              child: _CircleNavButton(
                                icon: Icons.arrow_forward,
                                onTap: _saving ? () {} : _nextStep,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Color(0xFF8FB9E9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
