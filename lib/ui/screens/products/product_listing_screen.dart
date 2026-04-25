import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/providers.dart';
import '../../widgets/widgets.dart';

class ProductListingScreen extends StatefulWidget {
  final String category;
  const ProductListingScreen({super.key, this.category = 'All'});
  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().setCategory(widget.category);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('SHOP',
            style: AppTextStyles.headingSmall.copyWith(letterSpacing: 4)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: AppTextStyles.bodyLarge,
              onChanged: (v) => context.read<ProductProvider>().setSearch(v),
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon:
                    Icon(Icons.search, size: 18, color: AppColors.textMuted),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: AppConstants.categories.length,
              itemBuilder: (_, i) {
                final cat = AppConstants.categories[i];
                final selected = products.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        context.read<ProductProvider>().setCategory(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      color:
                          selected ? AppColors.gold : AppColors.surface,
                      child: Text(
                        cat.toUpperCase(),
                        style: AppTextStyles.labelGold.copyWith(
                          fontSize: 10,
                          color: selected
                              ? AppColors.background
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: products.products.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 1, color: AppColors.gold))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 1,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: products.products.length,
                    itemBuilder: (_, i) {
                      final p = products.products[i];
                      return ProductCard(
                        product: p,
                        onTap: () => context.push('/product/${p.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
