import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:medibuddy/set_remind/remind_list_screen.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/widgets/app_drawer.dart';
import 'package:medibuddy/services/medicine_api.dart';
import 'create_medicine_profile.dart';
import '../search_medicine/detail_medicine.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/bottomBar.dart';
import '../export_pdf/medicine_plan_pdf.dart';
import 'package:lottie/lottie.dart';
import '../search_medicine/detail_medicine.dart';
import 'dart:math';
import 'package:icofont_flutter/icofont_flutter.dart';
import 'package:community_material_icon/community_material_icon.dart';

class ListMedicinePage extends StatefulWidget {
  final int profileId;

  const ListMedicinePage({
    super.key,
    required this.profileId,
  });

  @override
  State<ListMedicinePage> createState() => _ListMedicinePageState();
}

enum _SortOption {
  defaultOrder,
  byName,
}

class _ListMedicinePageState extends State<ListMedicinePage> {
  final MedicineApi _api = MedicineApi();
  final List<MedicineItem> _items = [];
  bool _isLoading = true;
  String _errorMessage = '';
  _SortOption _currentSort = _SortOption.defaultOrder;

  List<MedicineItem> get _sortedItems {
    if (_currentSort == _SortOption.defaultOrder) {
      return _items;
    }
    final sorted = List<MedicineItem>.from(_items);
    sorted.sort((a, b) {
      final nameA =
          a.nickname_medi.isNotEmpty ? a.nickname_medi : a.officialName_medi;
      final nameB =
          b.nickname_medi.isNotEmpty ? b.nickname_medi : b.officialName_medi;
      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    });
    return sorted;
  }

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  /// สร้าง full url จาก path ที่ backend ส่งมา
  /// - รองรับทั้ง full url, /uploads/..., uploads/...
  /// - กัน crash ถ้า API_BASE_URL ไม่ใช่ url ถูกต้อง
  String _toFullImageUrl(String? raw) {
    final base = (dotenv.env['API_BASE_URL'] ?? '').trim();
    if (raw == null) return '';
    final p = raw.trim();

    if (p.isEmpty || p.toLowerCase() == 'null') return '';

    // already full url
    if (p.startsWith('http://') || p.startsWith('https://')) return p;

    if (base.isEmpty) return '';

    try {
      final baseUri = Uri.parse(base);
      final normalizedPath = p.startsWith('/') ? p : '/$p';
      return baseUri.resolve(normalizedPath).toString();
    } catch (e) {
      return '';
    }
  }

  /// คืน ImageProvider สำหรับใช้กับ DecorationImage / Image widget
  /// ✅ ต้อง return ครบทุกกรณี เพื่อเลี่ยงพฤติกรรมแปลก ๆ ใน release
  ImageProvider? _buildMedicineImage(String? path) {
    if (path == null) return null;
    final p = path.trim();
    if (p.isEmpty || p.toLowerCase() == 'null') return null;

    // full url
    if (p.startsWith('http://') || p.startsWith('https://')) {
      return NetworkImage(p);
    }

    // relative uploads
    if (p.startsWith('/uploads') || p.startsWith('uploads')) {
      final url = _toFullImageUrl(p);
      if (url.isEmpty) return null;
      return NetworkImage(url);
    }

    // กรณี backend ส่ง path แบบอื่น (กันไว้ ไม่ให้เด้ง)
    final maybeUrl = _toFullImageUrl(p);
    if (maybeUrl.isNotEmpty) return NetworkImage(maybeUrl);

    return null;
  }

  Future<void> _loadMedicines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final items = await _api.fetchProfileMedicineList(
        profileId: widget.profileId, // ✅ source เดียว
      );
      if (!mounted) return;

