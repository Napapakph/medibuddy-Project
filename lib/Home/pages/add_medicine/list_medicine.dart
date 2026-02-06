import 'package:flutter/material.dart';
import 'package:medibuddy/Home/pages/set_remind/remind_list_screen.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/widgets/app_drawer.dart';
import 'package:medibuddy/services/medicine_api.dart';
import 'createName_medicine.dart';
import 'detail_medicine.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../widgets/bottomBar.dart';
import 'medication_plan_screen.dart';
import 'package:lottie/lottie.dart';

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
  String _toFullImageUrl(String raw) {
    final base = (dotenv.env['API_BASE_URL'] ?? '').trim();
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
  ImageProvider? _buildMedicineImage(String path) {
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
      setState(() {
        _items.removeAt(index);
        _errorMessage = '';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบรายการยาไม่สำเร็จ: $e')),
      );
    }
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ลบรายการยา'),
          content: const Text('ต้องการลบรายการยานี้หรือไม่'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMedicine(index);
              },
              child: const Text(
                'ลบ',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMedicineCard(BuildContext context, int index) {
    final item = _items[index];
    final imageProvider = _buildMedicineImage(item.imagePath);
    debugPrint('🧪 MED item imagePath = "${item.imagePath}"');

    return InkWell(
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE7F5),
                borderRadius: BorderRadius.circular(12),
                image: imageProvider != null
                    ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                    : null,
              ),
              child: imageProvider == null
                  ? const Icon(Icons.medication, color: Color(0xFF1F497D))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nickname_medi,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F497D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'กดเพื่อดูรายการแจ้งเตือนการรับประทานยา',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color.fromARGB(255, 85, 85, 85),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () => _editMedicine(index),
                  icon: const Icon(Icons.edit, color: Color(0xFF1F497D)),
                ),
                IconButton(
                  onPressed: () => _showDetails(item),
                  icon: const Icon(Icons.info, color: Color(0xFF1F497D)),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(index),
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                ),
              ],
            ),
          ],
        ),
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
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MedicationPlanScreen(profileId: widget.profileId),
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFEFF6FF),
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
                              horizontal: maxWidth * 0.04,
                              vertical: maxWidth * 0.03,
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
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
                                        ? const Center(
                                            child: CircularProgressIndicator(),
                                          )
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
                BottomBar(currentRoute: '/list_medicine'),
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
