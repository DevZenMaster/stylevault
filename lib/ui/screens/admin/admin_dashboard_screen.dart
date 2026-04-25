import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/models.dart';
import '../../widgets/widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _openAddProductSheet({ProductModel? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _ProductFormSheet(
        product: product,
        onSave: (data) async {
          if (product == null) {
            await _db.collection('products').add(data);
          } else {
            await _db.collection('products').doc(product.id).update(data);
          }
        },
      ),
    );
  }

  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Product', style: AppTextStyles.headingMedium),
        content: const Text('Are you sure you want to delete this product?',
            style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.collection('products').doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ADMIN DASHBOARD', style: AppTextStyles.headingSmall),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.gold),
            onPressed: () => _openAddProductSheet(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.gold));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      color: AppColors.textMuted, size: 64),
                  const SizedBox(height: 16),
                  const Text('No products yet', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 200,
                    child: CustomButton(
                      label: 'Add Product',
                      onPressed: () => _openAddProductSheet(),
                    ),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!.docs
              .map((d) =>
                  ProductModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList();

          return Column(
            children: [
              // Stats bar
              Container(
                color: AppColors.surface,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    _StatChip(
                        label: 'Total Products',
                        value: '${products.length}'),
                    const SizedBox(width: 24),
                    _StatChip(
                        label: 'Featured',
                        value:
                            '${products.where((p) => p.isFeatured).length}'),
                    const SizedBox(width: 24),
                    _StatChip(
                        label: 'Out of Stock',
                        value:
                            '${products.where((p) => p.stock == 0).length}'),
                  ],
                ),
              ),
              const SizedBox(height: 1),
              // Product list
              Expanded(
                child: ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (_, i) {
                    final p = products[i];
                    return ListTile(
                      tileColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 56,
                        height: 56,
                        color: AppColors.surfaceElevated,
                        child: p.imageUrl.isNotEmpty
                            ? Image.network(p.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image,
                                    color: AppColors.textMuted))
                            : const Icon(Icons.image,
                                color: AppColors.textMuted),
                      ),
                      title: Text(p.name,
                          style: AppTextStyles.headingSmall
                              .copyWith(fontSize: 13)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LKR ${p.price.toStringAsFixed(0)}',
                              style: AppTextStyles.priceSmall
                                  .copyWith(fontSize: 13)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _Badge(p.category, AppColors.surfaceElevated),
                              const SizedBox(width: 6),
                              _Badge('Stock: ${p.stock}',
                                  p.stock > 0 ? AppColors.success : AppColors.error,
                                  textColor: AppColors.background),
                              if (p.isFeatured) ...[
                                const SizedBox(width: 6),
                                const _Badge('Featured', AppColors.gold,
                                    textColor: AppColors.background),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.gold, size: 20),
                            onPressed: () =>
                                _openAddProductSheet(product: p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error, size: 20),
                            onPressed: () => _deleteProduct(p.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        onPressed: () => _openAddProductSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── STAT CHIP ─────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTextStyles.headingMedium
                .copyWith(color: AppColors.gold, fontSize: 20)),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

// ─── BADGE ─────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;
  const _Badge(this.text, this.bg, {this.textColor = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: bg,
      child: Text(text,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: textColor)),
    );
  }
}

// ─── PRODUCT FORM SHEET ────────────────────────────────────────
class _ProductFormSheet extends StatefulWidget {
  final ProductModel? product;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _ProductFormSheet({this.product, required this.onSave});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _imageUrl;
  late final TextEditingController _sizes;
  late final TextEditingController _colors;
  String _category = 'Men';
  bool _isFeatured = false;
  bool _isSaving = false;

  final List<String> _categories = [
    'Men', 'Women', 'Kids', 'Accessories', 'Footwear'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(
        text: p != null ? p.price.toStringAsFixed(0) : '');
    _stock = TextEditingController(
        text: p != null ? '${p.stock}' : '');
    _imageUrl = TextEditingController(text: p?.imageUrl ?? '');
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
    _imageUrl.dispose();
    _sizes.dispose();
    _colors.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

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

    final data = {
      'name': _name.text.trim(),
      'description': _desc.text.trim(),
      'price': double.parse(_price.text.trim()),
      'stock': int.parse(_stock.text.trim()),
      'imageUrl': _imageUrl.text.trim(),
      'category': _category,
      'isFeatured': _isFeatured,
      'sizes': sizes,
      'colors': colors,
      'rating': widget.product?.rating ?? 4.0,
    };

    await widget.onSave(data);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                    Text(isEdit ? 'EDIT PRODUCT' : 'ADD PRODUCT',
                        style: AppTextStyles.headingMedium),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  label: 'Product Name',
                  controller: _name,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Description',
                  controller: _desc,
                  maxLines: 3,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Price (LKR)',
                        controller: _price,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid';
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
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Image URL',
                  controller: _imageUrl,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Sizes (comma separated: S, M, L, XL)',
                  controller: _sizes,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  label: 'Colors (comma separated: Black, White)',
                  controller: _colors,
                ),
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
                    labelStyle: TextStyle(color: AppColors.textSecondary),
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
                      horizontal: 12, vertical: 4),
                  color: AppColors.surfaceElevated,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Featured Product',
                          style: AppTextStyles.bodyLarge),
                      Switch(
                        value: _isFeatured,
                        activeThumbColor: AppColors.gold,
                        onChanged: (v) =>
                            setState(() => _isFeatured = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                CustomButton(
                  label: isEdit ? 'Save Changes' : 'Add Product',
                  onPressed: _save,
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