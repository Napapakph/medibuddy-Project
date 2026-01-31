import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/services/medicine_api.dart';
import '../../../services/app_state.dart';

/// หน้า "ค้นหาข้อมูลยา"
/// ✅ เปิดหน้ามา: โหลด list ก่อนทันที
/// ✅ ค้นหา: กดปุ่มแว่น หรือกด Enter -> query API ด้วยคำค้น
/// ✅ กดการ์ด: เปิด popup รายละเอียด (แสดงชื่อ+รูปจาก list ก่อน)
class MedicineSearchPage extends StatefulWidget {
  const MedicineSearchPage({super.key});

  @override
  State<MedicineSearchPage> createState() => _MedicineSearchPageState();
}

class _MedicineSearchPageState extends State<MedicineSearchPage> {
  final MedicineApi _api = MedicineApi();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = false;
  String _errorMessage = '';
  List<MedicineCatalogItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadInitialList(); // ✅ เปิดหน้ามาโหลด list ก่อน
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialList() async {
    // ถ้า API ของเดียร์รองรับ search ว่าง = คืน list แรก ก็ใช้แบบนี้ได้เลย
    await _fetchList(search: '');
  }

  Future<void> _onSearch() async {
    final keyword = _searchController.text.trim();
    await _fetchList(search: keyword);
  }

  Future<void> _fetchList({required String search}) async {
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      // ใช้ API list เดิมของเดียร์ (fetchMedicineCatalog)
      // - search='' => list เริ่มต้น
      // - search='tylenol' => query ด้วยชื่อ
      final items = await _api.fetchMedicineCatalog(search: search);

      if (!mounted) return;
      setState(() {
        _items = items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _items = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  String _toFullImageUrl(String raw) {
    final base = (dotenv.env['API_BASE_URL'] ?? '').trim();
    final p = raw.trim();

    if (p.isEmpty || p.toLowerCase() == 'null') return '';
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    if (base.isEmpty) return '';

    try {
      final baseUri = Uri.parse(base);
      final path = p.startsWith('/') ? p : '/$p';
      return baseUri.resolve(path).toString();
    } catch (_) {
      return '';
    }
  }

  String _safe(String? s) {
    final value = (s ?? '').trim();
    return value.isEmpty ? '-' : value;
  }

  Future<void> _openDetails(MedicineCatalogItem item) async {
    try {
      final detail = await _api.getMedicineDetail(mediId: item.mediId);
      if (!mounted) return;
      final imageUrl = _toFullImageUrl(
        detail.mediPicture ?? item.mediPicture ?? '',
      );
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => _MedicineDetailsDialog(
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

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onSubmitted: (_) => _onSearch(),
            decoration: InputDecoration(
              hintText: 'ชื่อสามัญทางภาษาไทย/อังกฤษ หรือชื่อการค้า',
              filled: true,
              fillColor: const Color(0xFFF2F4F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: _onSearch,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1F497D),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.search, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(MedicineCatalogItem item) {
    final trade = _safe(item.mediTradeName);
    final en = _safe(item.mediEnName);
    final th = _safe(item.mediThName);

    final imageUrl = _toFullImageUrl(item.mediPicture ?? '');

    return InkWell(
      onTap: () => _openDetails(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รูปซ้าย
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE1E8F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: imageUrl.isEmpty
                  ? const Icon(Icons.medication, color: Color(0xFF1F497D))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(Icons.medication,
                              color: Color(0xFF1F497D));
                        },
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // ข้อความกลาง
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ชื่อการค้า :',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$trade\n$en',
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.2,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    th,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7A869A),
                    ),
                  ),
                ],
              ),
            ),

            // ไอคอนวงกลมขวา (เดียร์จะเปลี่ยนเป็นรูปทีหลังได้)
            InkWell(
              onTap: () => _openDetails(item),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF5D83C8),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.pets, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF7A869A)),
        ),
      );
    }

    if (_items.isEmpty) {
      // เปิดหน้ามาแล้วไม่เจอรายการ หรือค้นหาแล้วไม่เจอ
      return const Center(
        child: Text(
          'ไม่พบข้อมูลยา',
          style: TextStyle(color: Color(0xFF7A869A)),
        ),
      );
    }

    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) => _buildCard(_items[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pid = AppState.instance.currentProfileId;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F497D),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(
              context,
              '/home',
              arguments: {
                'profileId': pid,
                'profileName': AppState.instance.currentProfileName,
                'profileImage': AppState.instance.currentProfileImagePath,
              },
            );
          },
        ),
        title: const Text(
          'ค้นหาข้อมูลยา',
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Popup รายละเอียด (เหมือนทรงในรูป: หัวข้อ + ปุ่ม X + เลื่อน)
class _MedicineDetailsDialog extends StatelessWidget {
  final MedicineDetail detail;
  final String imageUrl;

  _MedicineDetailsDialog({
    MedicineDetail? detail,
    String? imageUrl,
  })  : detail = detail ?? _emptyDetail(),
        imageUrl = imageUrl ?? '';

  static MedicineDetail _emptyDetail() {
    return MedicineDetail(
      mediId: 0,
      mediThName: null,
      mediEnName: null,
      mediTradeName: null,
      mediType: null,
      mediUse: null,
      mediGuide: null,
      mediEffects: null,
      mediNoUse: null,
      mediWarning: null,
      mediStore: null,
      mediPicture: null,
    );
  }

  String _safe(String? s) {
    final value = (s ?? '').trim();
    return value.isEmpty ? '-' : value;
  }

  @override
  Widget build(BuildContext context) {
    final trade = _safe(detail.mediTradeName);
    final en = _safe(detail.mediEnName);
    final th = _safe(detail.mediThName);
    final type = _safe(detail.mediType);
    final use = _safe(detail.mediUse);
    final guide = _safe(detail.mediGuide);
    final effect = _safe(detail.mediEffects);
    final noUse = _safe(detail.mediNoUse);
    final warning = _safe(detail.mediWarning);
    final keep = _safe(detail.mediStore);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0F7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'รายละเอียดยา',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F497D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              height: 140,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F4F8),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: imageUrl.isEmpty
                                  ? const Center(
                                      child: Icon(Icons.photo,
                                          size: 64, color: Color(0xFF9AA7B8)),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) {
                                          return const Center(
                                            child: Icon(Icons.broken_image,
                                                size: 56,
                                                color: Color(0xFF9AA7B8)),
                                          );
                                        },
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SectionCard(
                              title: 'ชื่อสามัญทางภาษาไทย :', body: th),
                          _SectionCard(
                              title: 'ชื่อสามัญทางภาษาอังกฤษ :', body: en),
                          _SectionCard(title: 'ชื่อการค้า :', body: trade),
                          _SectionCard(title: 'ประเภท :', body: type),
                          _SectionCard(title: 'ข้อบ่งใช้ :', body: use),
                          _SectionCard(title: 'คำแนะนำ :', body: guide),
                          _SectionCard(
                              title: 'อาการไม่พึงประสงค์ :', body: effect),
                          _SectionCard(title: 'ข้อห้ามใช้ :', body: noUse),
                          _SectionCard(
                              title: 'ข้อควรระวังในการใช้ยา :', body: warning),
                          _SectionCard(title: 'การเก็บรักษา :', body: keep),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1F497D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String body;

  const _SectionCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F497D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: Colors.black87,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
