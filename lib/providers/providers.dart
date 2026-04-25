import 'package:flutter/material.dart';
import '../data/models/models.dart';
import '../data/services/auth_service.dart';
import '../data/services/services.dart';

// ─── AUTH PROVIDER ─────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true; // true until Firebase auth state is known
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  AuthProvider() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        _user = await _authService.getUserData(firebaseUser.uid);
      } else {
        _user = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Refresh user data from Firestore (useful after role change)
  Future<void> refreshUser() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _user = await _authService.getUserData(firebaseUser.uid);
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.login(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.register(
          name: name, email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    await _authService.updateUserProfile(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }

  String _parseError(String raw) {
    if (raw.contains('user-not-found')) return 'No account found with this email.';
    if (raw.contains('wrong-password')) return 'Incorrect password.';
    if (raw.contains('email-already-in-use')) return 'Email is already registered.';
    if (raw.contains('weak-password')) return 'Password should be at least 6 characters.';
    if (raw.contains('invalid-email')) return 'Please enter a valid email.';
    return 'An error occurred. Please try again.';
  }
}


// ─── PRODUCT PROVIDER ──────────────────────────────────────────
class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();
  List<ProductModel> _products = [];
  List<ProductModel> _featured = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final bool _isLoading = false;

  List<ProductModel> get products {
    List<ProductModel> list = _products;
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  List<ProductModel> get featured => _featured;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  void init() {
    _service.getProducts().listen((data) {
      _products = data;
      notifyListeners();
    });
    _service.getFeaturedProducts().listen((data) {
      _featured = data;
      notifyListeners();
    });
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _products = [];
    notifyListeners();
    _service.getProductsByCategory(category).listen((data) {
      _products = data;
      notifyListeners();
    });
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}


// ─── CART PROVIDER ─────────────────────────────────────────────
class CartProvider extends ChangeNotifier {
  final CartService _service = CartService();
  List<CartItemModel> _items = [];
  String? _userId;

  List<CartItemModel> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get total => _items.fold(0, (sum, item) => sum + item.totalPrice);

  void init(String userId) {
    _userId = userId;
    _service.getCartItems(userId).listen((data) {
      _items = data;
      notifyListeners();
    });
  }

  void clear() {
    _items = [];
    _userId = null;
    notifyListeners();
  }

  Future<void> addToCart(CartItemModel item) async {
    if (_userId == null) return;
    await _service.addToCart(_userId!, item);
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (_userId == null) return;
    await _service.updateQuantity(_userId!, itemId, quantity);
  }

  Future<void> removeItem(String itemId) async {
    if (_userId == null) return;
    await _service.removeFromCart(_userId!, itemId);
  }

  Future<void> clearCart() async {
    if (_userId == null) return;
    await _service.clearCart(_userId!);
  }
}


// ─── ORDER PROVIDER ────────────────────────────────────────────
class OrderProvider extends ChangeNotifier {
  final OrderService _service = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  void init(String userId) {
    _service.getUserOrders(userId).listen((data) {
      _orders = data;
      notifyListeners();
    });
  }

  Future<String?> placeOrder(OrderModel order) async {
    _isLoading = true;
    notifyListeners();
    try {
      final id = await _service.placeOrder(order);
      _isLoading = false;
      notifyListeners();
      return id;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}