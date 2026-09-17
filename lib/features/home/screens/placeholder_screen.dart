import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderScreen({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: palette.textTertiary),
          const SizedBox(height: 12),
          Text(
            '$title screen coming next',
            style: TextStyle(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}
