import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:medibuddy/Home/pages/set_remind/remind_list_screen.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/widgets/app_drawer.dart';
import 'package:medibuddy/services/medicine_api.dart';
import 'create_medicine_profile.dart';
import 'detail_medicine.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../widgets/bottomBar.dart';
import 'medication_plan_screen.dart';
import 'package:lottie/lottie.dart';
import 'detail_medicine.dart';

class ListMedicinePage extends StatefulWidget {
  final int profileId;

  const ListMedicinePage({
    super.key,
    required this.profileId,
  });

  @override
  State<ListMedicinePage> createState() => _ListMedicinePageState();
}

class _ListMedicinePageState extends State<ListMedicinePage> {
  final MedicineApi _api = MedicineApi();
  final List<MedicineItem> _items = [];
  bool _isLoading = true;
  String _errorMessage = '';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ โหลดรายละเอียดไม่สำเร็จ: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบรายการยาไม่สำเร็จ: $e')),
      );
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ไม่ใช่'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'ใช่',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;
    if (!mounted) return;

    // 2. ให้พิมพ์ CONFIRM เพื่อยืนยัน
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบรายการยา'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 14, color: Color.fromARGB(255, 0, 0, 0)),
                    children: [
                      TextSpan(text: 'พิมพ์คำว่า '),
                      TextSpan(
                        text: 'CONFIRM',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: ' (ตัวพิมพ์ใหญ่) เพื่อยืนยันการลบ'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'CONFIRM',
                  ),
                  validator: (value) {
                    if (value != 'CONFIRM') {
                      return 'กรุณาพิมพ์ CONFIRM ให้ถูกต้อง';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  _deleteMedicine(index);
                }
              },
              child: const Text(
                'ยืนยันลบ',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
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
                color: Colors.white,
                shape: BoxShape.rectangle,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: imageProvider != null
                    ? Image(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.medication,
                        size: 48, color: Color(0xFF1F497D)),
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
                          color: Color(0xFF1F497D),
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
                        color: Color(0xFF1F497D),
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
                                  color: Color(0xFF1F497D), size: 20),
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
                                  color: Color(0xFF1F497D), size: 20),
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
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 230, 239, 253),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      () {
                        final t = item.mediType!.trim().toUpperCase();
                        if (t == 'ORAL') return 'ยารับประทาน';
                        if (t == 'TOPICAL') return 'ยาทาภายนอก';
                        return item.mediType!;
                      }(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1F497D),
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
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        // สีเขียวอมฟ้าตามรูป (Teal-ish)
                        color: const Color.fromARGB(255, 168, 200, 241),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.alarm, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'ตั้งแจ้งเตือน',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
      backgroundColor: const Color.fromARGB(255, 222, 237, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 179, 216, 255),
        centerTitle: true,
        title: const Text(
          'รายการยาของฉัน',
          style: TextStyle(
            color: Color(0xFF1F497D),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1F497D)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        actions: [
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
              icon: const FaIcon(
                FontAwesomeIcons.filePdf,
                color: Color(0xFF1F497D),
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
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          0, 255, 255, 255),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _isLoading
                                        ? const Center()
                                        : _items.isNotEmpty
                                            ? ListView.builder(
                                                itemCount: _items.length,
                                                itemBuilder: _buildMedicineCard,
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
                                SizedBox(height: maxWidth * 0.05),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _addMedicine,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1F497D),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    icon: Icon(Icons.add_circle_outline_rounded,
                                        color: Colors.white),
                                    label: const Text(
                                      'เพิ่มยา',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
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
                        const SizedBox(height: 8),
                        const Text(
                          'กำลังโหลด…',
                          style: TextStyle(color: Colors.white),
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
