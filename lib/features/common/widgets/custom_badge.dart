import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum StockStatus { inStock, lowStock, expiringSoon, expired }

class CustomBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color textColor;
  final Color backgroundColor;

  const CustomBadge({
    super.key,
    required this.text,
    this.icon,
    required this.textColor,
    required this.backgroundColor,
  });

  factory CustomBadge.status(StockStatus status, {int? quantity, String? labelOverride}) {
    switch (status) {
      case StockStatus.inStock:
        return CustomBadge(
          text: labelOverride ?? (quantity != null ? '$quantity in stock' : 'In Stock'),
          icon: Icons.check_circle_outline,
          textColor: AppColors.inStock,
          backgroundColor: AppColors.inStockBg,
        );
      case StockStatus.lowStock:
        return CustomBadge(
          text: labelOverride ?? (quantity != null ? 'Low Stock ($quantity)' : 'Low Stock'),
          icon: Icons.error_outline,
          textColor: AppColors.lowStock,
          backgroundColor: AppColors.lowStockBg,
        );
      case StockStatus.expiringSoon:
        return CustomBadge(
          text: labelOverride ?? 'Expiring Soon',
          icon: Icons.schedule,
          textColor: AppColors.expiringSoon,
          backgroundColor: AppColors.expiringSoonBg,
        );
      case StockStatus.expired:
        return CustomBadge(
          text: labelOverride ?? 'EXPIRED',
          icon: Icons.warning_amber_rounded,
          textColor: AppColors.expired,
          backgroundColor: AppColors.expiredBg,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
