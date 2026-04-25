import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<OrderModel> _orders = [];
  List<UserModel> _allUsers = [];
  bool _ordersLoading = true;
  bool _usersLoading = true;

  StreamSubscription? _ordersSub;
  StreamSubscription? _usersSub;

  List<OrderModel> get orders => _orders;
  List<UserModel> get customers =>
      _allUsers.where((u) => u.role == 'user').toList();
  List<UserModel> get staff =>
      _allUsers.where((u) => u.role == 'staff' || u.role == 'admin').toList();
  List<UserModel> get allUsers => _allUsers;
  bool get isLoading => _ordersLoading || _usersLoading;

  // ── Stats ──────────────────────────────────────────────────
  double get totalRevenue => _orders
      .where((o) => o.status == 'Delivered')
      .fold(0.0, (s, o) => s + o.total);

  int get pendingCount =>
      _orders.where((o) => o.status == 'Pending').length;

  int get totalOrderCount => _orders.length;

  Map<String, int> get ordersByStatus {
    final map = <String, int>{};
    for (final o in _orders) {
      map[o.status] = (map[o.status] ?? 0) + 1;
    }
    return map;
  }

  // ── Listeners ──────────────────────────────────────────────
  void listenOrders() {
    _ordersSub?.cancel();
    _ordersLoading = true;
    _ordersSub = _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      _orders =
          snap.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList();
      _ordersLoading = false;
      notifyListeners();
    }, onError: (_) {
      _ordersLoading = false;
      notifyListeners();
    });
  }

  void listenUsers() {
    _usersSub?.cancel();
    _usersLoading = true;
    _usersSub = _db.collection('users').snapshots().listen((snap) {
      _allUsers =
          snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
      _usersLoading = false;
      notifyListeners();
    }, onError: (_) {
      _usersLoading = false;
      notifyListeners();
    });
  }

  // ── Order operations ───────────────────────────────────────
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({'status': status});
  }

  // ── User operations ────────────────────────────────────────
  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  Future<void> setUserRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'role': role});
  }

  // ── Image upload (Cloudinary - FREE) ───────────────────────
  Future<String> uploadProductImage(File imageFile) async {
    const cloudName = 'dy9a0l49t';
    const uploadPreset = 'nmtpvo2p';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body);

    if (response.statusCode == 200) {
      return json['secure_url'] as String;
    } else {
      throw Exception('Cloudinary upload failed: ${json['error']['message']}');
    }
  }

  // ── Product operations ─────────────────────────────────────
  Future<void> addProduct(Map<String, dynamic> data) async {
    await _db.collection('products').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _db.collection('products').doc(id).update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    _usersSub?.cancel();
    super.dispose();
  }
}