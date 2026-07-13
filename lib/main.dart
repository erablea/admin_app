import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '管理者アプリ',
      theme: ThemeData(
        primaryColor: const Color(0xFFBBEFF8),
        primaryColorLight: const Color(0xFFE6F7FC),
        primaryColorDark: const Color(0xFFA1D9E5),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFBBEFF8),
          secondary: Color(0xFFF4DFFF),
          surface: Colors.white,
          error: Color(0xFFB9727C),
          onPrimary: Color(0xFF3C3C3C),
          onSecondary: Colors.white,
          onSurface: Color(0xFF3C3C3C),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF3C3C3C)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF3C3C3C),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFBBEFF8),
            foregroundColor: const Color(0xFF3C3C3C),
          ),
        ),
      ),
      home: const AdminInterface(),
    );
  }
}

class AdminInterface extends StatefulWidget {
  const AdminInterface({Key? key}) : super(key: key);

  @override
  _AdminInterfaceState createState() => _AdminInterfaceState();
}

class _AdminInterfaceState extends State<AdminInterface> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _presentList = [];
  bool _isLoading = true;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPresentData();
  }

  void _fetchPresentData() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('present')
        .where('present_status', isEqualTo: 'pending')
        .get();
    setState(() {
      _presentList = querySnapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
      _pendingCount = _presentList.length;
      _isLoading = false;
    });
  }

  void _showComparisonDialog(Map<String, dynamic> a, Map<String, dynamic> b) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('これは同じデータですか？'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildComparisonRow('名前', a['present_name'], b['present_name']),
              _buildComparisonRow(
                  'ブランド', a['present_brand'], b['present_brand']),
              _buildComparisonRow(
                  '会社', a['present_company'], b['present_company']),
              _buildComparisonRow(
                  'ジャンル', a['present_genre'], b['present_genre']),
              _buildComparisonRow('価格', a['present_price'], b['present_price']),
              _buildImageComparisonRow(
                  '画像', a['present_imageurl'], b['present_imageurl']),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showMergeScreen(a, b);
            },
            child: const Text('はい、統合する'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditScreen(a);
            },
            child: const Text('いいえ、統合しない'),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, dynamic valueA, dynamic valueB) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Text(valueA?.toString() ?? 'N/A'),
          ),
          Expanded(
            flex: 3,
            child: Text(valueB?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageComparisonRow(String label, String? urlA, String? urlB) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 3,
            child: Image.network(
              urlA ?? '',
              height: 100,
              errorBuilder: (context, error, stackTrace) =>
                  const Text('画像はありません'),
            ),
          ),
          Expanded(
            flex: 3,
            child: Image.network(
              urlB ?? '',
              height: 100,
              errorBuilder: (context, error, stackTrace) =>
                  const Text('画像はありません'),
            ),
          ),
        ],
      ),
    );
  }

  void _showMergeScreen(Map<String, dynamic> a, Map<String, dynamic> b) {
    Map<String, dynamic> merged = {};
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データを統合'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              'present_name',
              'present_brand',
              'present_company',
              'present_genre',
              'present_price',
              'present_imageurl',
            ].map((field) {
              return ListTile(
                title: Text(field),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          merged[field] = a[field];
                        });
                      },
                      child: Text('A: ${a[field]}',
                          style: TextStyle(
                              color: merged[field] == a[field]
                                  ? Colors.blue
                                  : Colors.black)),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          merged[field] = b[field];
                        });
                      },
                      child: Text('B: ${b[field]}',
                          style: TextStyle(
                              color: merged[field] == b[field]
                                  ? Colors.blue
                                  : Colors.black)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              merged['id'] = a['id'];
              _showEditScreen(merged);
            },
            child: const Text('統合完了'),
          ),
        ],
      ),
    );
  }

  void _showEditScreen(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditScreen(item: item),
      ),
    ).then((_) {
      _fetchPresentData();
    });
  }

  bool _isSimilar(Map<String, dynamic> a, Map<String, dynamic> b) {
    String normalize(String? s) {
      if (s == null) return '';
      return s
          .toLowerCase()
          .replaceAll(RegExp(r'[・株式会社合同会社]'), '')
          .replaceAll(RegExp(r'[ぁ-んァ-ン]'), '')
          .replaceAll(RegExp(r'\s'), '');
    }

    return normalize(a['present_name']) == normalize(b['present_name']) &&
        normalize(a['present_brand']) == normalize(b['present_brand']) &&
        normalize(a['present_company']) == normalize(b['present_company']) &&
        normalize(a['present_genre']) == normalize(b['present_genre']);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理者インターフェース'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '未承認のデータ　あと$_pendingCount件',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _presentList.isEmpty
                ? const Center(child: Text('全てのデータがapprovedです'))
                : ListView.builder(
                    itemCount: _presentList.length,
                    itemBuilder: (context, index) {
                      final currentItem = _presentList[index];
                      final similarItems = _presentList
                          .where((item) =>
                              item != currentItem &&
                              _isSimilar(item, currentItem))
                          .toList();

                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(currentItem['present_name'] ?? ''),
                          subtitle: Text(currentItem['present_brand'] ?? ''),
                          onTap: () {
                            if (similarItems.isNotEmpty) {
                              _showComparisonDialog(
                                  currentItem, similarItems.first);
                            } else {
                              _showEditScreen(currentItem);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class EditScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const EditScreen({Key? key, required this.item}) : super(key: key);

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, dynamic> _editedItem;

  @override
  void initState() {
    super.initState();
    _editedItem = Map.from(widget.item);
  }

  String _toHalfWidth(String input) {
    return input.replaceAllMapped(
      RegExp(r'[！-～]'),
      (Match match) =>
          String.fromCharCode(match.group(0)!.codeUnitAt(0) - 0xFEE0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('データ編集'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ...[
                'present_name',
                'present_brand',
                'present_company',
                'present_genre',
                'present_price',
              ].map((field) {
                return TextFormField(
                  initialValue: _editedItem[field]?.toString() ?? '',
                  decoration: InputDecoration(labelText: field),
                  onChanged: (value) {
                    setState(() {
                      _editedItem[field] = _toHalfWidth(value);
                    });
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
              Image.network(
                _editedItem['present_imageurl'] ?? '',
                errorBuilder: (context, error, stackTrace) {
                  return const Text('画像がありません');
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _registerItem,
                child: const Text('登録'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _registerItem() async {
    String itemId = _generateItemId();
    Map<String, dynamic> itemData = {
      'item_id': itemId,
      'present_name': _editedItem['present_name'],
      'present_brand': _editedItem['present_brand'],
      'present_company': _editedItem['present_company'],
      'present_genre': _editedItem['present_genre'],
      'present_price': _editedItem['present_price'],
      'present_imageurl': _editedItem['present_imageurl'],
    };

    try {
      await _firestore.collection('item').doc(itemId).set(itemData);
      await _firestore.collection('present').doc(_editedItem['id']).update({
        'present_status': 'approved',
        'item_id': itemId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('アイテムが登録されました')),
      );
      Navigator.pop(context);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('エラーが発生しました')),
      );
    }
  }

  String _generateItemId() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final randomStr =
        List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    return '$dateStr$randomStr';
  }
}
