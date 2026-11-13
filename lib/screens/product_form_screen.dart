import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../ui.dart';
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
  late final _price = TextEditingController(text: _existing?.price.round().toString());
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

  Future<void> _pickImage() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (x == null) return;
      // Copy out of the picker's temp cache (which the OS may clear) into app storage next to the DB.
      final dir = Directory(p.join(await getDatabasesPath(), 'product_images'));
      await dir.create(recursive: true);
      final saved = await File(x.path)
          .copy(p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}${p.extension(x.path)}'));
      if (mounted) setState(() => _image.text = saved.path);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không chọn được ảnh: $e')));
    }
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
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _pickImage,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: ClipRRect(
                    key: ValueKey(_image.text.trim()),
                    borderRadius: BorderRadius.circular(24),
                    child: ProductImage(_image.text.trim(), size: 180),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                spacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Chọn ảnh từ thư viện'),
                  ),
                  if (_image.text.trim().isNotEmpty)
                    TextButton.icon(
                      onPressed: () => setState(_image.clear),
                      icon: const Icon(Icons.close),
                      label: const Text('Bỏ ảnh'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên sản phẩm', prefixIcon: Icon(Icons.label_outline)),
              validator: (v) => notEmpty(v, 'Tên'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mô tả', alignLabelWithHint: true),
              validator: (v) => notEmpty(v, 'Mô tả'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giá (VNĐ)',
                prefixIcon: Icon(Icons.payments_outlined),
                suffixText: '₫',
              ),
              validator: validatePrice,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _image,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Hoặc dán URL ảnh (tuỳ chọn)', prefixIcon: Icon(Icons.link)),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 28),
            GradientButton(
              onPressed: _save,
              busy: _busy,
              icon: _isEdit ? Icons.save_outlined : Icons.add_rounded,
              label: _isEdit ? 'Lưu thay đổi' : 'Thêm sản phẩm',
            ),
          ],
        ),
      ),
    );
  }
}
