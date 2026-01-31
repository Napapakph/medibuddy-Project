import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/Model/medicine_regimen_model.dart';
import 'package:medibuddy/services/regimen_api.dart';
import '../set_remind/setFuctionRemind.dart';

typedef ResolveMedicineByMediListId = MedicineItem? Function(int mediListId);
typedef BuildMedicineFromDetail = MedicineItem Function(
  MedicineRegimenDetailResponse detail,
);

String scheduleLabel(ReminderPlan plan) {
  switch (plan.frequencyPattern) {
    case FrequencyPattern.everyDay:
      return 'ทุกวัน';
    case FrequencyPattern.someDays:
      if (plan.weekdays.isEmpty) return 'บางวัน';
      final labels = <int, String>{
        1: 'จ.',
        2: 'อ.',
        3: 'พ.',
        4: 'พฤ.',
        5: 'ศ.',
        6: 'ส.',
        7: 'อา.',
      };
      final days = plan.weekdays.toList()..sort();
      final text = days.map((d) => labels[d] ?? d.toString()).join(', ');
      return 'บางวัน ($text)';
    case FrequencyPattern.everyInterval:
      final count = plan.everyCount < 1 ? 1 : plan.everyCount;
      final unit = plan.everyUnit.trim().isEmpty ? 'วัน' : plan.everyUnit;
      return 'ทุก $count $unit';
  }
}

String buildRegimenSummaryText(List<ReminderPlan> plans) {
  if (plans.isEmpty) return 'ไม่มีข้อมูลแผนการทานยา';
  final buffer = StringBuffer();
  for (final plan in plans) {
    final nickname = plan.medicine.nickname_medi.trim();
    final name = nickname.isNotEmpty
        ? nickname
        : plan.medicine.officialName_medi.trim().isNotEmpty
            ? plan.medicine.officialName_medi
            : 'ไม่ระบุชื่อยา';
    final times = plan.doses.map((dose) => formatTime(dose.time)).join(', ');
    buffer.writeln('• ชื่อยา: $name');
    buffer.writeln('  ความถี่: ${plan.frequencyLabel}');
    buffer.writeln('  รูปแบบวัน: ${scheduleLabel(plan)}');
    buffer.writeln('  เวลาที่ต้องทาน: ${times.isEmpty ? '-' : times}');
    buffer.writeln('  ระยะเวลา: ${plan.durationLabel}');
    buffer.writeln('');
  }
  return buffer.toString().trim();
}

Future<String> fetchRegimenSummaryText({
  required int medicineListId,
  required ResolveMedicineByMediListId resolveMedicineByMediListId,
  required BuildMedicineFromDetail buildMedicineItemFromDetail,
}) async {
  final api = RegimenApiService();
  final res = await api.getRegimensByMedicineListId(
    medicineListId: medicineListId,
  );

  final plans = <ReminderPlan>[];
  for (final item in res.items) {
    final detail = await api.getRegimenDetail(
      mediRegimenId: item.mediRegimenId,
    );
    final resolved = resolveMedicineByMediListId(detail.mediListId) ??
        buildMedicineItemFromDetail(detail);
    plans.add(
      fromRegimenDetail(
        detail: detail,
        medicineItemResolvedFromList: resolved,
        localId: item.mediRegimenId.toString(),
      ),
    );
  }

  return buildRegimenSummaryText(plans);
}
