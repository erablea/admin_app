import 'package:flutter/material.dart';
import 'package:admin_app/services/admin_service.dart';
import 'package:admin_app/view/brand/brand_form_screen.dart';

class BrandListScreen extends StatefulWidget {
  const BrandListScreen({super.key});

  @override
  State<BrandListScreen> createState() => _BrandListScreenState();
}

class _BrandListScreenState extends State<BrandListScreen> {
  List<Map<String, dynamic>> _brands = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final brands = await AdminService.instance.getBrands(search: _search);
    setState(() {
      _brands = brands;
      _isLoading = false;
    });
  }

  Future<void> _openForm([Map<String, dynamic>? brand]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => BrandFormScreen(initialBrand: brand)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ブランド管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'ブランド名で検索',
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
                : _brands.isEmpty
                    ? const Center(child: Text('ブランドがありません'))
                    : ListView.builder(
                        itemCount: _brands.length,
                        itemBuilder: (context, index) {
                          final brand = _brands[index];
                          return ListTile(
                            title: Text(brand['brand_name'] ?? ''),
                            subtitle: Text(
                              brand['brand_description'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _openForm(brand),
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
