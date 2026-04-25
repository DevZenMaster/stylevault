import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/providers.dart';
import '../../widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('STYLEVAULT',
                style: AppTextStyles.headingSmall
                    .copyWith(color: AppColors.gold, letterSpacing: 4)),
          ],
        ),
        actions: [
          badges.Badge(
            badgeContent: Text('${cart.itemCount}',
                style: const TextStyle(color: Colors.white, fontSize: 10)),
            showBadge: cart.itemCount > 0,
            child: IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              onPressed: () => context.push('/cart'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Hero Banner
          SliverToBoxAdapter(
            child: Container(
              height: 220,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.background,
                            AppColors.surfaceElevated
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('NEW SEASON', style: AppTextStyles.labelGold),
                        const SizedBox(height: 8),
                        Text('STYLE\nREDEFINED',
                            style: AppTextStyles.displayMedium
                                .copyWith(height: 1)),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => context.push('/products'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            color: AppColors.gold,
                            child: Text('SHOP NOW',
                                style: AppTextStyles.labelGold
                                    .copyWith(color: AppColors.background)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SHOP BY CATEGORY', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppConstants.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final cat = AppConstants.categories[i];
                        final selected = products.selectedCategory == cat;
                        return GestureDetector(
                          onTap: () {
                            context.read<ProductProvider>().setCategory(cat);
                            context.push('/products?category=$cat');
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            color: selected ? AppColors.gold : AppColors.surface,
                            child: Text(
                              cat.toUpperCase(),
                              style: AppTextStyles.labelGold.copyWith(
                                color: selected
                                    ? AppColors.background
                                    : AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Featured Products header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('FEATURED', style: AppTextStyles.headingSmall),
                  GestureDetector(
                    onTap: () => context.push('/products'),
                    child: Text('VIEW ALL',
                        style:
                            AppTextStyles.labelGold.copyWith(fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),

          // Featured Grid
          products.featured.isEmpty
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                          strokeWidth: 1, color: AppColors.gold),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final p = products.featured[i];
                        return ProductCard(
                          product: p,
                          onTap: () => context.push('/product/${p.id}'),
                        );
                      },
                      childCount: products.featured.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 1,
                      mainAxisSpacing: 1,
                      childAspectRatio: 0.68,
                    ),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
          color: AppColors.background,
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.gold,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle:
              const TextStyle(fontSize: 9, letterSpacing: 1),
          unselectedLabelStyle:
              const TextStyle(fontSize: 9, letterSpacing: 1),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined), label: 'HOME'),
            BottomNavigationBarItem(
                icon: Icon(Icons.grid_view_outlined), label: 'SHOP'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined), label: 'CART'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined), label: 'ORDERS'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'PROFILE'),
          ],
          onTap: (i) {
            switch (i) {
              case 0:
                context.go('/home');
              case 1:
                context.push('/products');
              case 2:
                context.push('/cart');
              case 3:
                context.push('/orders');
              case 4:
                context.push('/profile');
            }
          },
        ),
      ),
    );
  }
}