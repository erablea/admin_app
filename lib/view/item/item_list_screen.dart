import 'package:flutter/material.dart';
import 'package:admin_app/services/admin_service.dart';
import 'package:admin_app/view/item/item_form_screen.dart';
import 'package:admin_app/widgets/common_widgets.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final items = await AdminService.instance.getItems(search: _search);
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _openForm([Map<String, dynamic>? item]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => ItemFormScreen(initialItem: item)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('商品管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: '商品名で検索',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                _search = value;
                _load();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('商品がありません'))
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final percent = CommonWidgets.itemCompletionPercent(item);
                          return ListTile(
                            title: Row(
                              children: [
                                Flexible(child: Text(item['item_name'] ?? '')),
                                const SizedBox(width: 8),
                                CommonWidgets.buildCompletionBadge(percent),
                              ],
                            ),
                            subtitle: Text('¥${CommonWidgets.formatCurrency(item['item_price10percent'] ?? 0)}'),
                            onTap: () => _openForm(item),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
