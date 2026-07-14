import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:admin_app/main.dart';
import 'package:admin_app/services/admin_service.dart';
import 'package:admin_app/widgets/common_widgets.dart';

class ItemFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initialItem;

  /// useritemからの昇格時、ブランドIDは未確定なのでブランド名のヒントのみ渡す。
  final String? initialBrandName;

  /// 統合作業(useritemの昇格)経由でこの画面が開かれた場合、
  /// 保存成功時にこれらのuseritem_idをuseritem_reviewへ記録する。
  /// useritem自体には一切書き込まない。
  final List<String>? promoteFromUseritemIds;

  const ItemFormScreen({
    super.key,
    this.initialItem,
    this.initialBrandName,
    this.promoteFromUseritemIds,
  });

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandNameController;
  late final TextEditingController _priceController;
  late final TextEditingController _expiryController;
  late final TextEditingController _image1Controller;
  late final TextEditingController _image2Controller;
  late final TextEditingController _image3Controller;
  late final TextEditingController _urlController;
  late final TextEditingController _descriptionController;

  Set<String> _selectedGenres = {};
  bool? _individualWrapping;
  bool? _roomTemperature;
  bool? _online;

  List<Map<String, dynamic>> _brandSuggestions = [];
  bool _isSaving = false;

  // 統合作業(useritemの昇格)経由の場合はinitialItemがあってもitem_idを持たないため、
  // その場合は新規作成として扱う。
  bool get _isEditing => widget.initialItem != null && widget.initialItem!.containsKey('item_id');

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _nameController = TextEditingController(text: item?['item_name'] ?? '');
    _brandNameController = TextEditingController(text: widget.initialBrandName ?? '');
    _priceController = TextEditingController(
      text: item?['item_price'] != null ? CommonWidgets.formatCurrency(item!['item_price']) : '',
    );
    _expiryController = TextEditingController(text: item?['item_expirydate']?.toString() ?? '');
    _image1Controller = TextEditingController(text: item?['item_imageurl1'] ?? '');
    _image2Controller = TextEditingController(text: item?['item_imageurl2'] ?? '');
    _image3Controller = TextEditingController(text: item?['item_imageurl3'] ?? '');
    _urlController = TextEditingController(text: item?['item_url'] ?? '');
    _descriptionController = TextEditingController(text: item?['item_description'] ?? '');

    final category = item?['item_category'] as String?;
    if (category != null && category.isNotEmpty) {
      _selectedGenres = category.split(',').map((e) => e.trim()).toSet();
    }
    _individualWrapping = _asBool(item?['item_individualwrapping']);
    _roomTemperature = _asBool(item?['item_roomtemperature']);
    _online = _asBool(item?['item_online']);

    _loadBrandSuggestions();
    final brandId = item?['brand_id']?.toString();
    if (brandId != null) _loadBrandName(brandId);
  }

  bool? _asBool(dynamic value) {
    if (value == null) return null;
    if (value == true || value == 1 || value == '1' || value == 'yes') return true;
    if (value == false || value == 0 || value == '0' || value == 'no') return false;
    return null;
  }

  Future<void> _loadBrandSuggestions() async {
    final brands = await AdminService.instance.getBrands();
    if (mounted) setState(() => _brandSuggestions = brands);
  }

  Future<void> _loadBrandName(String brandId) async {
    final brand = await AdminService.instance.getBrandById(brandId);
    if (mounted && brand != null) {
      _brandNameController.text = brand['brand_name'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandNameController.dispose();
    _priceController.dispose();
    _expiryController.dispose();
    _image1Controller.dispose();
    _image2Controller.dispose();
    _image3Controller.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final brandName = _brandNameController.text.trim();
      final brandId = brandName.isEmpty
          ? null
          : await AdminService.instance.getOrCreateBrandByName(brandName);

      final rawPrice = _priceController.text.replaceAll(',', '');
      final data = {
        'item_name': _nameController.text.trim(),
        'item_category': _selectedGenres.join(','),
        'item_price': int.tryParse(rawPrice) ?? 0,
        'item_expirydate': int.tryParse(_expiryController.text),
        'item_individualwrapping': _individualWrapping,
        'item_roomtemperature': _roomTemperature,
        'item_online': _online,
        'item_imageurl1': _image1Controller.text.trim().isEmpty ? null : _image1Controller.text.trim(),
        'item_imageurl2': _image2Controller.text.trim().isEmpty ? null : _image2Controller.text.trim(),
        'item_imageurl3': _image3Controller.text.trim().isEmpty ? null : _image3Controller.text.trim(),
        'item_url': _urlController.text.trim(),
        'item_description': _descriptionController.text.trim(),
        'brand_id': brandId,
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
    final title = _isEditing
        ? '商品編集'
        : (widget.promoteFromUseritemIds != null ? '商品として登録' : '商品新規作成');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        elevation: 0,
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
              decoration: CommonWidgets.buildInputDecoration('商品名 *', context: context),
              validator: (v) => (v == null || v.trim().isEmpty) ? '必須項目です' : null,
            ),
            const SizedBox(height: 24),
            _buildBrandField(),
            const SizedBox(height: 24),
            CommonWidgets.buildGenreSelector(
              context: context,
              selectedGenres: _selectedGenres,
              onSelectionChanged: (newSelection) => setState(() => _selectedGenres = newSelection),
            ),
            const SizedBox(height: 24),
            CommonWidgets.buildOtherConditionSelector(
              context: context,
              individualWrapping: _individualWrapping,
              roomTemperature: _roomTemperature,
              online: _online,
              onChanged: (w, r, o) => setState(() {
                _individualWrapping = w;
                _roomTemperature = r;
                _online = o;
              }),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _priceController,
                    decoration: CommonWidgets.buildInputDecoration('金額', context: context),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter(),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Text('円', style: TextStyle(fontSize: 16, color: AppColors.blackLight, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _expiryController,
              decoration: CommonWidgets.buildInputDecoration('賞味期限（日数）', context: context),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('画像', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.blackLight)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _image1Controller,
                  decoration: CommonWidgets.buildInputDecoration('画像URL 1', context: context),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _image2Controller,
                  decoration: CommonWidgets.buildInputDecoration('画像URL 2', context: context),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _image3Controller,
                  decoration: CommonWidgets.buildInputDecoration('画像URL 3', context: context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _urlController,
              decoration: CommonWidgets.buildInputDecoration('購入URL', context: context),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _descriptionController,
              decoration: CommonWidgets.buildInputDecoration('商品説明', context: context),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.blackDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandField() {
    return Autocomplete<Map<String, dynamic>>(
      initialValue: TextEditingValue(text: _brandNameController.text),
      displayStringForOption: (option) => option['brand_name'] as String? ?? '',
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
        final query = textEditingValue.text.toLowerCase();
        return _brandSuggestions.where((b) => (b['brand_name'] as String? ?? '').toLowerCase().contains(query));
      },
      onSelected: (option) {
        _brandNameController.text = option['brand_name'] as String? ?? '';
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // AutocompleteのフィールドコントローラをFormの管理下のcontrollerと同期させる
        controller.text = _brandNameController.text;
        controller.addListener(() => _brandNameController.text = controller.text);
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: CommonWidgets.buildInputDecoration('ブランド・会社名 *', context: context),
          validator: (v) => (v == null || v.trim().isEmpty) ? '必須項目です' : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 400),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option['brand_name'] as String? ?? ''),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
