import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medibuddy/Model/medicine_model.dart';
import 'package:medibuddy/widgets/app_drawer.dart';

import 'createName_medicine.dart';
import '../home.dart';
import '../set_remind/remind_list_screen.dart';

class ListMedicinePage extends StatefulWidget {
  const ListMedicinePage({super.key});

  @override
  State<ListMedicinePage> createState() => _ListMedicinePageState();
}

class _ListMedicinePageState extends State<ListMedicinePage> {
  final List<MedicineItem> _items = [];

  ImageProvider? _buildMedicineImage(String path) {
    if (path.isEmpty) return null;
    if (path.startsWith('http')) return NetworkImage(path);
    return FileImage(File(path));
  }

  Future<void> _addMedicine() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateNameMedicinePage()),
    );

    if (!mounted) return;
    if (result is MedicineItem) {
      setState(() {
        _items.add(result);
      });
    }
  }

  void _editMedicine(int index) {
    final current = _items[index];
    final controller = TextEditingController(text: current.displayName);
    String tempImagePath = current.imagePath;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final image = _buildMedicineImage(tempImagePath);

            return AlertDialog(
              title: const Text('???????'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final img =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (img == null) return;
                      setDialogState(() {
                        tempImagePath = img.path;
                      });
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F8),
                        borderRadius: BorderRadius.circular(16),
                        image: image != null
                            ? DecorationImage(image: image, fit: BoxFit.cover)
                            : null,
                      ),
                      child: image == null
                          ? const Icon(Icons.photo, color: Color(0xFF9AA7B8))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '??????',
                      filled: true,
                      fillColor: const Color(0xFFF2F4F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('??????'),
                ),
                TextButton(
                  onPressed: () {
                    final newName = controller.text.trim();
                    if (newName.isEmpty) return;

                    setState(() {
                      _items[index] = MedicineItem(
                        displayName: newName,
                        selectedName: current.selectedName,
                        imagePath: tempImagePath,
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('??????'),
                ),
              ],
            );
          },
        );
      },
    );
  }




  void _showDetails(MedicineItem item) {
    final image = _buildMedicineImage(item.imagePath);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('รายละเอียด'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (image != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image(
                      image: image,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text('ชื่อยาที่ตั้ง: ${item.displayName}'),
              if (item.selectedName.isNotEmpty)
                Text('ชื่อรายการยาที่เลือก: ${item.selectedName}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
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
                setState(() {
                  _items.removeAt(index);
                });
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
    final image = _buildMedicineImage(item.imagePath);

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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE7F5),
                borderRadius: BorderRadius.circular(12),
                image: image != null
                    ? DecorationImage(image: image, fit: BoxFit.cover)
                    : null,
              ),
              child: image == null
                  ? const Icon(Icons.medication, color: Color(0xFF1F497D))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.selectedName.isNotEmpty)
                    Text(
                      item.selectedName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5E6C84),
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

  Widget _buildBottomBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1F497D),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.calendar_today, color: Colors.white),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Home()),
              );
            },
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFB7DAFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.home, color: Color(0xFF1F497D)),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.medication, color: Color(0xFFB7DAFF)),
          ),
        ],
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ฟีเจอร์ PDF กำลังพัฒนา')),
              );
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFEFF6FF),
      body: SafeArea(
        child: Column(
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
                                child: _items.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'ยังไม่มีรายการยา',
                                          style: TextStyle(
                                              color: Color(0xFF8893A0)),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _items.length,
                                        itemBuilder: _buildMedicineCard,
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                icon:
                                    const Icon(Icons.add, color: Colors.white),
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
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }
}
