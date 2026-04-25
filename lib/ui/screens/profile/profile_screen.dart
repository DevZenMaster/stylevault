import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  File? _pickedPhoto;
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

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _pickedPhoto = File(picked.path));
    }
  }

  // ── Cloudinary upload (FREE) ───────────────────────────────
  Future<String> _uploadPhotoToCloudinary(File imageFile) async {
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
      throw Exception('Image upload failed: ${json['error']['message']}');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();

    try {
      String photoUrl = auth.user!.photoUrl;
      if (_pickedPhoto != null) {
        photoUrl = await _uploadPhotoToCloudinary(_pickedPhoto!);
      }

      final updated = auth.user!.copyWith(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        photoUrl: photoUrl,
      );
      await auth.updateProfile(updated);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
        _pickedPhoto = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.error),
      );
    }
  }

  void _showChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) {
          bool processing = false;

          Future<void> handlePassUpdate() async {
            if (!formKey.currentState!.validate()) return;
            set(() => processing = true);
            try {
              final auth = ctx.read<AuthProvider>();
              await auth.reauthenticate(auth.user!.email, currentCtrl.text);
              await auth.changePassword(newCtrl.text);

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text('Password changed successfully'),
                      backgroundColor: AppColors.success),
                );
              }
            } catch (e) {
              if (ctx.mounted) {
                set(() => processing = false);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                      content: Text('Failed to change password: $e'),
                      backgroundColor: AppColors.error),
                );
              }
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: const RoundedRectangleBorder(),
            title: const Text('Change Password',
                style: AppTextStyles.headingMedium),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    label: 'Current Password',
                    controller: currentCtrl,
                    obscure: true,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'New Password',
                    controller: newCtrl,
                    obscure: true,
                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Confirm New Password',
                    controller: confirmCtrl,
                    obscure: true,
                    validator: (v) => v != newCtrl.text ? 'Passwords do not match' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: processing ? null : handlePassUpdate,
                child: processing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.gold))
                    : const Text('Change',
                        style: TextStyle(color: AppColors.gold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final hasPhoto = _pickedPhoto != null ||
        (user?.photoUrl != null && user!.photoUrl.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text('PROFILE',
            style: AppTextStyles.headingSmall.copyWith(letterSpacing: 4)),
        actions: [
          TextButton(
            onPressed: () {
              if (_editing) {
                _nameCtrl.text = user?.name ?? '';
                _phoneCtrl.text = user?.phone ?? '';
                _addressCtrl.text = user?.address ?? '';
                _pickedPhoto = null;
              }
              setState(() => _editing = !_editing);
            },
            child: Text(_editing ? 'CANCEL' : 'EDIT',
                style: AppTextStyles.labelGold),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Avatar ────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.gold, width: 1.5),
                          ),
                          child: ClipOval(
                            child: _pickedPhoto != null
                                ? Image.file(_pickedPhoto!,
                                    fit: BoxFit.cover)
                                : hasPhoto
                                    ? Image.network(
                                        user!.photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _avatarFallback(user.name),
                                      )
                                    : _avatarFallback(user?.name ?? ''),
                          ),
                        ),
                        if (_editing)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _pickProfilePhoto,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.gold,
                                ),
                                child: const Icon(Icons.edit,
                                    size: 14,
                                    color: AppColors.background),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(user?.name ?? '',
                        style: AppTextStyles.headingMedium),
                    Text(user?.email ?? '',
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 4),
                    _RoleBadge(user?.role ?? 'user'),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // ── Info / Edit form ───────────────────────────
              const Text('PERSONAL INFO',
                  style: AppTextStyles.headingSmall),
              const SizedBox(height: 20),

              if (_editing) ...[
                CustomTextField(
                  label: 'Full Name',
                  controller: _nameCtrl,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Phone Number',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Delivery Address',
                  controller: _addressCtrl,
                  maxLines: 2,
                ),
                const SizedBox(height: 28),
                CustomButton(
                  label: 'Save Changes',
                  onPressed: _save,
                  isLoading: _saving,
                ),
              ] else ...[
                _infoRow('Email', user?.email ?? '-'),
                _infoRow(
                    'Phone',
                    user?.phone.isEmpty == true
                        ? 'Not set'
                        : user!.phone),
                _infoRow(
                    'Address',
                    user?.address.isEmpty == true
                        ? 'Not set'
                        : user!.address),
              ],

              const SizedBox(height: 36),
              Container(height: 1, color: AppColors.border),
              const SizedBox(height: 20),

              // ── Menu ──────────────────────────────────────
              const Text('ACCOUNT', style: AppTextStyles.headingSmall),
              const SizedBox(height: 12),
              _menuItem(
                context,
                Icons.receipt_long_outlined,
                'My Orders',
                () => context.push('/orders'),
              ),
              const SizedBox(height: 1),
              _menuItem(
                context,
                Icons.lock_outline,
                'Change Password',
                _showChangePassword,
              ),
              const SizedBox(height: 1),
              _menuItem(
                context,
                Icons.logout,
                'Logout',
                () async {
                  await auth.logout();
                  if (context.mounted) context.go('/login');
                },
                color: AppColors.error,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: AppColors.surfaceElevated,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: AppColors.gold,
              fontSize: 32,
              fontWeight: FontWeight.w300),
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
            Icon(icon,
                color: color ?? AppColors.textSecondary, size: 20),
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

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge(this.role);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (role) {
      case 'admin':
        color = AppColors.gold;
        break;
      case 'staff':
        color = AppColors.goldLight;
        break;
      default:
        color = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5),
      ),
    );
  }
}