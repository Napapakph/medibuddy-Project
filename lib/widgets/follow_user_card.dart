import 'package:flutter/material.dart';

class FollowUserCard extends StatelessWidget {
  const FollowUserCard({
    super.key,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.avatarImage,
    required this.onDelete,
    this.onEdit,
    this.onDetail_1,
    this.onDetail_2,
    this.actionLabel_1 = 'ดูประวัติการกินยา',
    this.actionLabel_2 = 'ดูแผนการกินยา',
    this.actionIcon = Icons.history,
  });

  final String name;
  final String email;
  final String avatarUrl;
  final ImageProvider? avatarImage;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDetail_1;
  final VoidCallback? onDetail_2;
  final String actionLabel_1;
  final String? actionLabel_2;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shadowColor: const Color.fromARGB(40, 122, 174, 229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // === Top Section: Name (Left) | Edit, Delete (Right) ===
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B4C7E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF5A81BB),
                    size: 25,
                  ),
                  tooltip: 'แก้ไข',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(2),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete,
                      color: Color(0xFFC66E6E), size: 25),
                  tooltip: 'ลบ',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(2),
                ),
              ],
            ),

            // === Middle Section: Avatar + Email ===
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color.fromARGB(255, 255, 255, 255)),
                  ),
                  child: ClipOval(
                    child: avatarImage != null
                        ? Image(
                            image: avatarImage!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                color: Color.fromARGB(255, 119, 123, 162)),
                          )
                        : const Icon(Icons.person,
                            color: Color.fromARGB(255, 138, 139, 171)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    email.isNotEmpty ? email : 'ไม่มีอีเมล',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            // === Bottom Section: View History Button and Regimen Button (Right) ===
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: onDetail_1,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A81BB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    label: Text(actionLabel_1),
                  ),
                  if (onDetail_2 != null && actionLabel_2 != null) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: onDetail_2,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5A81BB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      label: Text(actionLabel_2!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
