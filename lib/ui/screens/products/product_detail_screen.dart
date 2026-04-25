import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/providers.dart';
import '../../../data/models/models.dart';
import '../../widgets/widgets.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedSize;
  String? _selectedColor;
  bool _adding = false;

  Future<void> _addToCart(product) async {
    if (product.sizes.isNotEmpty && _selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a size')));
      return;
    }
    setState(() => _adding = true);
    final cart = context.read<CartProvider>();
    final item = CartItemModel(
      id: '',
      productId: product.id,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
      size: _selectedSize ?? '',
      color: _selectedColor ?? '',
    );
    await cart.addToCart(item);
    setState(() => _adding = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final product =
        products.products.where((p) => p.id == widget.productId).firstOrNull;

    if (product == null) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(
                  strokeWidth: 1, color: AppColors.gold)));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceElevated,
                    child: const Icon(Icons.image,
                        color: AppColors.textMuted, size: 80)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.category.toUpperCase(),
                      style: AppTextStyles.labelGold),
                  const SizedBox(height: 8),
                  Text(product.name, style: AppTextStyles.headingLarge),
                  const SizedBox(height: 12),
                  Text('LKR ${product.price.toStringAsFixed(0)}',
                      style: AppTextStyles.price),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star, color: AppColors.gold, size: 16),
                    const SizedBox(width: 4),
                    Text('${product.rating}',
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(width: 12),
                    Text('In stock: ${product.stock}',
                        style: AppTextStyles.bodySmall),
                  ]),
                  const SizedBox(height: 20),
                  Text(product.description, style: AppTextStyles.bodyMedium),

                  if (product.sizes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('SIZE', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: product.sizes.map((s) {
                        final sel = _selectedSize == s;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSize = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: sel
                                      ? AppColors.gold
                                      : AppColors.border,
                                  width: sel ? 2 : 1),
                              color: sel
                                  ? AppColors.gold.withValues(alpha: 0.1)
                                  : AppColors.surface,
                            ),
                            child: Center(
                              child: Text(s,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                      color: sel
                                          ? AppColors.gold
                                          : AppColors.textSecondary)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  if (product.colors.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('COLOR', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: product.colors.map((c) {
                        final sel = _selectedColor == c;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: sel
                                      ? AppColors.gold
                                      : AppColors.border),
                            ),
                            child: Text(c,
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: sel
                                        ? AppColors.gold
                                        : AppColors.textSecondary)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 32),
                  CustomButton(
                    label: 'Add to Cart',
                    onPressed: () => _addToCart(product),
                    isLoading: _adding,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    label: 'View Cart',
                    outlined: true,
                    onPressed: () => context.push('/cart'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
