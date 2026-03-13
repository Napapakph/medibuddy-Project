import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

bool _looksLikeSuccess(String message) {
  final msg = message.toLowerCase();
  return msg.contains('สำเร็จ') ||
      msg.contains('เสร็จสิ้น') ||
      msg.contains('ยอมรับ') ||
      msg.contains('ปฏิเสธ') ||
      msg.contains('✅');
}

void showToast(String message, {bool? isSuccess}) {
  final success = isSuccess ?? _looksLikeSuccess(message);
  if (success) {
    showSuccessToast(message);
  } else {
    showErrorToast(message);
  }
}

void showSuccessToast(String message) {
  BotToast.showCustomText(
    duration: const Duration(seconds: 2),
    align: const Alignment(0, 0.5),
    toastBuilder: (_) {
      return Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 114, 178, 121),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    },
  );
}

void showErrorToast(String message) {
  BotToast.showCustomNotification(
    align: const Alignment(0, -0.5),
    duration: const Duration(seconds: 2),
    toastBuilder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 195, 120, 134),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 8,
                    offset: Offset(0, 2),
                    color: Colors.black26,
                  ),
                ],
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
