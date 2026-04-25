import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/providers.dart';
import '../../widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.name;
      _phoneCtrl.text = user.phone;
      _addressCtrl.text = user.address;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final updated = auth.user!.copyWith(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );
    await auth.updateProfile(updated);
    setState(() {
      _saving = false;
      _editing = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.success));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('PROFILE',
            style: AppTextStyles.headingSmall.copyWith(letterSpacing: 4)),
        actions: [
          TextButton(
            onPressed: () => setState(() => _editing = !_editing),
            child: Text(_editing ? 'CANCEL' : 'EDIT',
                style: AppTextStyles.labelGold),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.gold, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        (user?.name.isNotEmpty == true)
                            ? user!.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? '', style: AppTextStyles.headingMedium),
                  Text(user?.email ?? '', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 40),

            const Text('PERSONAL INFO', style: AppTextStyles.headingSmall),
            const SizedBox(height: 20),

            if (_editing) ...[
              CustomTextField(label: 'Full Name', controller: _nameCtrl),
              const SizedBox(height: 16),
              CustomTextField(
                  label: 'Phone',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              CustomTextField(
                  label: 'Address',
                  controller: _addressCtrl,
                  maxLines: 2),
              const SizedBox(height: 32),
              CustomButton(
                  label: 'Save Changes',
                  onPressed: _save,
                  isLoading: _saving),
            ] else ...[
              _infoRow('Email', user?.email ?? '-'),
              _infoRow('Phone',
                  user?.phone.isEmpty == true ? '-' : user!.phone),
              _infoRow('Address',
                  user?.address.isEmpty == true ? '-' : user!.address),
            ],

            const SizedBox(height: 40),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 24),

            _menuItem(context, Icons.receipt_long_outlined, 'My Orders',
                () => context.push('/orders')),
            const SizedBox(height: 4),
            _menuItem(context, Icons.logout, 'Logout', () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            }, color: AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.labelGold.copyWith(fontSize: 10)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.bodyLarge),
          const Divider(color: AppColors.border),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: AppTextStyles.bodyLarge
                    .copyWith(color: color ?? AppColors.textPrimary)),
            const Spacer(),
            const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
