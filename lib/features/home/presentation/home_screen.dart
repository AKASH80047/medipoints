import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/pharmacy_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final salesAsync = ref.watch(salesProvider);
    final batchesAsync = ref.watch(batchesProvider);
    final alerts = ref.watch(stockAlertsProvider);
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    final ownerName = settingsAsync.value?.ownerName ?? 'Shop Owner';

    // Calculate today's metrics
    final now = DateTime.now();
    final todaySales = (salesAsync.value ?? []).where((s) {
      return s.dateTime.year == now.year &&
          s.dateTime.month == now.month &&
          s.dateTime.day == now.day;
    }).toList();

    final todaySalesTotal = todaySales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final todayBillsCount = todaySales.length;
    final itemsSoldTodayCount = todaySales.fold(0, (sum, s) {
      return sum + s.items.fold(0, (itemSum, item) => itemSum + item.quantity);
    });

    final totalCurrentStock = (batchesAsync.value ?? [])
        .fold(0, (sum, b) => sum + b.quantity);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_pharmacy, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, $ownerName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${settingsAsync.value?.shopName ?? AppConstants.defaultShopName} • ${AppConstants.appTagline}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's Sales Primary Card
              Card(
                color: AppColors.primary,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Today's Sales",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.receipt_long, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '$todayBillsCount Bills Today',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currencyFormatter.format(todaySalesTotal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Secondary Metrics Row (Items Sold & Total Stock)
              Row(
                children: [
                  Expanded(
                    child: _MiniMetricCard(
                      title: 'Items Sold Today',
                      value: '$itemsSoldTodayCount units',
                      icon: Icons.shopping_bag_outlined,
                      color: AppColors.secondary,
                      bgColor: AppColors.secondaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MiniMetricCard(
                      title: 'Current Stock',
                      value: '$totalCurrentStock units',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF4F46E5),
                      bgColor: const Color(0xFFEEF2FF),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Stock Status Alerts (Section 7 Requirements)
              const Text(
                'Shop Alerts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),

              if (alerts.lowStockBatches.isNotEmpty)
                _AlertCard(
                  icon: Icons.error_outline,
                  color: AppColors.lowStock,
                  bgColor: AppColors.lowStockBg,
                  message: '${alerts.lowStockBatches.length} medicines low in stock',
                  badgeEmoji: '🟠',
                  onTap: () => context.go('/stock?filter=low'),
                ),

              if (alerts.expiredBatches.isNotEmpty) ...[
                const SizedBox(height: 8),
                _AlertCard(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.expired,
                  bgColor: AppColors.expiredBg,
                  message: '${alerts.expiredBatches.length} medicines expired',
                  badgeEmoji: '🔴',
                  onTap: () => context.go('/stock?filter=expired'),
                ),
              ],

              if (alerts.expiringSoonBatches.isNotEmpty) ...[
                const SizedBox(height: 8),
                _AlertCard(
                  icon: Icons.schedule,
                  color: AppColors.expiringSoon,
                  bgColor: AppColors.expiringSoonBg,
                  message: '${alerts.expiringSoonBatches.length} medicines expiring soon',
                  badgeEmoji: '🟡',
                  onTap: () => context.go('/stock?filter=expiring'),
                ),
              ],

              if (alerts.lowStockBatches.isEmpty &&
                  alerts.expiredBatches.isEmpty &&
                  alerts.expiringSoonBatches.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.inStockBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.inStock, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'All medicine stock levels look healthy!',
                        style: TextStyle(
                          color: AppColors.inStock,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Large Quick Action Buttons (Section 7 & 8)
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width >= 600 ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 118,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _QuickActionButton(
                    title: 'New Bill',
                    subtitle: 'Create customer bill',
                    emoji: '🧾',
                    color: AppColors.primary,
                    bgColor: AppColors.primaryLight,
                    onTap: () => context.go('/billing'),
                  ),
                  _QuickActionButton(
                    title: 'Add Stock',
                    subtitle: 'Add new medicine',
                    emoji: '➕',
                    color: AppColors.secondary,
                    bgColor: AppColors.secondaryLight,
                    onTap: () => context.go('/stock?action=add'),
                  ),
                  _QuickActionButton(
                    title: 'View Stock',
                    subtitle: 'Check medicine list',
                    emoji: '📦',
                    color: const Color(0xFF4F46E5),
                    bgColor: const Color(0xFFEEF2FF),
                    onTap: () => context.go('/stock'),
                  ),
                  _QuickActionButton(
                    title: 'Purchase',
                    subtitle: 'Record supplier bill',
                    emoji: '🛒',
                    color: const Color(0xFF9333EA),
                    bgColor: const Color(0xFFF3E8FF),
                    onTap: () => context.go('/purchase'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _MiniMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String message;
  final String badgeEmoji;
  final VoidCallback onTap;

  const _AlertCard({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.message,
    required this.badgeEmoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Text(badgeEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: bgColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
