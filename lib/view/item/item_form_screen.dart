import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';
import 'package:admin_app/services/admin_service.dart';

const List<String> kItemGenres = ['クッキー', 'ショコラ', '和菓子', '焼き菓子', 'ゼリー・プリン', 'その他'];

class ItemFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initialItem;

  /// 統合作業(useritemの昇格)経由でこの画面が開かれた場合、
  /// 保存成功時にこれらのuseritem_idをuseritem_reviewへ記録する。
  /// useritem自体には一切書き込まない。
  final List<String>? promoteFromUseritemIds;

  const ItemFormScreen({super.key, this.initialItem, this.promoteFromUseritemIds});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _urlController;
  late final TextEditingController _expiryController;
  late final TextEditingController _image1Controller;
  late final TextEditingController _image2Controller;
  late final TextEditingController _image3Controller;

  Set<String> _selectedGenres = {};
  bool _individualWrapping = false;
  bool _roomTemperature = false;
  bool _online = false;

  List<Map<String, dynamic>> _brands = [];
  String? _brandId;
  bool _isLoadingBrands = true;
  bool _isSaving = false;

  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _nameController = TextEditingController(text: item?['item_name'] ?? '');
    _priceController = TextEditingController(text: item?['item_price']?.toString() ?? '');
    _urlController = TextEditingController(text: item?['item_url'] ?? '');
    _expiryController = TextEditingController(text: item?['item_expirydate']?.toString() ?? '');
    _image1Controller = TextEditingController(text: item?['item_imageurl1'] ?? '');
    _image2Controller = TextEditingController(text: item?['item_imageurl2'] ?? '');
    _image3Controller = TextEditingController(text: item?['item_imageurl3'] ?? '');

    final category = item?['item_category'] as String?;
    if (category != null && category.isNotEmpty) {
      _selectedGenres = category.split(',').map((e) => e.trim()).toSet();
    }
    _individualWrapping = _asBool(item?['item_individualwrapping']);
    _roomTemperature = _asBool(item?['item_roomtemperature']);
    _online = _asBool(item?['item_online']);
    _brandId = item?['brand_id']?.toString();

    _loadBrands();
  }

  bool _asBool(dynamic value) =>
      value == true || value == 1 || value == '1' || value == 'yes';

  Future<void> _loadBrands() async {
    final brands = await AdminService.instance.getBrands();
    setState(() {
      _brands = brands;
      _isLoadingBrands = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _urlController.dispose();
    _expiryController.dispose();
    _image1Controller.dispose();
    _image2Controller.dispose();
    _image3Controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final data = {
        'item_name': _nameController.text.trim(),
        'item_category': _selectedGenres.join(','),
        'item_price': int.tryParse(_priceController.text) ?? 0,
        'item_url': _urlController.text.trim(),
        'item_expirydate': int.tryParse(_expiryController.text),
        'item_individualwrapping': _individualWrapping,
        'item_roomtemperature': _roomTemperature,
        'item_online': _online,
        'item_imageurl1': _image1Controller.text.trim().isEmpty ? null : _image1Controller.text.trim(),
        'item_imageurl2': _image2Controller.text.trim().isEmpty ? null : _image2Controller.text.trim(),
        'item_imageurl3': _image3Controller.text.trim().isEmpty ? null : _image3Controller.text.trim(),
        'brand_id': _brandId,
      };

      if (_isEditing) {
        final itemId = widget.initialItem!['item_id'].toString();
        await AdminService.instance.updateItem(itemId, data);
      } else {
        final created = await AdminService.instance.insertItem(data);
        final newItemId = created['item_id'].toString();
        final promoteIds = widget.promoteFromUseritemIds;
        if (promoteIds != null) {
          for (final useritemId in promoteIds) {
            await AdminService.instance.markPromoted(
              useritemId: useritemId,
              promotedItemId: newItemId,
            );
          }
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('「${widget.initialItem!['item_name']}」を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: AppColors.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await AdminService.instance.deleteItem(widget.initialItem!['item_id'].toString());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('削除に失敗しました: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '商品編集' : (widget.promoteFromUseritemIds != null ? '商品として登録' : '商品新規作成')),
        actions: [
          if (_isEditing)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '商品名 *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? '商品名を入力してください' : null,
            ),
            const SizedBox(height: 16),
            _isLoadingBrands
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _brands.any((b) => b['brand_id'].toString() == _brandId) ? _brandId : null,
                    decoration: const InputDecoration(labelText: 'ブランド'),
                    items: _brands
                        .map((b) => DropdownMenuItem(
                              value: b['brand_id'].toString(),
                              child: Text(b['brand_name'] ?? ''),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _brandId = value),
                  ),
            const SizedBox(height: 16),
            const Text('ジャンル', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: kItemGenres.map((genre) {
                final isSelected = _selectedGenres.contains(genre);
                return FilterChip(
                  label: Text(genre),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGenres.add(genre);
                      } else {
                        _selectedGenres.remove(genre);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: '価格（税込・円）'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _expiryController,
              decoration: const InputDecoration(labelText: '賞味期限（日数）'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: '購入URL'),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('個包装'),
              value: _individualWrapping,
              onChanged: (v) => setState(() => _individualWrapping = v),
            ),
            SwitchListTile(
              title: const Text('常温保存可能'),
              value: _roomTemperature,
              onChanged: (v) => setState(() => _roomTemperature = v),
            ),
            SwitchListTile(
              title: const Text('オンライン購入可能'),
              value: _online,
              onChanged: (v) => setState(() => _online = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _image1Controller,
              decoration: const InputDecoration(labelText: '画像URL 1'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _image2Controller,
              decoration: const InputDecoration(labelText: '画像URL 2'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _image3Controller,
              decoration: const InputDecoration(labelText: '画像URL 3'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
