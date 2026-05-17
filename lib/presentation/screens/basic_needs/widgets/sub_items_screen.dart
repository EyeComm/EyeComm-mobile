import 'package:flutter/material.dart';
import '../../../core/language_service.dart';
import '../../../core/voice_service.dart';
import '../../../core/eye_utils.dart';
import '../../../shared/base_grid_page.dart'; // تأكدي من مسار الـ shared

class SubItemsScreen extends StatelessWidget {
  final String titleAr;
  final String titleEn;
  final List<Map<String, dynamic>> options;

  const SubItemsScreen({
    super.key,
    required this.titleAr,
    required this.titleEn,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';
    final List<Map<String, dynamic>> items = [
      {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back', 'iconAsset': 'assets/icons/back.png', 'color': const Color(0xFF455A64), 'is_nav': false, 'eye_name': eyeName('closed')},
      ...options,
    ];

    return BaseGridPage(
      title: ar ? titleAr : titleEn,
      color: const Color(0xFF0288D1),
      items: items,
      onAction: (eye, ctx) async {
        if (eye == 'closed') { Navigator.pop(ctx); return; }

        final selectedItem = items.firstWhere((item) => item['eye'] == eye, orElse: () => {});
        if (selectedItem.isNotEmpty) {
          final String itemName = selectedItem['text'].toString().trim();
          VoiceService.speak(ar ? 'أنا أريد $itemName' : 'I want $itemName');

          Future.delayed(const Duration(seconds: 2), () {
            if (ctx.mounted) Navigator.pop(ctx);
          });
        }
      },
    );
  }
}