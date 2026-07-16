import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';
import 'package:admin_app/services/admin_service.dart';
import 'package:admin_app/view/brand/brand_list_screen.dart';
import 'package:admin_app/view/item/item_list_screen.dart';
import 'package:admin_app/view/item/item_order_screen.dart';
import 'package:admin_app/view/merge/useritem_merge_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理者ダッシュボード'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'サインアウト',
            onPressed: () => AdminService.instance.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DashboardTile(
            icon: Icons.reorder,
            title: 'home表示順の設定',
            subtitle: 'alamode_appのhome画面での商品表示順を並び替え',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ItemOrderScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _DashboardTile(
            icon: Icons.inventory_2_outlined,
            title: '商品管理',
            subtitle: 'itemマスタの作成・編集・削除',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ItemListScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _DashboardTile(
            icon: Icons.storefront_outlined,
            title: 'ブランド管理',
            subtitle: 'brandマスタの作成・編集・削除',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BrandListScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _DashboardTile(
            icon: Icons.merge_type,
            title: '統合作業',
            subtitle: 'ユーザー投稿(useritem)の類似データを商品マスタへ昇格',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UseritemMergeScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryColor, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
