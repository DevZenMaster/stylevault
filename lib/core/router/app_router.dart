import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../ui/screens/splash/splash_screen.dart';
import '../../ui/screens/auth/login_screen.dart';
import '../../ui/screens/auth/register_screen.dart';
import '../../ui/screens/home/home_screen.dart';
import '../../ui/screens/products/product_listing_screen.dart';
import '../../ui/screens/products/product_detail_screen.dart';
import '../../ui/screens/cart/cart_screen.dart';
import '../../ui/screens/checkout/checkout_screen.dart';
import '../../ui/screens/orders/order_history_screen.dart';
import '../../ui/screens/profile/profile_screen.dart';
import '../../ui/screens/admin/admin_dashboard_screen.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (ctx, state) {
        final authProvider = ctx.read<AuthProvider>();
        final isLoggedIn = authProvider.isLoggedIn;
        final isAdmin = authProvider.user?.isAdmin ?? false;
        final location = state.uri.toString();
        final isAuthRoute = location == '/login' || location == '/register';

        if (!isLoggedIn && !isAuthRoute && location != '/splash') {
          return '/login';
        }
        if (isLoggedIn && isAuthRoute) {
          return isAdmin ? '/admin' : '/home';
        }
        if (location == '/admin' && !isAdmin) {
          return '/home';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/products',
          builder: (_, state) {
            final category = state.uri.queryParameters['category'] ?? 'All';
            return ProductListingScreen(category: category);
          },
        ),
        GoRoute(
          path: '/product/:id',
          builder: (_, state) {
            final id = state.pathParameters['id']!;
            return ProductDetailScreen(productId: id);
          },
        ),
        GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
        GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
        GoRoute(path: '/orders', builder: (_, __) => const OrderHistoryScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      ],
    );
  }
}