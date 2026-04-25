import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/models.dart';
import '../data/services/auth_service.dart';
import '../data/services/services.dart';

// ─── AUTH PROVIDER ─────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;
  String? _error;
  bool _isLockedOut = false;
  int _lockoutSecondsRemaining = 0;
  int _attemptsRemaining = 5;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isLockedOut => _isLockedOut;
  int get lockoutSeconds => _lockoutSecondsRemaining;
  int get attemptsRemaining => _attemptsRemaining;

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

  Future<void> refreshUser() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _user = await _authService.getUserData(firebaseUser.uid);
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _error = null;
    _isLockedOut = false;

    if (_authService.isLockedOut(email)) {
      _isLockedOut = true;
      _lockoutSecondsRemaining = _authService.lockoutSecondsRemaining(email);
      final mins = (_lockoutSecondsRemaining / 60).ceil();
      _error =
          'Too many failed attempts. Try again in $mins minute${mins == 1 ? '' : 's'}.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.login(email: email, password: password);
      _attemptsRemaining = 5;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e.toString());
      _isLockedOut = _authService.isLockedOut(email);
      _lockoutSecondsRemaining = _authService.lockoutSecondsRemaining(email);
      _attemptsRemaining = _authService.attemptsRemaining(email);
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
    _error = null;
    notifyListeners();
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    await _authService.updateUserProfile(updatedUser);
    _user = updatedUser;
    notifyListeners();
  }

  Future<bool> sendPasswordReset(String email) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        _error = 'No account found with that email address.';
        notifyListeners();
        return false;
      }
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _error = _parseError(e.toString());
      notifyListeners();
      return false;
    }
  }

  // ── Change password (reauthenticate first, then update) ────
  Future<void> reauthenticate(String email, String password) async {
    await _authService.reauthenticate(email, password);
  }

  Future<void> changePassword(String newPassword) async {
    await _authService.changePassword(newPassword);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _parseError(String raw) {
    if (raw.contains('user-not-found') || raw.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    if (raw.contains('wrong-password')) return 'Incorrect password.';
    if (raw.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    }
    if (raw.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }
    if (raw.contains('invalid-email')) return 'Please enter a valid email.';
    if (raw.contains('network-request-failed')) {
      return 'No internet connection. Please check your network.';
    }
    if (raw.contains('too-many-requests')) {
      final match = RegExp(r'message: (.+)\)').firstMatch(raw);
      return match?.group(1) ??
          'Too many attempts. Account temporarily locked.';
    }
    if (raw.contains('user-disabled')) {
      return 'This account has been disabled. Contact support.';
    }
    return 'Something went wrong. Please try again.';
  }
}


// ─── PRODUCT PROVIDER ──────────────────────────────────────────
class ProductProvider extends ChangeNotifier {
  final ProductService _service = ProductService();
  List<ProductModel> _products = [];
  List<ProductModel> _featured = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';

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
  int get itemCount => _items.fold(0, (acc, item) => acc + item.quantity);
  double get total => _items.fold(0.0, (acc, item) => acc + item.totalPrice);

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