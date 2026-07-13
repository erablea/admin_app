import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';
import 'package:admin_app/services/admin_service.dart';
import 'package:admin_app/services/similarity_util.dart';
import 'package:admin_app/view/merge/useritem_merge_detail_screen.dart';

class UseritemMergeScreen extends StatefulWidget {
  const UseritemMergeScreen({super.key});

  @override
  State<UseritemMergeScreen> createState() => _UseritemMergeScreenState();
}

class _UseritemMergeScreenState extends State<UseritemMergeScreen> {
  List<List<Map<String, dynamic>>> _clusters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final useritems = await AdminService.instance.getUnreviewedUseritems();
    setState(() {
      _clusters = clusterUseritems(useritems);
      _isLoading = false;
    });
  }

  Future<void> _openCluster(List<Map<String, dynamic>> cluster) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => UseritemMergeDetailScreen(cluster: cluster)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('統合作業')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clusters.isEmpty
              ? const Center(child: Text('未処理のデータはありません'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _clusters.length,
                  itemBuilder: (context, index) {
                    final cluster = _clusters[index];
                    final first = cluster.first;
                    final isSimilarGroup = cluster.length > 1;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          isSimilarGroup ? Icons.merge_type : Icons.inventory_2_outlined,
                          color: isSimilarGroup ? AppColors.primaryColor : AppColors.blackLight,
                        ),
                        title: Text(first['useritem_name'] ?? ''),
                        subtitle: Text(
                          isSimilarGroup
                              ? '類似データ ${cluster.length}件（ブランド: ${first['useritem_brand'] ?? '-'}）'
                              : 'ブランド: ${first['useritem_brand'] ?? '-'}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _openCluster(cluster),
                      ),
                    );
                  },
                ),
    );
  }
}
