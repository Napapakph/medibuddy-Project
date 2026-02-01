import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/services/medicine_api.dart';

Future<void> showMedicineDetailDialog({
  required BuildContext context,
  required int mediId,
}) async {
  try {
    final api = MedicineApi();
    final detail = await api.getMedicineDetail(mediId: mediId);
    if (!context.mounted) return;

    final imageUrl = _toFullImageUrl(detail.mediPicture ?? '');

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DetailMedicineSheet(
        detail: detail,
        imageUrl: imageUrl,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('? ???????????????????????: $e')),
    );
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

class DetailMedicineSheet extends StatelessWidget {
  final MedicineDetail detail;
  final String imageUrl;

  const DetailMedicineSheet({
    super.key,
    required this.detail,
    required this.imageUrl,
  });

  String _safe(String? s) {
    final value = (s ?? '').trim();
    return value.isEmpty ? '-' : value;
  }

  @override
  Widget build(BuildContext context) {
    final th = _safe(detail.mediThName);
    final en = _safe(detail.mediEnName);
    final trade = _safe(detail.mediTradeName);
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
                                      child: Icon(
                                        Icons.photo,
                                        size: 64,
                                        color: Color(0xFF9AA7B8),
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) {
                                          return const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 56,
                                              color: Color(0xFF9AA7B8),
                                            ),
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
