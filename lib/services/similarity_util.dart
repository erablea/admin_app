/// useritem内の類似データ検出のための簡易な文字列正規化・クラスタリング。
/// 会社表記ゆれ・全角半角・空白を吸収して同一商品らしさを判定する。
/// 意味的なAIマッチングではなく、文字列一致ベースのv1実装。
String normalizeForMatch(String? input) {
  if (input == null) return '';
  return input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'(株式会社|合同会社|有限会社)'), '')
      .replaceAll(RegExp(r'[\s　・,、。\-ー]'), '');
}

String _matchKey(Map<String, dynamic> useritem) {
  final name = normalizeForMatch(useritem['useritem_name'] as String?);
  final category = normalizeForMatch(useritem['useritem_category'] as String?);
  return '$name|$category';
}

/// useritem一覧を「名前+カテゴリ」の正規化キーでクラスタリングする。
List<List<Map<String, dynamic>>> clusterUseritems(List<Map<String, dynamic>> useritems) {
  final groups = <String, List<Map<String, dynamic>>>{};
  for (final item in useritems) {
    final key = _matchKey(item);
    groups.putIfAbsent(key, () => []).add(item);
  }
  final clusters = groups.values.toList();
  // 類似候補（複数件）を先頭に、単独データを後ろに並べる
  clusters.sort((a, b) => b.length.compareTo(a.length));
  return clusters;
}
