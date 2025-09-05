import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;
  final Widget? child;

  const CustomCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
    this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120, // 固定卡片高度
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              // 修复 withOpacity 警告
              color: Colors.black.withAlpha((255 * 0.08).round()),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 垂直居中对齐
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(icon, color: foregroundColor),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: foregroundColor,
                    ),
                  ),
                ),
              ],
            ),
            if (description != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  description!,
                  style: TextStyle(
                    fontSize: 12,
                    color: foregroundColor.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (child != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: child!,
              ),
          ],
        ),
      ),
    );
  }
}