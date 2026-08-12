import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../common/widgets/empty_state.dart';
import '../../models/sale_model.dart';
import '../../providers/pharmacy_providers.dart';
import '../../services/pdf_invoice_service.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesProvider);
    final alerts = ref.watch(stockAlertsProvider);
    final sales = salesAsync.value ?? [];
    final currencyFormatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    final now = DateTime.now();

    // Calculate Sales metrics
    final todaySales = sales.where((s) =>
        s.dateTime.year == now.year &&
        s.dateTime.month == now.month &&
        s.dateTime.day == now.day).toList();

    final weekSales = sales.where((s) {
      final diff = now.difference(s.dateTime).inDays;
      return diff <= 7;
    }).toList();

    final monthSales = sales.where((s) =>
        s.dateTime.year == now.year && s.dateTime.month == now.month).toList();

    final todayTotal = todaySales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final weekTotal = weekSales.fold(0.0, (sum, s) => sum + s.totalAmount);
    final monthTotal = monthSales.fold(0.0, (sum, s) => sum + s.totalAmount);

    // Payment distribution
    final cashTotal = sales
        .where((s) => s.paymentMethod == PaymentMethod.cash)
        .fold(0.0, (sum, s) => sum + s.totalAmount);
    final upiTotal = sales
        .where((s) => s.paymentMethod == PaymentMethod.upi)
        .fold(0.0, (sum, s) => sum + s.totalAmount);
    final cardTotal = sales
        .where((s) => s.paymentMethod == PaymentMethod.card)
        .fold(0.0, (sum, s) => sum + s.totalAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports 📊'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sales Metric Cards
              const Text(
                'Sales Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: "Today's Sales",
                      value: currencyFormatter.format(todayTotal),
                      subtitle: '${todaySales.length} Bills',
                      color: AppColors.primary,
                      bgColor: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      title: 'This Week',
                      value: currencyFormatter.format(weekTotal),
                      subtitle: '${weekSales.length} Bills',
                      color: AppColors.secondary,
                      bgColor: AppColors.secondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MetricCard(
                title: 'This Month Total',
                value: currencyFormatter.format(monthTotal),
                subtitle: '${monthSales.length} total bills completed this month',
                color: const Color(0xFF4F46E5),
                bgColor: const Color(0xFFEEF2FF),
              ),

              const SizedBox(height: 24),

              // Payment Method Breakdown
              const Text(
                'Payment Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _PaymentMetric(
                        emoji: '💵',
                        title: 'Cash',
                        amount: currencyFormatter.format(cashTotal),
                      ),
                      const SizedBox(height: 30, child: VerticalDivider()),
                      _PaymentMetric(
                        emoji: '📱',
                        title: 'UPI',
                        amount: currencyFormatter.format(upiTotal),
                      ),
                      const SizedBox(height: 30, child: VerticalDivider()),
                      _PaymentMetric(
                        emoji: '💳',
                        title: 'Card',
                        amount: currencyFormatter.format(cardTotal),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Stock Status Summary
              const Text(
                'Stock Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _StockStatBadge(
                      label: 'Total Medicines',
                      count: '${alerts.totalMedicineTypes}',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StockStatBadge(
                      label: 'Low Stock',
                      count: '${alerts.lowStockBatches.length}',
                      color: AppColors.lowStock,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StockStatBadge(
                      label: 'Expired',
                      count: '${alerts.expiredBatches.length}',
                      color: AppColors.expired,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Sales History Section
              const Text(
                'Sales History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 12),

              if (sales.isEmpty)
                const EmptyStateWidget(
                  title: 'No Sales Yet',
                  message: 'Your completed customer bills will appear here.',
                  icon: Icons.receipt_long_outlined,
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final s = sales[index];
                    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

                    return Card(
                      child: ListTile(
                        onTap: () => PdfInvoiceService.printInvoice(s),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Bill #${s.invoiceNumber}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '₹${s.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${dateFormat.format(s.dateTime)} • ${s.paymentMethod.icon} ${s.paymentMethod.displayName}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to print or view PDF bill receipt',
                              style: TextStyle(fontSize: 11, color: AppColors.primary.withOpacity(0.8)),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.print_outlined, color: AppColors.primary),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final Color bgColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}

class _PaymentMetric extends StatelessWidget {
  final String emoji;
  final String title;
  final String amount;

  const _PaymentMetric({
    required this.emoji,
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(amount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _StockStatBadge extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _StockStatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
