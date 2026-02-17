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
    this.onDetail,
    this.actionLabel = 'ดูประวัติการทานยา',
    this.actionIcon = Icons.history,
  });

  final String name;
  final String email;
  final String avatarUrl;
  final ImageProvider? avatarImage;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDetail;
  final String actionLabel;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      elevation: 2,
      color: const Color.fromARGB(255, 232, 236, 241),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E6EF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
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
                        color: Color(0xFF1F497D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, color: Color(0xFF1F497D)),
                  tooltip: 'แก้ไข',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(2),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
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

            // === Bottom Section: View History Button (Right) ===
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F497D),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                label: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
