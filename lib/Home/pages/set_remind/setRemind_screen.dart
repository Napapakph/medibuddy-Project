import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';

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
  List<ReminderDose> _doses = [];

  late TextEditingController _timesPerDayController;
  late TextEditingController _everyHoursController;
  late TextEditingController _everyCountController;
  late TextEditingController _durationValueController;

  @override
  void initState() {
    super.initState();

    _selectedMedicine = widget.initialMedicine ??
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

    _timesPerDayController.addListener(() {
      _updateTimesPerDay(_timesPerDayController.text);
    });
    _everyHoursController.addListener(() {
      _updateEveryHours(_everyHoursController.text);
    });
    _everyCountController.addListener(() {
      _updateEveryCount(_everyCountController.text);
    });
    _durationValueController.addListener(() {
      _updateDurationValue(_durationValueController.text);
    });
  }

  void _applyInitialPlan(ReminderPlan plan) {
    _selectedMedicine = plan.medicine;
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

    _selectedWeekdays
      ..clear()
      ..addAll(plan.weekdays);

    _timesPerDayController.text = _timesPerDay.toString();
    _everyHoursController.text = _everyHours.toString();
    _everyCountController.text = _everyCount.toString();
    _durationValueController.text = _durationValue.toString();

    _doses = plan.doses
        .map(
          (dose) => ReminderDose(
            time: dose.time,
            amount: dose.amount,
            unit: dose.unit,
            mealTiming: dose.mealTiming,
          ),
        )
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
      updated.add(
        ReminderDose(
          time: _defaultTimeForIndex(updated.length),
        ),
      );
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
      if (_frequencyMode == FrequencyMode.timesPerDay) {
        _syncDoseCount(_timesPerDay);
      }
    });
  }

  void _updateEveryHours(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    setState(() {
      _everyHours = parsed < 1 ? 1 : parsed;
    });
  }

  void _updateEveryCount(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    setState(() {
      _everyCount = parsed < 1 ? 1 : parsed;
    });
  }

  void _updateDurationValue(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    setState(() {
      _durationValue = parsed < 1 ? 1 : parsed;
    });
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
    setState(() {
      _stepIndex += 1;
    });
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
    setState(() {
      _stepIndex -= 1;
    });
    _pageController.animateToPage(
      _stepIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _savePlan() {
    if (_selectedMedicine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกรายการยา')),
      );
      return;
    }

    final id = widget.reminderId ??
        widget.initialPlan?.id ??
        DateTime.now().microsecondsSinceEpoch.toString();

    final plan = ReminderPlan(
      id: id,
      medicine: _selectedMedicine!,
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
    );

    Navigator.pop(context, plan);
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
        onMedicineChanged: (medicine) {
          setState(() {
            _selectedMedicine = medicine;
          });
        },
        frequencyMode: _frequencyMode,
        onFrequencyModeChanged: _setFrequencyMode,
        timesPerDayController: _timesPerDayController,
        everyHoursController: _everyHoursController,
        frequencyPattern: _frequencyPattern,
        onFrequencyPatternChanged: (value) {
          setState(() {
            _frequencyPattern = value;
          });
        },
        selectedWeekdays: _selectedWeekdays,
        onWeekdaysChanged: (value) {
          setState(() {
            _selectedWeekdays
              ..clear()
              ..addAll(value);
          });
        },
        everyCountController: _everyCountController,
        everyUnit: _everyUnit,
        onEveryUnitChanged: (value) {
          if (value == null) return;
          setState(() {
            _everyUnit = value;
          });
        },
        durationMode: _durationMode,
        onDurationModeChanged: (value) {
          setState(() {
            _durationMode = value;
          });
        },
        durationValueController: _durationValueController,
        durationUnit: _durationUnit,
        onDurationUnitChanged: (value) {
          if (value == null) return;
          setState(() {
            _durationUnit = value;
          });
        },
        onAddMedicine: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ฟีเจอร์เพิ่มยากำลังพัฒนา')),
          );
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
        onStartTimeChanged: (value) {
          setState(() {
            _startTime = value;
          });
        },
        doses: _doses,
        onDoseChanged: (index, dose) {
          setState(() {
            _doses[index] = dose;
          });
        },
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F497D),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          pageTitle,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: steps
                    .map(
                      (step) => SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        child: step,
                      ),
                    )
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  _CircleNavButton(
                    icon: Icons.arrow_back,
                    onTap: _prevStep,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _stepIndex == 2
                        ? ElevatedButton(
                            onPressed: _savePlan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F497D),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'บันทึกข้อมูล',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : Align(
                            alignment: Alignment.centerRight,
                            child: _CircleNavButton(
                              icon: Icons.arrow_forward,
                              onTap: _nextStep,
                            ),
                          ),
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

class _CircleNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleNavButton({
    required this.icon,
    required this.onTap,
  });

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
