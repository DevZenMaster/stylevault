import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/providers.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppColors.warning;
      case 'Processing':
        return AppColors.gold;
      case 'Shipped':
        return AppColors.textPrimary;
      case 'Delivered':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>();
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MY ORDERS',
          style: AppTextStyles.headingSmall.copyWith(letterSpacing: 3),
        ),
      ),
      body: orders.orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.textMuted,
                    size: 64,
                  ),
                   SizedBox(height: 16),
                  Text('No orders yet', style: AppTextStyles.bodyMedium),
                   SizedBox(height: 8),
                  Text(
                    'Your order history will appear here',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 1),
              itemCount: orders.orders.length,
              itemBuilder: (_, i) {
                final order = orders.orders[i];
                final statusColor = _statusColor(order.status);

                return Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ORDER #${order.id.substring(0, 8).toUpperCase()}',
                            style: AppTextStyles.labelGold,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            color: statusColor.withValues(alpha: 0.15),
                            child: Text(
                              order.status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Date
                      Text(
                        fmt.format(order.createdAt),
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 12),

                      // Items
                      ...order.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Text('• ',
                                  style: TextStyle(color: AppColors.textMuted)),
                              Expanded(
                                child: Text(
                                  '${item.name}  ×${item.quantity}',
                                  style: AppTextStyles.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'LKR ${item.totalPrice.toStringAsFixed(0)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Divider(color: AppColors.border, height: 20),

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                            style: AppTextStyles.bodySmall,
                          ),
                          Text(
                            'LKR ${order.total.toStringAsFixed(0)}',
                            style: AppTextStyles.priceSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Address
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.address,
                              style: AppTextStyles.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}