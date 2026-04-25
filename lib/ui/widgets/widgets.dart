import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/models.dart';

// ─── CUSTOM BUTTON ─────────────────────────────────────────────
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;
  final Color? color;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gold,
            side: const BorderSide(color: AppColors.gold),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 18, width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
              : Text(label.toUpperCase()),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.gold,
          foregroundColor: AppColors.background,
        ),
        child: isLoading
            ? const SizedBox(
                height: 18, width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background))
            : Text(label.toUpperCase()),
      ),
    );
  }
}


// ─── CUSTOM TEXT FIELD ─────────────────────────────────────────
class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscure && !_visible,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      validator: widget.validator,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  _visible ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                onPressed: () => setState(() => _visible = !_visible),
              )
            : null,
      ),
    );
  }
}


// ─── PRODUCT CARD ──────────────────────────────────────────────
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: AppColors.surface,
                      highlightColor: AppColors.surfaceElevated,
                      child: Container(color: AppColors.surface),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surfaceElevated,
                      child: const Icon(Icons.image_not_supported,
                          color: AppColors.textMuted),
                    ),
                  ),
                  if (product.isFeatured)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        color: AppColors.gold,
                        child: Text('FEATURED',
                            style: AppTextStyles.labelGold.copyWith(
                                color: AppColors.background, fontSize: 9)),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: AppTextStyles.headingSmall.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('LKR ${product.price.toStringAsFixed(0)}',
                      style: AppTextStyles.priceSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── CART ITEM TILE ────────────────────────────────────────────
class CartItemTile extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  const CartItemTile({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      color: AppColors.surface,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              width: 80, height: 80,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.surfaceElevated),
              errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceElevated,
                  width: 80, height: 80,
                  child: const Icon(Icons.image, color: AppColors.textMuted)),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.headingSmall.copyWith(fontSize: 13)),
                if (item.size.isNotEmpty)
                  Text('Size: ${item.size}', style: AppTextStyles.bodySmall),
                const SizedBox(height: 8),
                Text('LKR ${item.totalPrice.toStringAsFixed(0)}',
                    style: AppTextStyles.priceSmall),
              ],
            ),
          ),
          // Quantity controls
          Column(
            children: [
              Row(
                children: [
                  _qtyButton(Icons.remove, () {
                    if (item.quantity > 1) {onQuantityChanged(item.quantity - 1);}
                    else {onRemove();}
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('${item.quantity}', style: AppTextStyles.bodyLarge),
                  ),
                  _qtyButton(Icons.add, () => onQuantityChanged(item.quantity + 1)),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onRemove,
                child: Text('REMOVE',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error, letterSpacing: 1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }
}
