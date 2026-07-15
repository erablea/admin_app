import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';
import 'package:admin_app/services/admin_service.dart';
import 'package:admin_app/widgets/common_widgets.dart';

class BrandFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initialBrand;

  const BrandFormScreen({super.key, this.initialBrand});

  @override
  State<BrandFormScreen> createState() => _BrandFormScreenState();
}

class _BrandFormScreenState extends State<BrandFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _companyController;
  late final TextEditingController _urlController;
  bool _isSaving = false;

  bool get _isEditing => widget.initialBrand != null;
  bool get _needsMoreInfo => _isEditing && CommonWidgets.brandCompletionPercent(widget.initialBrand!) < 100;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialBrand?['brand_name'] ?? '');
    _companyController = TextEditingController(text: widget.initialBrand?['brand_company'] ?? '');
    _urlController = TextEditingController(text: widget.initialBrand?['brand_url'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final data = {
        if (_isEditing) 'brand_id': widget.initialBrand!['brand_id'],
        'brand_name': _nameController.text.trim(),
        'brand_company': _companyController.text.trim(),
        'brand_url': _urlController.text.trim(),
      };
      await AdminService.instance.upsertBrand(data);
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
        content: Text('「${widget.initialBrand!['brand_name']}」を削除しますか？'),
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
      await AdminService.instance.deleteBrand(widget.initialBrand!['brand_id']);
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
        title: Text(
          _isEditing ? 'ブランド編集' : 'ブランド新規作成',
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
            if (_needsMoreInfo)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.errorColor.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.errorColor, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '未入力の項目があります。',
                        style: TextStyle(fontSize: 12, color: AppColors.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            TextFormField(
              controller: _nameController,
              decoration: CommonWidgets.buildInputDecoration('ブランド名 *', context: context),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'ブランド名を入力してください' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyController,
              decoration: CommonWidgets.buildInputDecoration('会社名', context: context),
            ),
            const SizedBox(height: 16),
            UrlInputField(controller: _urlController, label: '公式サイトURL'),
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
