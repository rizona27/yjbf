import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;
  final Widget? child;
  final bool isCompact;

  const CustomCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.onTap,
    this.child,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: isCompact ? _buildCompactContent() : _buildStandardContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 36, color: foregroundColor),
          const SizedBox(height: 8),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: foregroundColor.withOpacity(0.9),
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              fontSize: 12,
              color: foregroundColor.withOpacity(0.7),
            ),
          ),
        ],
        if (child != null) ...[
          const SizedBox(height: 12),
          child!,
        ],
      ],
    );
  }

  Widget _buildCompactContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24, color: foregroundColor),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: foregroundColor.withOpacity(0.9),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              fontSize: 12,
              color: foregroundColor.withOpacity(0.7),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          if (child == null)
            const SizedBox(height: 16),
        ],
        if (child != null) ...[
          const SizedBox(height: 8),
          child!,
        ],
      ],
    );
  }
}