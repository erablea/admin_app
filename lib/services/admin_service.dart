import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/main.dart';

/// 管理者向けのSupabaseアクセスを一元化するサービス。
/// useritemは常に読み取り専用として扱い、書き込みは一切行わない。
class AdminService {
  static final AdminService instance = AdminService._();
  AdminService._();

  User? get currentUser => supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String? get userId => currentUser?.id;

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  Future<bool> isAdmin() async {
    final uid = userId;
    if (uid == null) return false;
    final row = await supabase
        .from('user')
        .select('is_admin')
        .eq('user_id', uid)
        .maybeSingle();
    return row?['is_admin'] == true;
  }

  // ---------------- brand ----------------

  Future<List<Map<String, dynamic>>> getBrands({String? search}) async {
    var query = supabase.from('brand').select();
    if (search != null && search.isNotEmpty) {
      query = query.ilike('brand_name', '%$search%');
    }
    final data = await query.order('brand_name');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> upsertBrand(Map<String, dynamic> brand) async {
    await supabase.from('brand').upsert(brand);
  }

  Future<void> deleteBrand(String brandId) async {
    await supabase.from('brand').delete().eq('brand_id', brandId);
  }

  // ---------------- item ----------------

  Future<List<Map<String, dynamic>>> getItems({String? search}) async {
    var query = supabase.from('item').select();
    if (search != null && search.isNotEmpty) {
      query = query.ilike('item_name', '%$search%');
    }
    final data = await query.order('item_name');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> insertItem(Map<String, dynamic> item) async {
    return await supabase.from('item').insert(item).select().single();
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> item) async {
    await supabase.from('item').update(item).eq('item_id', itemId);
  }

  Future<void> deleteItem(String itemId) async {
    await supabase.from('item').delete().eq('item_id', itemId);
  }

  // ---------------- useritem（読み取り専用） ----------------

  /// まだ統合作業(useritem_review)で確認されていないuseritemを取得する。
  /// useritemテーブル自体へは一切書き込まない。
  Future<List<Map<String, dynamic>>> getUnreviewedUseritems() async {
    final reviewed = await supabase.from('useritem_review').select('useritem_id');
    final reviewedIds = reviewed.map((r) => r['useritem_id'].toString()).toSet();

    final data = await supabase.from('useritem').select();
    final rows = List<Map<String, dynamic>>.from(data);
    return rows.where((r) => !reviewedIds.contains(r['useritem_id'].toString())).toList();
  }

  // ---------------- useritem_review（昇格作業の記録。useritem自体は変更しない） ----------------

  Future<void> markPromoted({
    required String useritemId,
    required String promotedItemId,
  }) async {
    await supabase.from('useritem_review').insert({
      'useritem_id': useritemId,
      'reviewed_by': userId,
      'promoted_item_id': promotedItemId,
    });
  }

  Future<void> markReviewedWithoutPromotion(String useritemId) async {
    await supabase.from('useritem_review').insert({
      'useritem_id': useritemId,
      'reviewed_by': userId,
    });
  }
}
