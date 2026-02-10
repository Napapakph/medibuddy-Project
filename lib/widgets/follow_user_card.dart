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
  });

  final String name;
  final String email;
  final String avatarUrl;
  final ImageProvider? avatarImage;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onDetail;

  Widget _buildActionButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
    double width = 40,
    double height = 40,
    double iconSize = 24,
  }) {
    return IconButton(
      constraints: BoxConstraints.tightFor(width: width, height: height),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize),
      color: Colors.white,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: const CircleBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDetail = onDetail != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFFD7DDE3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipOval(
              child: Container(
                width: 64,
                height: 64,
                color: const Color(0xFFE8EDF3),
                child: avatarImage != null
                    ? Image(
                        image: avatarImage!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, size: 32),
                      )
                    : const Icon(Icons.person, size: 32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    'ชื่อ :  $name',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF1F497D),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    email.isNotEmpty ? email : '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2F5788),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (hasDetail)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: Icons.delete,
                        backgroundColor: const Color(0xFFE66C63),
                        onPressed: onDelete,
                      ),
                      const SizedBox(width: 4),
                      _buildActionButton(
                        icon: Icons.edit,
                        backgroundColor: const Color(0xFF2F5788),
                        onPressed: onEdit ?? () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildActionButton(
                    icon: Icons.arrow_forward_ios,
                    backgroundColor: const Color(0xFF8BC0F0),
                    onPressed: onDetail!,
                    width: 42,
                    height: 42,
                    iconSize: 18,
                  ),
                ],
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    icon: Icons.delete,
                    backgroundColor: const Color(0xFFE66C63),
                    onPressed: onDelete,
                  ),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    icon: Icons.edit,
                    backgroundColor: const Color(0xFF2F5788),
                    onPressed: onEdit ??
                        () {
                          debugPrint('Edit pressed');
                        },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
