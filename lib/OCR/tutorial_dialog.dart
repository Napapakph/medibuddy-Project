import 'package:flutter/material.dart';
import '../services/tutorial_service.dart';

class TutorialDialog extends StatefulWidget {
  final bool forceShow;

  const TutorialDialog({Key? key, this.forceShow = false}) : super(key: key);

  static Future<void> show(BuildContext context,
      {bool forceShow = false}) async {
    if (!forceShow) {
      final isDone = await TutorialService.isTutorialDone();
      if (isDone) return;
    }
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialDialog(forceShow: forceShow),
    );
  }

  @override
  _TutorialDialogState createState() => _TutorialDialogState();
}

class _TutorialDialogState extends State<TutorialDialog> {
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': '1. ถ่ายรูปฉลากยา',
      'image': 'assets/tutorial_1.jpg',
      'points': [
        'วางฉลากยาในที่แสงเพียงพอ',
        'หลีกเลี่ยงแสงสะท้อน',
        'จัดกล้องให้ตรงกับฉลากยา',
        'ถ่ายเมื่อภาพชัดเจนและเห็นชื่อยา',
      ],
    },
    {
      'title': '2. เลือกตัดรูป',
      'image': 'assets/tutorial_2.jpg',
      'points': [
        'ลากกรอบให้ครอบคลุมแค่ส่วนชื่อยา',
        'ปรับกรอบให้พอดีกับชื่อยา',
        'กดบันทึกเมื่อเสร็จเรียบร้อย',
      ],
    },
    {
      'title': '3.เลือกส่วนชื่อยา',
      'image': 'assets/tutorial_3.jpg',
      'points': [
        'แตะที่กรอบข้อความที่ตรงกับชื่อยา',
        'ตรวจสอบความถูกต้องของข้อความ',
        'กด "ค้นหา" เพื่อค้นหาชื่อยา',
      ],
    },
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _onUnderstand() async {
    await TutorialService.setTutorialDone();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageData = _pages[_currentPage];
    final bool isLastPage = _currentPage == _pages.length - 1;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'วิธีใช้งาน',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                pageData['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_currentPage > 0)
                  GestureDetector(
                    onTap: _prevPage,
                    child: const Icon(Icons.arrow_back_ios,
                        size: 30, color: Colors.black87),
                  )
                else
                  const SizedBox(width: 30),
                Expanded(
                  child: Image.asset(
                    pageData['image'],
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
                if (_currentPage < _pages.length - 1)
                  GestureDetector(
                    onTap: _nextPage,
                    child: const Icon(Icons.arrow_forward_ios,
                        size: 30, color: Colors.black87),
                  )
                else
                  const SizedBox(width: 30),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (pageData['points'] as List<String>)
                  .map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              point,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            if (isLastPage)
              ElevatedButton(
                onPressed: _onUnderstand,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F497D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'เข้าใจแล้ว!',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              )
            else
              ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'ต่อไป',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