      setState(() {
        _items
          ..clear()
          ..addAll(items);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _sanitizeErrorMessage(e.toString());
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _friendlyErrorMessage() {
    final message = _errorMessage.trim();
    if (message.isEmpty) return '';
    final lower = message.toLowerCase();
    if (lower.contains('<html') || lower.contains('<!doctype')) {
      return 'ไม่สามารถโหลดรายการยาได้ในขณะนี้';
    }
    return message;
  }

  String _sanitizeErrorMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return '';
    final lower = trimmed.toLowerCase();
    if (lower.contains('<html') || lower.contains('<!doctype')) {
      return 'ไม่สามารถโหลดรายการยาได้ในขณะนี้';
    }
    return trimmed;
  }

  Future<void> _addMedicine() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateNameMedicinePage(
          profileId: widget.profileId, // ✅ source เดียว
        ),
      ),
    );

    if (!mounted) return;
    if (result is MedicineItem) {
      setState(() {
        _errorMessage = '';
      });
      await _loadMedicines();
    }
  }

  Future<void> _editMedicine(int index) async {
    final current = _items[index];

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateNameMedicinePage(
          profileId: widget.profileId, // ✅ source เดียว
          isEditing: true,
          initialItem: current,
        ),
      ),
    );

    if (!mounted) return;
    if (result is MedicineItem) {
      setState(() {
        _errorMessage = '';
      });
      await _loadMedicines();
    }
  }

  Future<void> _showDetails(MedicineItem item) async {
    try {
      final detail = await _api.getMedicineDetail(mediId: item.mediId);
      if (!mounted) return;

      final imageUrl = _toFullImageUrl(
        detail.mediPicture ?? item.imagePath,
      );

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => DetailMedicineSheet(
          detail: detail,
          imageUrl: imageUrl,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('ไม่มีรายละเอียด'),
          content: const Text('ไม่พบรายการยาที่เกี่ยวข้องผูกกับรายการยาของคุณ'),
          backgroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง',
                  style: TextStyle(color: Color(0xFF5A81BB))),
            ),
          ],
        ),
      );
      debugPrint('❌ โหลดรายละเอียดไม่สำเร็จ: $e');
    }
  }

  Future<void> _deleteMedicine(int index) async {
    final item = _items[index];
    if (item.mediListId == 0) {
      setState(() {
        _items.removeAt(index);
        _errorMessage = '';
      });
      return;
    }

    try {
      await _api.deleteMedicineListItem(mediListId: item.mediListId);
      if (!mounted) return;

      // ✅ รีเฟรชข้อมูลใหม่ทันที
      await _loadMedicines();
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ ลบรายการยาไม่สำเร็จ: $e');
    }
  }

  void _confirmDelete(int index) async {
    // 1. ถามยืนยันครั้งแรก
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันที่จะลบรายการยาใช่มั้ย'),
          content: const Text(
              'ข้อมูลประวัติการทานยาทั้งหมดที่เกี่ยวข้องจะหายไป ต้องการลบจริงๆใช่มั้ย'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'ใช่',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ไม่ใช่'),
            ),
          ],
          backgroundColor: Colors.white,
        );
      },
    );

    if (shouldDelete != true) return;
    if (!mounted) return;

    // 2. สุ่มเลข 4 หลัก
    final randomCode = (1000 + Random().nextInt(9000)).toString();

    await showDialog(
      context: context,
      builder: (context) {
        String enteredCode = '';

        // Customization variables
        const double buttonSize = 70.0;
        const double buttonFontSize = 26.0;
        const Color numButtonColor = Colors.white;
        const Color numTextColor = Color(0xFF5A81BB);
        const Color delButtonColor = Color(0xFFFFEBEE);
        const Color delIconColor = Colors.red;

        return StatefulBuilder(
          builder: (context, setState) {
            void onKeyTap(String value) {
              if (value == 'DEL') {
                if (enteredCode.isNotEmpty) {
                  setState(() {
                    enteredCode =
                        enteredCode.substring(0, enteredCode.length - 1);
                  });
                }
              } else {
                if (enteredCode.length < 4) {
                  setState(() {
                    enteredCode += value;
                  });
                }
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFFF0F6FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: const Text('ยืนยันลบรายการยา'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black87),
                        children: [
                          const TextSpan(text: 'กรุณากดรหัส '),
                          TextSpan(
                            text: randomCode,
                            style: const TextStyle(
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const TextSpan(text: ' เพื่อยืนยัน'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Display Entered Code
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: enteredCode == randomCode
                                ? Colors.green
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                            )
                          ]),
                      child: Text(
                        enteredCode.isEmpty ? '____' : enteredCode,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          letterSpacing: 12,
                          fontWeight: FontWeight.bold,
                          color: enteredCode == randomCode
                              ? Colors.green
                              : const Color(0xFF5A81BB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Numpad
                    Column(
                      children: [
                        for (var row in [
                          ['1', '2', '3'],
                          ['4', '5', '6'],
                          ['7', '8', '9'],
                          ['', '0', 'DEL']
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: row.map((key) {
                                if (key.isEmpty) {
                                  return SizedBox(
                                      width: buttonSize, height: buttonSize);
                                }
                                return SizedBox(
                                  width: buttonSize,
                                  height: buttonSize,
                                  child: ElevatedButton(
                                    onPressed: () => onKeyTap(key),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      backgroundColor: key == 'DEL'
                                          ? delButtonColor
                                          : numButtonColor,
                                      foregroundColor: key == 'DEL'
                                          ? delIconColor
                                          : numTextColor,
                                      elevation: 3,
                                      shadowColor: Colors.black26,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            buttonSize / 2),
                                      ),
                                    ),
                                    child: key == 'DEL'
                                        ? const Icon(Icons.backspace_rounded,
                                            size: 28)
                                        : Text(
                                            key,
                                            style: TextStyle(
                                              fontSize: buttonFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: numTextColor,
                                            ),
                                          ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก', style: TextStyle(fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: enteredCode == randomCode
                      ? () {
                          Navigator.pop(context);
                          _deleteMedicine(index);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('ยืนยันลบ',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showImagePopup(ImageProvider? imageProvider) {
    if (imageProvider == null) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Stack(
        children: [
          // Background dismiss
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black.withOpacity(0.7)),
            ),
          ),
          // Content
          Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Close button bar
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.black),
                    ),
                  ),
                  // Image
                  Flexible(
                    child: InteractiveViewer(
                      child: Image(
                        image: imageProvider,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(BuildContext context, int index) {
    final item = _items[index];
    final imageProvider = _buildMedicineImage(item.imagePath);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7BAEE5).withOpacity(0.10),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ฝั่งซ้าย: รูปภาพ
          GestureDetector(
            onTap: () => _showImagePopup(imageProvider),
            child: Container(
              width: 80,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F5F9),
                shape: BoxShape.rectangle,
                border: Border.all(color: const Color(0xFFE4EAF0)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageProvider != null
                    ? Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.medication,
                        size: 48, color: Color(0xFF7BAEE5)),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ฝั่งขวา: Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. แถวบน: ชื่อยา + เมนู
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.nickname_medi,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B4C7E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      icon: const Icon(
                        Icons.more_horiz,
                        color: Color(0xFF8A9BB5),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editMedicine(index);
                        } else if (value == 'delete') {
                          _confirmDelete(index);
                        } else if (value == 'info') {
                          _showDetails(item);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'info',
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Color(0xFF6B8DB0), size: 20),
                              SizedBox(width: 8),
                              Text('ข้อมูลยา'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit,
                                  color: Color(0xFF6B8DB0), size: 20),
                              SizedBox(width: 8),
                              Text('แก้ไข'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete,
                                  color: Color.fromARGB(255, 210, 83, 83),
                                  size: 20),
                              SizedBox(width: 8),
                              Text(
                                'ลบ',
                                style: TextStyle(
                                    color: Color.fromARGB(255, 210, 83, 83)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // 2. Type (ย้ายมาไว้ใต้ชื่อ)
                if (item.mediType != null && item.mediType!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      () {
                        final t = item.mediType!.trim().toUpperCase();
                        if (t == 'ORAL') return 'ยารับประทาน';
                        if (t == 'TOPICAL') return 'ยาทาภายนอก';
                        return item.mediType!;
                      }(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5A81BB),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],

                // 3. ชื่อทางการ / รายละเอียด (Subtitle)
                if (item.officialName_medi.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.officialName_medi,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // 4. ปุ่มตั้งแจ้งเตือน (ขวาล่าง)
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RemindListScreen(
                            medicines: _items,
                            initialMedicine: item,
                            profileId: widget.profileId,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6E9FC),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.alarm_rounded,
                              color: Color(0xFF5A81BB), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'ตั้งแจ้งเตือน',
                            style: TextStyle(
                              color: Color(0xFF5A81BB),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 234, 244, 255),
                Color.fromARGB(255, 193, 222, 255)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'รายการยาของฉัน',
          style: TextStyle(
            color: Color(0xFF2B4C7E),
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF5A81BB)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        actions: [
          PopupMenuButton<_SortOption>(
            icon: const Icon(Icons.sort_rounded, color: Color(0xFF5A81BB)),
            color: Colors.white,
            tooltip: 'เรียงลำดับ',
            onSelected: (option) {
              setState(() {
                _currentSort = option;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _SortOption.defaultOrder,
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: _currentSort == _SortOption.defaultOrder
                          ? const Color(0xFF5A81BB)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'เพิ่มล่าสุด (เริ่มต้น)',
                      style: TextStyle(
                        color: _currentSort == _SortOption.defaultOrder
                            ? const Color(0xFF5A81BB)
                            : Colors.black87,
                        fontWeight: _currentSort == _SortOption.defaultOrder
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _SortOption.byName,
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha_rounded,
                      color: _currentSort == _SortOption.byName
                          ? const Color(0xFF5A81BB)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'เรียงตามชื่อ (A-Z)',
                      style: TextStyle(
                        color: _currentSort == _SortOption.byName
                            ? const Color(0xFF5A81BB)
                            : Colors.black87,
                        fontWeight: _currentSort == _SortOption.byName
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MedicationPlanScreen(profileId: widget.profileId),
                  ),
                );
              },
              icon: const Icon(
                CommunityMaterialIcons.file_pdf_box,
                color: Color(0xFF5A81BB),
                size: 30,
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: const BottomBar(
        currentRoute: '/list_medicine',
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final containerWidth = maxWidth > 600 ? 500.0 : maxWidth;

                      return Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: containerWidth,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: maxWidth * 0.02,
                              vertical: maxWidth * 0.02,
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: _isLoading
                                        ? const Center()
                                        : _sortedItems.isNotEmpty
                                            ? Scrollbar(
                                                thickness: 6,
                                                radius:
                                                    const Radius.circular(8),
                                                trackVisibility: true,
                                                //thumbVisibility: true,
                                                child: ListView.builder(
                                                  itemCount:
                                                      _sortedItems.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    // Find the actual index in the original `_items` array
                                                    final sortedItem =
                                                        _sortedItems[index];
                                                    final actualIndex = _items
                                                        .indexOf(sortedItem);
                                                    return _buildMedicineCard(
                                                        context, actualIndex);
                                                  },
                                                ),
                                              )
                                            : _errorMessage.isNotEmpty
                                                ? Center(
                                                    child: Text(
                                                      _friendlyErrorMessage(),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF8893A0),
                                                      ),
                                                    ),
                                                  )
                                                : const Center(
                                                    child: Text(
                                                      'ไม่พบรายการยา',
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF8893A0),
                                                      ),
                                                    ),
                                                  ),
                                  ),
                                ),
                                SizedBox(height: maxWidth * 0.015),
                                SizedBox(
                                  width: 170,
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed: _addMedicine,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 90, 129, 187),
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shadowColor:
                                          const Color.fromARGB(255, 42, 80, 135)
                                              .withOpacity(0.4),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                    ),
                                    icon: const Icon(IcoFontIcons.uiAdd,
                                        color: Colors.white, size: 20),
                                    label: const Text(
                                      'เพิ่มยา',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Positioned.fill(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const ModalBarrier(
                      dismissible: false,
                      color: Colors.black26,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          'assets/lottie/loader_cat.json',
                          width: 180,
                          height: 180,
                          repeat: true,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'กำลังโหลด…',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
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
