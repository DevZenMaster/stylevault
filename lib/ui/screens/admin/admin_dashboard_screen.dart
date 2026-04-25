import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../providers/admin_provider.dart';
import '../../widgets/widgets.dart';

// ─── Section enum ──────────────────────────────────────────────
enum _Section { dashboard, orders, customers, products, staff, settings }

extension _SectionLabel on _Section {
  String get label => switch (this) {
        _Section.dashboard => 'Dashboard',
        _Section.orders    => 'Orders',
        _Section.customers => 'Customers',
        _Section.products  => 'Products',
        _Section.staff     => 'Staff',
        _Section.settings  => 'Settings',
      };

  IconData get icon => switch (this) {
        _Section.dashboard => Icons.dashboard_outlined,
        _Section.orders    => Icons.receipt_long_outlined,
        _Section.customers => Icons.people_outline,
        _Section.products  => Icons.inventory_2_outlined,
        _Section.staff     => Icons.badge_outlined,
        _Section.settings  => Icons.settings_outlined,
      };
}

// ══════════════════════════════════════════════════════════════
//  ROOT SCREEN
// ══════════════════════════════════════════════════════════════
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _Section _current = _Section.dashboard;
  bool _drawerOpen = false;
  late final AdminProvider _admin;

  @override
  void initState() {
    super.initState();
    _admin = AdminProvider()
      ..listenUsers()
      ..listenOrders();
  }

  @override
  void dispose() {
    _admin.dispose();
    super.dispose();
  }

  void _select(_Section s) =>
      setState(() { _current = s; _drawerOpen = false; });

  Future<void> _logout() async {
    final ok = await _confirm(
        title: 'Logout', message: 'Sign out of the admin panel?',
        confirmLabel: 'Logout', destructive: false);
    if (ok != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    bool destructive = true,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(),
          title: Text(title, style: AppTextStyles.headingMedium),
          content: Text(message, style: AppTextStyles.bodyMedium),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel,
                  style: TextStyle(
                      color: destructive ? AppColors.error : AppColors.gold)),
            ),
          ],
        ),
      );

  Widget _panel() => switch (_current) {
        _Section.dashboard => _DashboardPanel(admin: _admin),
        _Section.orders    => _OrdersPanel(admin: _admin),
        _Section.customers => _CustomersPanel(admin: _admin),
        _Section.products  => _ProductsPanel(admin: _admin),
        _Section.staff     => _StaffPanel(admin: _admin),
        _Section.settings  => const _SettingsPanel(),
      };

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        leading: isWide
            ? null
            : IconButton(
                icon: Icon(
                    _drawerOpen ? Icons.close : Icons.menu,
                    color: AppColors.textPrimary),
                onPressed: () => setState(() => _drawerOpen = !_drawerOpen),
              ),
        title: Row(children: [
          const _LogoMark(size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_current.label.toUpperCase(),
                  style: AppTextStyles.headingSmall),
              const Text('Admin Panel',
                  style:  TextStyle(
                      color: AppColors.textMuted, fontSize: 10,
                      letterSpacing: 0.5)),
            ],
          ),
        ]),
        actions: [
          // Current user avatar
          Consumer<AuthProvider>(
            builder: (_, auth, __) {
              final user = auth.user;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _select(_Section.settings),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 1),
                    ),
                    child: ClipOval(
                      child: user?.photoUrl.isNotEmpty == true
                          ? Image.network(user!.photoUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _initialsWidget(user.name, 13))
                          : _initialsWidget(user?.name ?? 'A', 13),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error, size: 20),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Row(children: [
            if (isWide)
              _Sidebar(current: _current, onSelect: _select, onLogout: _logout),
            Expanded(child: _panel()),
          ]),
          if (!isWide && _drawerOpen) ...[
            GestureDetector(
              onTap: () => setState(() => _drawerOpen = false),
              child: Container(color: Colors.black54),
            ),
            SizedBox(
              width: 220,
              child: _Sidebar(
                  current: _current, onSelect: _select, onLogout: _logout),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _initialsWidget(String name, double fontSize) {
  return Container(
    color: AppColors.surfaceElevated,
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'A',
        style: TextStyle(
            color: AppColors.gold,
            fontSize: fontSize,
            fontWeight: FontWeight.w600),
      ),
    ),
  );
}

// ─── Logo mark ─────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(border: Border.all(color: AppColors.gold)),
      child: Center(
        child: Text('SV',
            style: TextStyle(
                color: AppColors.gold,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SIDEBAR
// ══════════════════════════════════════════════════════════════
class _Sidebar extends StatelessWidget {
  final _Section current;
  final void Function(_Section) onSelect;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.current,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(children: [
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            _LogoMark(size: 36),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STYLE VAULT',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
                Text('Admin Panel',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 32),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('NAVIGATION',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 8),
        ..._Section.values.map((s) => _SidebarItem(
              section: s,
              isActive: current == s,
              onTap: () => onSelect(s),
            )),
        const Spacer(),
        const Divider(color: AppColors.border, height: 1),
        // Current user info
        Consumer<AuthProvider>(
          builder: (_, auth, __) {
            final user = auth.user;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                  ),
                  child: ClipOval(
                    child: user?.photoUrl.isNotEmpty == true
                        ? Image.network(user!.photoUrl, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _initialsWidget(user.name, 11))
                        : _initialsWidget(user?.name ?? 'A', 11),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Admin',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                      Text(user?.role.toUpperCase() ?? 'ADMIN',
                          style: const TextStyle(
                              color: AppColors.gold, fontSize: 9,
                              letterSpacing: 1)),
                    ],
                  ),
                ),
              ]),
            );
          },
        ),
        GestureDetector(
          onTap: onLogout,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.logout, size: 16, color: AppColors.error),
              SizedBox(width: 10),
              Text('Logout',
                  style: TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _Section section;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem(
      {required this.section, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.gold.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          border: isActive
              ? const Border(left: BorderSide(color: AppColors.gold, width: 2))
              : null,
        ),
        child: Row(children: [
          Icon(section.icon,
              size: 18,
              color: isActive ? AppColors.gold : AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            section.label,
            style: TextStyle(
              color: isActive ? AppColors.gold : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              letterSpacing: 0.5,
            ),
          ),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  DASHBOARD PANEL
// ══════════════════════════════════════════════════════════════
class _DashboardPanel extends StatelessWidget {
  final AdminProvider admin;
  const _DashboardPanel({required this.admin});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: admin,
      builder: (_, __) {
        if (admin.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.gold));
        }
        final statusMap = admin.ordersByStatus;
        final screenWidth = MediaQuery.of(context).size.width;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('OVERVIEW', style: AppTextStyles.headingSmall),
                      const SizedBox(height: 4),
                      Text(
                        _greeting(),
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    _formattedDate(),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11,
                        letterSpacing: 0.5),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              // Stats grid — responsive
              LayoutBuilder(builder: (ctx, constraints) {
                final cardW = constraints.maxWidth > 600
                    ? (constraints.maxWidth - 48) / 4
                    : constraints.maxWidth > 400
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _StatCard(
                      label: 'Total Revenue',
                      value: 'LKR ${_compact(admin.totalRevenue)}',
                      icon: Icons.attach_money,
                      color: AppColors.gold,
                      width: cardW,
                      trend: '+12%',
                      trendUp: true,
                    ),
                    _StatCard(
                      label: 'Total Orders',
                      value: '${admin.totalOrderCount}',
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.success,
                      width: cardW,
                      trend: '${admin.totalOrderCount} total',
                      trendUp: null,
                    ),
                    _StatCard(
                      label: 'Pending',
                      value: '${admin.pendingCount}',
                      icon: Icons.hourglass_empty_outlined,
                      color: AppColors.warning,
                      width: cardW,
                      trend: admin.pendingCount > 5 ? 'Needs attention' : 'Looks good',
                      trendUp: admin.pendingCount <= 5,
                    ),
                    _StatCard(
                      label: 'Customers',
                      value: '${admin.customers.length}',
                      icon: Icons.people_outline,
                      color: AppColors.goldLight,
                      width: cardW,
                      trend: '${admin.staff.length} staff',
                      trendUp: null,
                    ),
                  ],
                );
              }),
              const SizedBox(height: 32),
              // Order Status + Recent Orders side by side on wide screens
              if (screenWidth >= 900)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildStatusSection(statusMap)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildRecentOrders()),
                  ],
                )
              else ...[
                _buildStatusSection(statusMap),
                const SizedBox(height: 32),
                _buildRecentOrders(),
              ],
            ],
          ),
        );
      },
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning, have a productive day!';
    if (h < 17) return 'Good afternoon, here\'s your overview.';
    return 'Good evening, here\'s your summary.';
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _compact(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  Widget _buildStatusSection(Map<String, int> statusMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ORDER STATUS', style: AppTextStyles.headingSmall),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            children: ['Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled']
                .map((s) => _StatusRow(
                    status: s,
                    count: statusMap[s] ?? 0,
                    total: admin.totalOrderCount))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentOrders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RECENT ORDERS', style: AppTextStyles.headingSmall),
        const SizedBox(height: 16),
        if (admin.orders.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            color: AppColors.surface,
            child: const Center(
                child: Text('No orders yet', style: AppTextStyles.bodyMedium)),
          )
        else
          ...admin.orders.take(5).map((o) => _OrderRowSimple(order: o)),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String status;
  final int count;
  final int total;
  const _StatusRow(
      {required this.status, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final pct = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        SizedBox(
          width: 90,
          child: Text(status,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 28,
          child: Text('$count',
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double width;
  final String trend;
  final bool? trendUp; // null = neutral

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
    required this.trend,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = trendUp == null
        ? AppColors.textMuted
        : trendUp!
            ? AppColors.success
            : AppColors.error;
    final trendIcon = trendUp == null
        ? Icons.remove
        : trendUp!
            ? Icons.trending_up
            : Icons.trending_down;

    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: color, width: 2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Icon(trendIcon, color: trendColor, size: 14),
          const SizedBox(width: 4),
          Text(trend,
              style: TextStyle(
                  color: trendColor, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 16),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ]),
    );
  }
}

class _OrderRowSimple extends StatelessWidget {
  final OrderModel order;
  const _OrderRowSimple({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      color: AppColors.surface,
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('#${order.id.substring(0, 8).toUpperCase()}',
                  style: AppTextStyles.headingSmall.copyWith(fontSize: 12)),
              Text(
                  order.userName.isNotEmpty
                      ? order.userName
                      : order.userEmail.isNotEmpty
                          ? order.userEmail
                          : order.userId,
                  style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        Text('LKR ${order.total.toStringAsFixed(0)}',
            style: AppTextStyles.priceSmall.copyWith(fontSize: 13)),
        const SizedBox(width: 12),
        _StatusBadge(order.status),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ORDERS PANEL
// ══════════════════════════════════════════════════════════════
class _OrdersPanel extends StatefulWidget {
  final AdminProvider admin;
  const _OrdersPanel({required this.admin});

  @override
  State<_OrdersPanel> createState() => _OrdersPanelState();
}

class _OrdersPanelState extends State<_OrdersPanel> {
  String _filter = 'All';
  String _search = '';
  static const _statuses = [
    'All', 'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.admin,
      builder: (_, __) {
        var orders = widget.admin.orders;
        if (_filter != 'All') {
          orders = orders.where((o) => o.status == _filter).toList();
        }
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          orders = orders
              .where((o) =>
                  o.userName.toLowerCase().contains(q) ||
                  o.userEmail.toLowerCase().contains(q) ||
                  o.id.toLowerCase().contains(q))
              .toList();
        }

        return Column(children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(
                style: AppTextStyles.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Search by name, email or order ID…',
                  prefixIcon: Icon(Icons.search,
                      color: AppColors.textMuted, size: 18),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.gold, width: 1.5)),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statuses.map((s) {
                    final active = _filter == s;
                    final color = s == 'All' ? AppColors.gold : _statusColor(s);
                    return GestureDetector(
                      onTap: () => setState(() => _filter = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: active
                              ? color.withValues(alpha: 0.15)
                              : AppColors.surfaceElevated,
                          border: active
                              ? Border.all(color: color)
                              : Border.all(color: Colors.transparent),
                        ),
                        child: Text(s,
                            style: TextStyle(
                                color: active ? color : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),
          Container(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text('${orders.length} order(s)', style: AppTextStyles.bodySmall),
            ]),
          ),
          Expanded(
            child: orders.isEmpty
                ? const Center(
                    child: Text('No orders found',
                        style: AppTextStyles.bodyMedium))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _OrderCard(
                      order: orders[i],
                      onStatusChange: (status) =>
                          widget.admin.updateOrderStatus(orders[i].id, status),
                    ),
                  ),
          ),
        ]);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final void Function(String) onStatusChange;
  static const _statuses = [
    'Pending', 'Processing', 'Shipped', 'Delivered', 'Cancelled'
  ];

  const _OrderCard({required this.order, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${order.id.substring(0, 8).toUpperCase()}',
                    style: AppTextStyles.headingSmall.copyWith(fontSize: 13)),
                Text(
                    order.userName.isNotEmpty
                        ? '${order.userName} • ${order.userEmail}'
                        : order.userEmail,
                    style: AppTextStyles.bodySmall),
                Text(
                    '${order.items.length} item(s) • LKR ${order.total.toStringAsFixed(0)}',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: AppColors.gold)),
              ],
            ),
          ),
          _StatusBadge(order.status),
        ]),
        const SizedBox(height: 8),
        Text('📍 ${order.address}', style: AppTextStyles.bodySmall),
        Text('📞 ${order.phone}', style: AppTextStyles.bodySmall),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statuses.map((s) {
              final active = order.status == s;
              final color = _statusColor(s);
              return GestureDetector(
                onTap: () => onStatusChange(s),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: active
                        ? color.withValues(alpha: 0.2)
                        : AppColors.surfaceElevated,
                    border: active ? Border.all(color: color) : null,
                  ),
                  child: Text(s,
                      style: TextStyle(
                          color: active ? color : AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8)),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  CUSTOMERS PANEL
// ══════════════════════════════════════════════════════════════
class _CustomersPanel extends StatefulWidget {
  final AdminProvider admin;
  const _CustomersPanel({required this.admin});

  @override
  State<_CustomersPanel> createState() => _CustomersPanelState();
}

class _CustomersPanelState extends State<_CustomersPanel> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.admin,
      builder: (_, __) {
        var list = widget.admin.customers;
        if (_search.isNotEmpty) {
          final q = _search.toLowerCase();
          list = list
              .where((u) =>
                  u.name.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q))
              .toList();
        }

        return Column(children: [
          _SearchBar(
              hint: 'Search customers…',
              onChanged: (v) => setState(() => _search = v)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.success, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text('${list.length} customer(s)',
                  style: AppTextStyles.bodySmall),
            ]),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text('No customers found',
                        style: AppTextStyles.bodyMedium))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final u = list[i];
                      return ListTile(
                        tileColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: _UserAvatar(user: u),
                        title: Text(u.name,
                            style: AppTextStyles.headingSmall
                                .copyWith(fontSize: 13)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.email, style: AppTextStyles.bodySmall),
                            if (u.phone.isNotEmpty)
                              Text(u.phone,
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error, size: 20),
                          tooltip: 'Remove customer',
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: AppColors.surface,
                                shape: const RoundedRectangleBorder(),
                                title: const Text('Delete Customer',
                                    style: AppTextStyles.headingMedium),
                                content: Text('Remove ${u.name}?',
                                    style: AppTextStyles.bodyMedium),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel',
                                        style: TextStyle(
                                            color: AppColors.textSecondary)),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete',
                                        style:
                                            TextStyle(color: AppColors.error)),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await widget.admin.deleteUser(u.uid);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ]);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  PRODUCTS PANEL
// ══════════════════════════════════════════════════════════════
class _ProductsPanel extends StatefulWidget {
  final AdminProvider admin;
  const _ProductsPanel({required this.admin});

  @override
  State<_ProductsPanel> createState() => _ProductsPanelState();
}

class _ProductsPanelState extends State<_ProductsPanel> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _search = '';
  String _categoryFilter = 'All';

  static const _cats = ['All', 'Men', 'Women', 'Kids', 'Accessories', 'Footwear', 'Sports'];

  void _openForm({ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(),
      builder: (_) => _ProductFormSheet(
        product: product,
        admin: widget.admin,
        onSave: (data) async {
          if (product == null) {
            await _db.collection('products').add({
              ...data,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } else {
            await _db.collection('products').doc(product.id).update(data);
          }
        },
      ),
    );
  }

  Future<void> _delete(ProductModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(),
        title: const Text('Delete Product', style: AppTextStyles.headingMedium),
        content: Text('Remove "${p.name}"?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.collection('products').doc(p.id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: TextField(
                style: AppTextStyles.bodyMedium,
                decoration: const InputDecoration(
                  hintText: 'Search products…',
                  prefixIcon:
                      Icon(Icons.search, color: AppColors.textMuted, size: 18),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.gold, width: 1.5)),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.background,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: const RoundedRectangleBorder(),
                elevation: 0,
              ),
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('ADD',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
            ),
          ]),
          // Category filter chips
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _cats.map((c) {
                final active = _categoryFilter == c;
                return GestureDetector(
                  onTap: () => setState(() => _categoryFilter = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.gold.withValues(alpha: 0.15)
                          : AppColors.surfaceElevated,
                      border: active
                          ? Border.all(color: AppColors.gold)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Text(c,
                        style: TextStyle(
                            color: active
                                ? AppColors.gold
                                : AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8)),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('products').orderBy('name').snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold));
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        color: AppColors.textMuted, size: 64),
                    const SizedBox(height: 16),
                    const Text('No products yet',
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 160,
                      child: CustomButton(
                          label: 'Add Product', onPressed: () => _openForm()),
                    ),
                  ],
                ),
              );
            }
            var products = snap.data!.docs
                .map((d) => ProductModel.fromMap(
                    d.data() as Map<String, dynamic>, d.id))
                .toList();
            if (_search.isNotEmpty) {
              products = products
                  .where((p) =>
                      p.name.toLowerCase().contains(_search.toLowerCase()))
                  .toList();
            }
            if (_categoryFilter != 'All') {
              products = products
                  .where((p) => p.category == _categoryFilter)
                  .toList();
            }
            if (products.isEmpty) {
              return const Center(
                  child: Text('No products match filter',
                      style: AppTextStyles.bodyMedium));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, i) {
                final p = products[i];
                return ListTile(
                  tileColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: _ProductThumb(imageUrl: p.imageUrl),
                  title: Text(p.name,
                      style:
                          AppTextStyles.headingSmall.copyWith(fontSize: 13)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LKR ${p.price.toStringAsFixed(0)}',
                          style: AppTextStyles.priceSmall
                              .copyWith(fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(children: [
                        _MicroBadge(p.category, AppColors.surfaceElevated),
                        const SizedBox(width: 6),
                        _MicroBadge(
                          'Stock: ${p.stock}',
                          p.stock > 0
                              ? AppColors.success
                              : AppColors.error,
                          textColor: AppColors.background,
                        ),
                        if (p.isFeatured) ...[
                          const SizedBox(width: 6),
                          const _MicroBadge('Featured', AppColors.gold,
                              textColor: AppColors.background),
                        ],
                      ]),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.gold, size: 20),
                        tooltip: 'Edit',
                        onPressed: () => _openForm(product: p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 20),
                        tooltip: 'Delete',
                        onPressed: () => _delete(p),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════
//  STAFF PANEL  (FIX: RadioListTile groupValue bug fixed)
// ══════════════════════════════════════════════════════════════
class _StaffPanel extends StatelessWidget {
  final AdminProvider admin;
  const _StaffPanel({required this.admin});

  void _showAddDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(),
        title: const Text('Add Staff Member', style: AppTextStyles.headingMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Enter the email of an existing user to promote them to staff.',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            CustomTextField(
                label: 'User Email',
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final email = emailCtrl.text.trim().toLowerCase();
              Navigator.pop(context);
              final match = admin.allUsers
                  .where((u) => u.email.toLowerCase() == email)
                  .toList();
              if (match.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No user found with that email.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              if (match.first.role == 'staff' || match.first.role == 'admin') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This user is already a staff/admin.'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              await admin.setUserRole(match.first.uid, 'staff');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User promoted to staff.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Promote',
                style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  /// FIX: StatefulBuilder properly tracks 'selected' for RadioListTile
  void _showEditRole(BuildContext context, UserModel u) {
  showDialog(
    context: context,
    builder: (_) {
      String selected = u.role;
      return StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(),
          title: Text('Edit Role — ${u.name}',
              style: AppTextStyles.headingMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['staff', 'admin', 'user'].map((r) {
              return ListTile(
                tileColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                leading: RadioGroup<String>(
  groupValue: selected,          // ← state lives HERE on the group
  onChanged: (val) {
    if (val != null) set(() => selected = val);
  },
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: ['staff', 'admin', 'user'].map((r) {
      return RadioListTile<String>(
        value: r,                // ← just the value, nothing else
        title: Text(r.toUpperCase(), style: AppTextStyles.bodyMedium),
        activeColor: AppColors.gold,
        tileColor: AppColors.surface,
      );
    }).toList(),
  ),
),
                title: Text(r.toUpperCase(), style: AppTextStyles.bodyMedium),
                onTap: () => set(() => selected = r),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await admin.setUserRole(u.uid, selected);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Role updated to ${selected.toUpperCase()}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Save',
                  style: TextStyle(color: AppColors.gold)),
            ),
          ],
        ),
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: admin,
      builder: (_, __) {
        final staffList = admin.staff;
        return Column(children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.goldLight, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text('${staffList.length} staff member(s)',
                  style: AppTextStyles.bodySmall),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.background,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: const RoundedRectangleBorder(),
                  elevation: 0,
                ),
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('ADD STAFF',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
              ),
            ]),
          ),
          Expanded(
            child: staffList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.badge_outlined,
                            color: AppColors.textMuted, size: 64),
                        const SizedBox(height: 16),
                        const Text('No staff members yet',
                            style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 160,
                          child: CustomButton(
                              label: 'Add Staff',
                              onPressed: () => _showAddDialog(context)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: staffList.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final u = staffList[i];
                      return ListTile(
                        tileColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: _UserAvatar(user: u),
                        title: Text(u.name,
                            style: AppTextStyles.headingSmall
                                .copyWith(fontSize: 13)),
                        subtitle: Text(u.email,
                            style: AppTextStyles.bodySmall),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _RoleBadge(u.role),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  color: AppColors.gold, size: 20),
                              tooltip: 'Edit role',
                              onPressed: () => _showEditRole(context, u),
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.person_remove_outlined,
                                  color: AppColors.error,
                                  size: 20),
                              tooltip: 'Demote to user',
                              onPressed: () async {
                                await admin.setUserRole(u.uid, 'user');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('User demoted.'),
                                      backgroundColor: AppColors.warning,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ]);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SETTINGS PANEL
// ══════════════════════════════════════════════════════════════
class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ACCOUNT', style: AppTextStyles.headingSmall),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          color: AppColors.surface,
          child: Row(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 1.5),
              ),
              child: ClipOval(
                child: user?.photoUrl.isNotEmpty == true
                    ? Image.network(user!.photoUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _initialsWidget(user.name, 20))
                    : _initialsWidget(user?.name ?? 'A', 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.name ?? 'Admin',
                      style: AppTextStyles.headingMedium),
                  Text(user?.email ?? '', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 6),
                  _RoleBadge(user?.role ?? 'admin'),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 32),
        const Text('APP INFO', style: AppTextStyles.headingSmall),
        const SizedBox(height: 12),
        const _SettingRow(Icons.info_outline, 'App Version', '1.0.0'),
        const _SettingRow(
            Icons.shield_outlined, 'Security', 'Rate-limiting enabled'),
        const _SettingRow(
            Icons.storage_outlined, 'Database', 'Cloud Firestore'),
        const _SettingRow(Icons.cloud_outlined, 'Auth', 'Firebase Auth'),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border:
                Border.all(color: AppColors.error.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DANGER ZONE',
                  style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
              const SizedBox(height: 8),
              const Text('Sign out from the admin panel.',
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: const RoundedRectangleBorder(),
                  ),
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.go('/login');
                  },
                  child: const Text('LOGOUT',
                      style: TextStyle(letterSpacing: 2, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SettingRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 1),
      color: AppColors.surface,
      child: Row(children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.bodyLarge),
        const Spacer(),
        Text(value, style: AppTextStyles.bodySmall),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  PRODUCT FORM SHEET
//  FIX: Properly validates image, handles upload errors gracefully
// ══════════════════════════════════════════════════════════════
class _ProductFormSheet extends StatefulWidget {
  final ProductModel? product;
  final AdminProvider admin;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _ProductFormSheet(
      {this.product, required this.admin, required this.onSave});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _sizes;
  late final TextEditingController _colors;
  String _category = 'Men';
  bool _isFeatured = false;
  bool _isSaving = false;
  bool _imageRequired = false; // tracks if image validation triggered

  File? _pickedImageFile;
  String _existingImageUrl = '';

  static const _categories = [
    'Men', 'Women', 'Kids', 'Accessories', 'Footwear', 'Sports'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(
        text: p != null ? p.price.toStringAsFixed(0) : '');
    _stock = TextEditingController(text: p != null ? '${p.stock}' : '');
    _existingImageUrl = p?.imageUrl ?? '';
    _sizes = TextEditingController(text: p?.sizes.join(', ') ?? '');
    _colors = TextEditingController(text: p?.colors.join(', ') ?? '');
    _category = p?.category ?? 'Men';
    _isFeatured = p?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    _stock.dispose();
    _sizes.dispose();
    _colors.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _pickedImageFile = File(picked.path);
        _imageRequired = false;
      });
    }
  }

  bool get _hasImage =>
      _pickedImageFile != null || _existingImageUrl.isNotEmpty;

  Future<void> _save() async {
    // Validate image first
    if (!_hasImage) {
      setState(() => _imageRequired = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a product image'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      String imageUrl = _existingImageUrl;
      if (_pickedImageFile != null) {
        imageUrl = await widget.admin.uploadProductImage(_pickedImageFile!);
      }

      final sizes = _sizes.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final colors = _colors.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await widget.onSave({
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'price': double.parse(_price.text.trim()),
        'stock': int.parse(_stock.text.trim()),
        'imageUrl': imageUrl,
        'category': _category,
        'isFeatured': _isFeatured,
        'sizes': sizes,
        'colors': colors,
        'rating': widget.product?.rating ?? 4.0,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving product: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                        width: 3, height: 18,
                        color: AppColors.gold,
                        margin: const EdgeInsets.only(right: 10),
                      ),
                      Text(isEdit ? 'EDIT PRODUCT' : 'ADD PRODUCT',
                          style: AppTextStyles.headingMedium),
                    ]),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Product Name',
                  controller: _name,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Description',
                  controller: _desc,
                  maxLines: 3,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Price (LKR)',
                      controller: _price,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        if (double.parse(v) <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Stock',
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Invalid';
                        if (int.parse(v) < 0) return 'Must be ≥ 0';
                        return null;
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // ── Product Image Picker ──────────────────────
                Text('Product Image',
                    style: TextStyle(
                        color: _imageRequired
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _pickImage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border.all(
                          color: _imageRequired
                              ? AppColors.error
                              : AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _pickedImageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(_pickedImageFile!,
                                fit: BoxFit.cover, width: double.infinity),
                          )
                        : _existingImageUrl.isNotEmpty
                            ? Stack(fit: StackFit.expand, children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(_existingImageUrl,
                                      fit: BoxFit.cover),
                                ),
                                Positioned(
                                  bottom: 8, right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit, size: 10,
                                            color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Change',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              ])
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      color: _imageRequired
                                          ? AppColors.error
                                          : AppColors.textMuted,
                                      size: 36),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to select image from gallery',
                                    style: TextStyle(
                                        color: _imageRequired
                                            ? AppColors.error
                                            : AppColors.textSecondary,
                                        fontSize: 13),
                                  ),
                                  if (_imageRequired)
                                    const Text('Image is required',
                                        style: TextStyle(
                                            color: AppColors.error,
                                            fontSize: 11)),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                    label: 'Sizes (e.g. S, M, L, XL)',
                    controller: _sizes),
                const SizedBox(height: 12),
                CustomTextField(
                    label: 'Colors (e.g. Black, White)',
                    controller: _colors),
                const SizedBox(height: 16),

                // Category dropdown
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  dropdownColor: AppColors.surfaceElevated,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.gold, width: 1.5)),
                    labelStyle:
                        TextStyle(color: AppColors.textSecondary),
                  ),
                  style: AppTextStyles.bodyLarge,
                  items: _categories
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 16),

                // Featured toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(children:  [
                        Icon(Icons.star_outline,
                            color: AppColors.gold, size: 18),
                        SizedBox(width: 10),
                        Text('Featured Product',
                            style: AppTextStyles.bodyLarge),
                      ]),
                      Switch(
                        value: _isFeatured,
                        activeThumbColor: AppColors.gold,
                        onChanged: (v) => setState(() => _isFeatured = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                CustomButton(
                  label: isEdit ? 'SAVE CHANGES' : 'ADD PRODUCT',
                  onPressed: _isSaving ? null : _save,
                  isLoading: _isSaving,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ══════════════════════════════════════════════════════════════
Color _statusColor(String status) => switch (status) {
      'Pending'    => AppColors.warning,
      'Processing' => AppColors.goldLight,
      'Shipped'    => AppColors.gold,
      'Delivered'  => AppColors.success,
      'Cancelled'  => AppColors.error,
      _            => AppColors.textSecondary,
    };

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(status,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8)),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge(this.role);

  @override
  Widget build(BuildContext context) {
    final color = switch (role) {
      'admin' => AppColors.gold,
      'staff' => AppColors.goldLight,
      _       => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(role.toUpperCase(),
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final UserModel user;
  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.surfaceElevated,
      backgroundImage:
          user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
      onBackgroundImageError: user.photoUrl.isNotEmpty
          ? (_, __) {}
          : null,
      child: user.photoUrl.isEmpty
          ? Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.gold, fontSize: 16))
          : null,
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final String imageUrl;
  const _ProductThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.border),
      ),
      child: imageUrl.isNotEmpty
          ? Image.network(imageUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image, color: AppColors.textMuted, size: 20))
          : const Icon(Icons.image, color: AppColors.textMuted, size: 20),
    );
  }
}

class _MicroBadge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;
  const _MicroBadge(this.text, this.bg,
      {this.textColor = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: bg,
      child: Text(text,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: textColor)),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search,
              color: AppColors.textMuted, size: 20),
          filled: true,
          fillColor: AppColors.surfaceElevated,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.border)),
          enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.gold, width: 1.5)),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
