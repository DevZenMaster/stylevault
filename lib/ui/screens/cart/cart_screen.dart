import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/providers.dart';
import '../../widgets/widgets.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'YOUR BAG (${cart.itemCount})',
          style: AppTextStyles.headingSmall.copyWith(letterSpacing: 3),
        ),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      color: AppColors.textMuted, size: 64),
                  const SizedBox(height: 16),
                  const Text('Your bag is empty',
                      style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    child: CustomButton(
                      label: 'Start Shopping',
                      onPressed: () => context.push('/products'),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      return CartItemTile(
                        item: item,
                        onRemove: () => cart.removeItem(item.id),
                        onQuantityChanged: (q) =>
                            cart.updateQuantity(item.id, q),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border:
                        Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SUBTOTAL',
                              style: AppTextStyles.headingSmall),
                          Text(
                            'LKR ${cart.total.toStringAsFixed(0)}',
                            style: AppTextStyles.price,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        label: 'Proceed to Checkout',
                        onPressed: () => context.push('/checkout'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
