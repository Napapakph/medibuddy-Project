import 'package:flutter/material.dart';
import 'package:medibuddy/Model/medicine_model.dart';

Future<void> showMedicineDetailDialog({
  required BuildContext context,
  required MedicineCatalogItem? catalog,
  required String nickname,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: _MedicineDetailContent(
          catalog: catalog,
          nickname: nickname,
        ),
      );
    },
  );
}

class _MedicineDetailContent extends StatelessWidget {
  final MedicineCatalogItem? catalog;
  final String nickname;

  const _MedicineDetailContent({
    required this.catalog,
    required this.nickname,
  });

  String _valueOrDash(String value) {
    return value.trim().isEmpty ? '-' : value.trim();
  }

  Widget _buildSection(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E3F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F497D),
            ),
          ),
          const SizedBox(height: 6),
          Text(_valueOrDash(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = catalog?.imageUrl.trim() ?? '';
    final mediThName = catalog?.mediThName ?? '';
    final mediEnName = catalog?.mediEnName ?? '';
    final mediTradeName = catalog?.mediTradeName ?? '';
    final mediType = catalog?.mediType ?? '';
    final indications = catalog?.indications ?? '-';
    final usageAdvice = catalog?.usageAdvice ?? '-';
    final adverseReactions = catalog?.adverseReactions ?? '-';
    final contraindications = catalog?.contraindications ?? '-';
    final precautions = catalog?.precautions ?? '-';
    final interactions = catalog?.interactions ?? '-';
    final storage = catalog?.storage ?? '-';
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: maxHeight,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFF2F5F9),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '????????????',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F497D),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F8),
                        borderRadius: BorderRadius.circular(16),
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
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.photo,
                                      size: 64,
                                      color: Color(0xFF9AA7B8),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      '??????????????',
                      '?????????? : ${_valueOrDash(nickname)}\n'
                          '????????????????????? : ${_valueOrDash(mediThName)}\n'
                          '???????????????????????? : ${_valueOrDash(mediEnName)}\n'
                          '???????????? : ${_valueOrDash(mediTradeName)}',
                    ),
                    _buildSection('???????????????', _valueOrDash(mediType)),
                    _buildSection('?????????', indications),
                    _buildSection('?????????????????', usageAdvice),
                    _buildSection('??????????????????', adverseReactions),
                    _buildSection('??????????', contraindications),
                    _buildSection('?????????????????????', precautions),
                    _buildSection(
                        '???????????????????????????????', interactions),
                    _buildSection('??????????????', storage),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
