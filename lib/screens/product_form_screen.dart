import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import 'product_list_screen.dart';
import 'validators.dart';

/// Add a product (productId == null) or edit an existing one.
class ProductFormScreen extends ConsumerStatefulWidget {
  final int? productId;
  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _form = GlobalKey<FormState>();
  late final Product? _existing = widget.productId == null
      ? null
      : ref.read(productsProvider).value?.where((p) => p.id == widget.productId).firstOrNull;
  late final _name = TextEditingController(text: _existing?.name);
  late final _desc = TextEditingController(text: _existing?.description);
  late final _price = TextEditingController(text: _existing?.price.toString());
  late final _image = TextEditingController(text: _existing?.imageUrl);
  bool _busy = false;

  bool get _isEdit => widget.productId != null;

  @override
  void dispose() {
    for (final c in [_name, _desc, _price, _image]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final image = _image.text.trim();
    final p = Product(
      id: widget.productId,
      name: _name.text.trim(),
      description: _desc.text.trim(),
      price: double.parse(_price.text.trim()),
      imageUrl: image.isEmpty ? null : image,
    );
    final notifier = ref.read(productsProvider.notifier);
    _isEdit ? await notifier.edit(p) : await notifier.add(p);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(_isEdit ? 'Đã cập nhật sản phẩm' : 'Đã thêm sản phẩm')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit && _existing == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Không tìm thấy sản phẩm')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
              validator: (v) => notEmpty(v, 'Tên'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mô tả'),
              validator: (v) => notEmpty(v, 'Mô tả'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Giá', prefixText: '\$ '),
              validator: validatePrice,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _image,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'URL hình ảnh (tuỳ chọn)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ProductImage(_image.text.trim(), size: 160),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy ? const CircularProgressIndicator() : Text(_isEdit ? 'Lưu thay đổi' : 'Thêm'),
            ),
          ],
        ),
      ),
    );
  }
}
