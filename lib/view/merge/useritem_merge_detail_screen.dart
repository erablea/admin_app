import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';
import 'package:admin_app/services/admin_service.dart';
import 'package:admin_app/view/item/item_form_screen.dart';

/// クラスタ内のuseritem候補を目視比較し、採用する値を選んでitemへ昇格させる画面。
/// 昇格確定時にuseritem.item_idを紐づける以外、useritemの項目は変更しない。
class UseritemMergeDetailScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cluster;

  const UseritemMergeDetailScreen({super.key, required this.cluster});

  @override
  State<UseritemMergeDetailScreen> createState() => _UseritemMergeDetailScreenState();
}

class _UseritemMergeDetailScreenState extends State<UseritemMergeDetailScreen> {
  late Map<String, dynamic> _merged;
  bool _isProcessing = false;

  static const _fields = [
    ('useritem_name', '商品名'),
    ('useritem_brand', 'ブランド（参考。次の画面でbrandを選択）'),
    ('useritem_category', 'カテゴリ'),
    ('useritem_price', '価格'),
    ('useritem_URL', '購入URL'),
    ('useritem_image', '画像'),
  ];

  @override
  void initState() {
    super.initState();
    _merged = Map<String, dynamic>.from(widget.cluster.first);
  }

  List<String> get _useritemIds =>
      widget.cluster.map((e) => e['useritem_id'].toString()).toList();

  Future<void> _skipWithoutPromoting() async {
    setState(() => _isProcessing = true);
    try {
      for (final id in _useritemIds) {
        await AdminService.instance.markReviewedWithoutPromotion(id);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('処理に失敗しました: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _proceedToItemForm() async {
    final initialItem = {
      'item_name': _merged['useritem_name'],
      'item_category': _merged['useritem_category'],
      'item_price': _merged['useritem_price'],
      'item_url': _merged['useritem_URL'],
      'item_imageurl1': _merged['useritem_image'],
      'item_individualwrapping': _merged['useritem_individualwrapping'],
      'item_roomtemperature': _merged['useritem_roomtemperature'],
      'item_online': _merged['useritem_online'],
    };

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ItemFormScreen(
          initialItem: initialItem,
          initialBrandName: _merged['useritem_brand'] as String?,
          promoteFromUseritemIds: _useritemIds,
        ),
      ),
    );
    if (changed == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isCluster = widget.cluster.length > 1;
    return Scaffold(
      appBar: AppBar(title: Text(isCluster ? '類似データの統合' : '商品として登録')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isCluster)
            Text(
              '${widget.cluster.length}件の類似データが見つかりました。各項目でどの値を採用するか選んでください。',
              style: const TextStyle(color: AppColors.blackLight),
            ),
          const SizedBox(height: 16),
          for (final (field, label) in _fields) ...[
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.cluster.map((candidate) {
                final value = candidate[field];
                final isSelected = _merged[field] == value;
                return ChoiceChip(
                  label: Text(value?.toString().isEmpty ?? true ? '(空)' : value.toString()),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _merged[field] = value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : _skipWithoutPromoting,
                  child: const Text('統合せず既読にする'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _proceedToItemForm,
                  child: const Text('商品として登録へ進む'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
