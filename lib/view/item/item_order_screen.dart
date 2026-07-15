import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';
import 'package:admin_app/services/admin_service.dart';

/// alamode_appのhome画面での商品表示順を編集する画面。
class ItemOrderScreen extends StatefulWidget {
  const ItemOrderScreen({super.key});

  @override
  State<ItemOrderScreen> createState() => _ItemOrderScreenState();
}

class _ItemOrderScreenState extends State<ItemOrderScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final items = await AdminService.instance.getItemsForOrdering();
    setState(() {
      _items = items;
      _isLoading = false;
      _hasChanges = false;
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final ids = _items.map((e) => e['item_id'].toString()).toList();
      await AdminService.instance.saveDisplayOrder(ids);
      setState(() => _hasChanges = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('表示順を保存しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('home表示順の設定'),
        actions: [
          TextButton(
            onPressed: (_hasChanges && !_isSaving) ? _save : null,
            child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('保存'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: AppColors.greyLight,
                  child: const Text(
                    '上にあるものほどalamode_appのhome(表示順ソート時)で先に表示されます。ドラッグして並び替えてください。',
                    style: TextStyle(fontSize: 12, color: AppColors.blackLight),
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    itemCount: _items.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        key: ValueKey(item['item_id']),
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                          child: Text('${index + 1}', style: const TextStyle(fontSize: 12, color: AppColors.primaryColor)),
                        ),
                        title: Text(item['item_name'] ?? ''),
                        trailing: const Icon(Icons.drag_handle),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
