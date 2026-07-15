import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:admin_app/main.dart';

/// alamode_app(memo.dart)のデザインに合わせた共通ウィジェット群。
class CommonWidgets {
  static InputDecoration buildInputDecoration(
    String labelText, {
    Widget? suffixIcon,
    BuildContext? context,
  }) {
    final focusColor = context != null ? Theme.of(context).primaryColor : AppColors.primaryColor;
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: AppColors.blackLight,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.inputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.inputBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: focusColor, width: 2),
      ),
      filled: true,
      fillColor: AppColors.cardBackground,
      suffixIcon: suffixIcon,
    );
  }

  static Widget buildGenreSelector({
    required BuildContext context,
    required Set<String> selectedGenres,
    required Function(Set<String>) onSelectionChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'カテゴリー',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.blackLight),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: kItemGenres.map((genre) {
            final isSelected = selectedGenres.contains(genre);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  final newSelection = Set<String>.from(selectedGenres);
                  if (isSelected) {
                    newSelection.remove(genre);
                  } else {
                    newSelection.add(genre);
                  }
                  onSelectionChanged(newSelection);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Theme.of(context).primaryColor : AppColors.greyDark,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    genre,
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).primaryColor : AppColors.blackLight,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 3状態(unknown/yes/no)の条件チップ。item側のカラムはboolean(null許容)を想定。
  static const Map<String, Map<String, String>> conditionLabels = {
    '個包装': {'unknown': '個包装', 'yes': '個包装あり', 'no': '個包装なし'},
    '常温': {'unknown': '常温', 'yes': '常温保存', 'no': '要冷蔵・冷凍'},
    'オンライン購入': {'unknown': 'オンライン購入', 'yes': 'オンライン購入可', 'no': 'オンライン購入不可'},
  };

  static String stateFromBool(bool? value) {
    if (value == null) return 'unknown';
    return value ? 'yes' : 'no';
  }

  static bool? boolFromState(String state) {
    if (state == 'yes') return true;
    if (state == 'no') return false;
    return null;
  }

  static Widget buildConditionChip(
    BuildContext context,
    String key,
    String state, {
    VoidCallback? onTap,
  }) {
    final label = conditionLabels[key]?[state] ?? key;
    final primary = Theme.of(context).primaryColor;
    Color borderColor;
    Color bgColor;
    Color textColor;
    bool showIcon;
    bool isDashed = false;

    switch (state) {
      case 'yes':
        borderColor = primary;
        bgColor = Colors.white;
        textColor = AppColors.blackDark;
        showIcon = true;
        break;
      case 'no':
        borderColor = AppColors.greyDark;
        bgColor = AppColors.greyLight;
        textColor = AppColors.blackLight;
        showIcon = false;
        break;
      default:
        borderColor = AppColors.greyDark;
        bgColor = Colors.transparent;
        textColor = AppColors.blackLight;
        showIcon = false;
        isDashed = true;
    }

    final chipContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 17, child: showIcon ? Icon(Icons.check, size: 13, color: primary) : null),
            Text(label, style: TextStyle(fontSize: 13, color: textColor)),
          ],
        ),
      ),
    );

    final chip = Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: isDashed ? null : Border.all(color: borderColor, width: 1),
          ),
          child: chipContent,
        ),
        if (isDashed)
          Positioned.fill(
            child: CustomPaint(painter: _DashedBorderPainter(color: borderColor, radius: 20)),
          ),
      ],
    );

    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }

  static Widget buildOtherConditionSelector({
    required BuildContext context,
    required bool? individualWrapping,
    required bool? roomTemperature,
    required bool? online,
    required Function(bool? individualWrapping, bool? roomTemperature, bool? online) onChanged,
  }) {
    String cycle(String state) => state == 'unknown' ? 'yes' : (state == 'yes' ? 'no' : 'unknown');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'その他',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.blackLight),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: buildConditionChip(context, '個包装', stateFromBool(individualWrapping), onTap: () {
                final next = cycle(stateFromBool(individualWrapping));
                onChanged(boolFromState(next), roomTemperature, online);
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildConditionChip(context, '常温', stateFromBool(roomTemperature), onTap: () {
                final next = cycle(stateFromBool(roomTemperature));
                onChanged(individualWrapping, boolFromState(next), online);
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildConditionChip(context, 'オンライン購入', stateFromBool(online), onTap: () {
                final next = cycle(stateFromBool(online));
                onChanged(individualWrapping, roomTemperature, boolFromState(next));
              }),
            ),
          ],
        ),
      ],
    );
  }

  static String formatCurrency(dynamic value) {
    if (value == null) return '';
    return NumberFormat('#,###').format(value);
  }

  /// itemの入力項目のうち、埋まっている割合(0〜100)。
  /// 画像はimageurl1/2/3のうち1つでもあれば満たしているとみなす。
  static int itemCompletionPercent(Map<String, dynamic> item) {
    final checks = <bool>[
      (item['item_name'] as String?)?.trim().isNotEmpty == true,
      item['brand_id'] != null,
      (item['item_category'] as String?)?.trim().isNotEmpty == true,
      (item['item_price'] as num?) != null && (item['item_price'] as num) > 0,
      item['item_expirydate'] != null,
      item['item_individualwrapping'] != null,
      item['item_roomtemperature'] != null,
      item['item_online'] != null,
      (item['item_imageurl1'] as String?)?.trim().isNotEmpty == true ||
          (item['item_imageurl2'] as String?)?.trim().isNotEmpty == true ||
          (item['item_imageurl3'] as String?)?.trim().isNotEmpty == true,
      (item['item_url'] as String?)?.trim().isNotEmpty == true,
      (item['item_description'] as String?)?.trim().isNotEmpty == true,
    ];
    final filled = checks.where((c) => c).length;
    return (filled / checks.length * 100).round();
  }

  /// brandの入力項目のうち、埋まっている割合(0〜100)。
  static int brandCompletionPercent(Map<String, dynamic> brand) {
    final checks = <bool>[
      (brand['brand_name'] as String?)?.trim().isNotEmpty == true,
      (brand['brand_company'] as String?)?.trim().isNotEmpty == true,
      (brand['brand_url'] as String?)?.trim().isNotEmpty == true,
    ];
    final filled = checks.where((c) => c).length;
    return (filled / checks.length * 100).round();
  }

  static Widget buildCompletionBadge(int percent) {
    final isComplete = percent >= 100;
    final color = isComplete ? const Color(0xFF2E9E5B) : AppColors.errorColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// URLを入力するTextFormField。値が入っている間、開いて確認できるボタンを表示する。
class UrlInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;

  const UrlInputField({super.key, required this.controller, required this.label});

  @override
  State<UrlInputField> createState() => _UrlInputFieldState();
}

class _UrlInputFieldState extends State<UrlInputField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _open() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    final uri = Uri.tryParse(text);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.controller.text.trim().isNotEmpty;
    return TextFormField(
      controller: widget.controller,
      decoration: CommonWidgets.buildInputDecoration(
        widget.label,
        context: context,
        suffixIcon: hasValue
            ? IconButton(
                icon: const Icon(Icons.open_in_new),
                tooltip: '開いて確認',
                onPressed: _open,
              )
            : null,
      ),
    );
  }
}

const List<String> kItemGenres = ['クッキー', 'ショコラ', '和菓子', '焼き菓子', 'ゼリー・プリン', 'その他'];

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final int selectionIndex = newValue.text.length - newValue.selection.extentOffset;
    final parts = newValue.text.replaceAll(',', '');
    final formatter = NumberFormat('#,###', 'en_US');
    final parsed = int.tryParse(parts);
    final formatted = parsed != null ? formatter.format(parsed) : parts;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length - selectionIndex),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dashLen = 4.0;
    const gapLen = 3.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + dashLen), paint);
        dist += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
