import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/services/medicine_api.dart';

/// เรียก popup รายละเอียดยา โดยดึงข้อมูลจาก
/// GET /api/mobile/v1/medicine/detail?mediId=...
Future<void> showMedicineDetailDialog({
  required BuildContext context,
  required int mediId,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _MedicineDetailDialog(mediId: mediId),
  );
}

class _MedicineDetailDialog extends StatefulWidget {
  final int mediId;
  const _MedicineDetailDialog({required this.mediId});

  @override
  State<_MedicineDetailDialog> createState() => _MedicineDetailDialogState();
}

class _MedicineDetailDialogState extends State<_MedicineDetailDialog> {
  bool _loading = true;
  String _error = '';
  MedicineDetail? _detail;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = '';
      _detail = null;
    });

    try {
      final api = MedicineApi();
      final detail = await api.getMedicineDetail(mediId: widget.mediId);

      if (!mounted) return;
      setState(() {
        _detail = detail;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
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
    final v = (s ?? '').trim();
    return v.isEmpty ? '-' : v;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ใช้ทรง popup แบบ MedicineSearchPage (Dialog + header + X + scroll)
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
                  // header
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

                  // content
                  Flexible(
                    child: SingleChildScrollView(
                      child: Builder(
                        builder: (_) {
                          if (_loading) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 24),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (_error.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _SectionCard(
                                title: 'เกิดข้อผิดพลาด',
                                body: _error,
                              ),
                            );
                          }

                          final d = _detail;
                          if (d == null) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: _SectionCard(
                                title: 'ไม่พบข้อมูล',
                                body: 'ไม่พบรายละเอียดของยา',
                              ),
                            );
                          }

                          final imageUrl = _toFullImageUrl(d.mediPicture ?? '');

                          return Column(
                            children: [
                              // image
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
                                          borderRadius:
                                              BorderRadius.circular(14),
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
                                title: 'ชื่อสามัญทางภาษาไทย :',
                                body: _safe(d.mediThName),
                              ),
                              _SectionCard(
                                title: 'ชื่อสามัญทางภาษาอังกฤษ :',
                                body: _safe(d.mediEnName),
                              ),
                              _SectionCard(
                                title: 'ชื่อการค้า :',
                                body: _safe(d.mediTradeName),
                              ),
                              _SectionCard(
                                title: 'รูปแบบยา :',
                                body: _safe(d.mediType),
                              ),

                              const _SectionHeader(title: 'ข้อบ่งใช้'),
                              _SectionCard(
                                title: 'ข้อบ่งใช้',
                                body: _safe(d.mediUse),
                              ),

                              const _SectionHeader(title: 'คำแนะนำในการใช้ยา'),
                              _SectionCard(
                                title: 'คำแนะนำ',
                                body: _safe(d.mediGuide),
                              ),

                              const _SectionHeader(
                                  title: 'อาการไม่พึงประสงค์จากยา'),
                              _SectionCard(
                                title: 'อาการไม่พึงประสงค์',
                                body: _safe(d.mediEffects),
                              ),

                              const _SectionHeader(title: 'ข้อห้ามใช้'),
                              _SectionCard(
                                title: 'ข้อห้ามใช้',
                                body: _safe(d.mediNoUse),
                              ),

                              const _SectionHeader(
                                  title: 'ข้อควรระวังในการใช้ยา'),
                              _SectionCard(
                                title: 'คำเตือน',
                                body: _safe(d.mediWarning),
                              ),

                              const _SectionHeader(title: 'การเก็บรักษายา'),
                              _SectionCard(
                                title: 'การเก็บรักษา',
                                body: _safe(d.mediStore),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // close button
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F497D),
          ),
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
