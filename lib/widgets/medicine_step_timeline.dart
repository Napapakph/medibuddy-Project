import 'package:flutter/material.dart';

class MedicineStepTimeline extends StatelessWidget {
  final int currentStep;

  const MedicineStepTimeline({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF1F497D);
    const inactiveColor = Color(0xFFD6DFEA);
    const inactiveIcon = Color(0xFF8FA3BF);

    const icons = [
      Icons.edit,
      Icons.search,
      Icons.medication,
      Icons.bookmark,
    ];

    final widgets = <Widget>[];

    for (var i = 0; i < icons.length; i++) {
      final step = i + 1;
      final isActive = step <= currentStep;

      widgets.add(
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icons[i],
            color: isActive ? Colors.white : inactiveIcon,
          ),
        ),
      );

      if (i < icons.length - 1) {
        widgets.add(
          Expanded(
            child: Container(
              height: 3,
              color: (step < currentStep) ? activeColor : inactiveColor,
            ),
          ),
        );
      }
    }

    return Row(children: widgets);
  }
}
