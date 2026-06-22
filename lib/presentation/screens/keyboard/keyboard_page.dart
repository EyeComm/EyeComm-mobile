import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
 
import '../../core/language_service.dart';
import '../../core/voice_service.dart';
import '../../core/eye_utils.dart';
import '../../core/app_theme.dart';
import '../../shared/base_grid_page.dart';
import '../../shared/device_switch_card.dart';
 
class KeyboardPage extends StatefulWidget {
  const KeyboardPage({super.key});
 
  @override
  State<KeyboardPage> createState() => _KeyboardPageState();
}
 
class _KeyboardPageState extends State<KeyboardPage> {
  String _composed = '';
  int _phase = 0;      // 0=مجموعات, 1=حروف, 2=أدوات
  int _groupIdx = 0;
  int _pageOffset = 0;
 
  bool _isProcessingAction = false;
 
  bool get _ar => AppLanguage.current == 'ar';
 
  // ─── مجموعات الحروف العربية ─────────────────────────────────────────────────
  static const List<List<String>> _arGroups = [
    ['ا', 'ب', 'ت', 'ث'],
    ['ج', 'ح', 'خ', 'د'],
    ['ذ', 'ر', 'ز', 'س'],
    ['ش', 'ص', 'ض', 'ط'],
    ['ظ', 'ع', 'غ', 'ف'],
    ['ق', 'ك', 'ل', 'م'],
    ['ن', 'ه', 'و', 'ي'],
    [' ', '.', '؟', '،'],
  ];
 
  // ─── مجموعات الحروف الإنجليزية ──────────────────────────────────────────────
  static const List<List<String>> _enGroups = [
    ['A', 'B', 'C', 'D'],
    ['E', 'F', 'G', 'H'],
    ['I', 'J', 'K', 'L'],
    ['M', 'N', 'O', 'P'],
    ['Q', 'R', 'S', 'T'],
    ['U', 'V', 'W', 'X'],
    ['Y', 'Z', ' ', '.'],
  ];
 
  // ─── خريطة صور الحروف ────────────────────────────────────────────────────────
  // ✅ المسارات كاملة من assets/letters/
  static const Map<String, String> _letterImages = {
    // إنجليزي
    'A': 'assets/letters/A.png', 'B': 'assets/letters/B.png',
    'C': 'assets/letters/C.png', 'D': 'assets/letters/D.png',
    'E': 'assets/letters/E.png', 'F': 'assets/letters/F.png',
    'G': 'assets/letters/G.png', 'H': 'assets/letters/H.png',
    'I': 'assets/letters/I.png', 'J': 'assets/letters/J.png',
    'K': 'assets/letters/K.png', 'L': 'assets/letters/L.png',
    'M': 'assets/letters/M.png', 'N': 'assets/letters/N.png',
    'O': 'assets/letters/O.png', 'P': 'assets/letters/P.png',
    'Q': 'assets/letters/Q.png', 'R': 'assets/letters/R.png',
    'S': 'assets/letters/S.png', 'T': 'assets/letters/T.png',
    'U': 'assets/letters/U.png', 'V': 'assets/letters/V.png',
    'W': 'assets/letters/W.png', 'X': 'assets/letters/X.png',
    'Y': 'assets/letters/Y.png', 'Z': 'assets/letters/Z.png',
    // عربي
    'ا': 'assets/letters/ا.png', 'ب': 'assets/letters/ب.png',
    'ت': 'assets/letters/ت.png', 'ث': 'assets/letters/ث.png',
    'ج': 'assets/letters/ج.png', 'ح': 'assets/letters/ح.png',
    'خ': 'assets/letters/خ.png', 'د': 'assets/letters/د.png',
    'ذ': 'assets/letters/ذ.png', 'ر': 'assets/letters/ر.png',
    'ز': 'assets/letters/ز.png', 'س': 'assets/letters/س.png',
    'ش': 'assets/letters/ش.png', 'ص': 'assets/letters/ص.png',
    'ض': 'assets/letters/ض.png', 'ط': 'assets/letters/ط.png',
    'ظ': 'assets/letters/ظ.png', 'ع': 'assets/letters/ع.png',
    'غ': 'assets/letters/غ.png', 'ف': 'assets/letters/ف.png',
    'ق': 'assets/letters/ق.png', 'ك': 'assets/letters/ك.png',
    'ل': 'assets/letters/ل.png', 'م': 'assets/letters/م.png',
    'ن': 'assets/letters/ن.png', 'ه': 'assets/letters/ه.png',
    'و': 'assets/letters/و.png', 'ي': 'assets/letters/ي.png',
    // رموز
    ' ': 'assets/letters/space.png',
    '.': 'assets/letters/dot.png',
    '؟': 'assets/letters/q_ar.png',
    '،': 'assets/letters/comma_ar.png',
  };
 
  // ─── أيقونات المجموعات ───────────────────────────────────────────────────────
  // ✅ المسار الكامل من assets/
  static const List<String> _enGroupIcons = [
    'assets/img_1.png', 'assets/img.png', 'assets/IJKL.png',
    'assets/MNOP.png',  'assets/QRST.png','assets/UVWX.png',
    'assets/YZ.png',
  ];
 
  static const List<String> _arGroupIcons = [
    'assets/AR_GROUP1.png', 'assets/AR_GROUP2.png', 'assets/AR_GROUP3.png',
    'assets/AR_GROUP4.png', 'assets/AR_GROUP5.png', 'assets/AR_GROUP6.png',
    'assets/AR_GROUP7.png', 'assets/AR_PUNCT.png',
  ];
 
  // ─── Getters ─────────────────────────────────────────────────────────────────
  List<List<String>> get _groups => _ar ? _arGroups : _enGroups;
  List<String> get _groupIcons => _ar ? _arGroupIcons : _enGroupIcons;
 
  String _getLetterImage(String letter) =>
      _letterImages[letter] ?? 'assets/icons/abc.png';
 
  Color _groupColor(int i) {
    const cols = [
      Color(0xFF1E88E5), Color(0xFF43A047), Color(0xFFE53935),
      Color(0xFF8E24AA), Color(0xFFFF8F00), Color(0xFF00897B),
      Color(0xFF6D4C41), Color(0xFF0097A7),
    ];
    return cols[i % cols.length];
  }
 
  // ─── بناء عناصر المجموعات ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _groupItems() {
    final grps = _groups;
    final icons = _groupIcons;
    final List<Map<String, dynamic>> result = [];

    if (_pageOffset == 0) {
      if (grps.length > 0) result.add({'eye': 'left', 'text': grps[0].join(' '), 'color': _groupColor(0), 'eye_name': eyeName('left'), 'type': 'group', 'index': 0, 'iconAsset': icons[0]});
      if (grps.length > 1) result.add({'eye': 'right', 'text': grps[1].join(' '), 'color': _groupColor(1), 'eye_name': eyeName('right'), 'type': 'group', 'index': 1, 'iconAsset': icons[1]});
      if (grps.length > 2) result.add({'eye': 'up', 'text': grps[2].join(' '), 'color': _groupColor(2), 'eye_name': eyeName('up'), 'type': 'group', 'index': 2, 'iconAsset': icons[2]});
      result.add({'eye': 'down', 'text': _ar ? 'التالي ➡️' : 'Next ➡️', 'color': const Color(0xFFFF8F00), 'eye_name': eyeName('down'), 'type': 'next_page', 'iconAsset': 'icons/next.png'});
    }
    else if (_pageOffset == 3) {
      if (grps.length > 3) result.add({'eye': 'left', 'text': grps[3].join(' '), 'color': _groupColor(3), 'eye_name': eyeName('left'), 'type': 'group', 'index': 3, 'iconAsset': icons[3]});
      if (grps.length > 4) result.add({'eye': 'right', 'text': grps[4].join(' '), 'color': _groupColor(4), 'eye_name': eyeName('right'), 'type': 'group', 'index': 4, 'iconAsset': icons[4]});
      result.add({'eye': 'up', 'text': _ar ? '⬅️ السابق' : '⬅️ Previous', 'color': const Color(0xFFFF8F00), 'eye_name': eyeName('up'), 'type': 'prev_page', 'iconAsset': 'icons/back.png'});
      result.add({'eye': 'down', 'text': _ar ? 'التالي ➡️' : 'Next ➡️', 'color': const Color(0xFFFF8F00), 'eye_name': eyeName('down'), 'type': 'next_page', 'iconAsset': 'icons/next.png'});
    }
    else if (_pageOffset == 5) {
      if (grps.length > 5) result.add({'eye': 'left', 'text': grps[5].join(' '), 'color': _groupColor(5), 'eye_name': eyeName('left'), 'type': 'group', 'index': 5, 'iconAsset': icons[5]});
      if (grps.length > 6) result.add({'eye': 'right', 'text': grps[6].join(' '), 'color': _groupColor(6), 'eye_name': eyeName('right'), 'type': 'group', 'index': 6, 'iconAsset': icons[6]});
      if (_ar && grps.length > 7) {
        result.add({'eye': 'up', 'text': _ar ?"🛠️ أدوات الكتابة":'🛠️ Text Tools', 'color': const Color(0xFF9C27B0), 'eye_name': eyeName('up'), 'type': 'open_tools', 'iconAsset': 'icons/settings.png'});

      } else {
        result.add({'eye': 'up', 'text': grps[7].join(' '), 'color': _groupColor(7), 'eye_name': eyeName('up'), 'type': 'group', 'index': 7, 'iconAsset': icons[7]});
      }
      result.add({'eye': 'down', 'text': _ar ? '⬅️ السابق' : '⬅️ Previous', 'color': const Color(0xFFFF8F00), 'eye_name': eyeName('down'), 'type': 'prev_page', 'iconAsset': 'icons/back.png'});
    }

    result.add({'eye': 'closed', 'text': _ar ? '🗣️ نطق وخروج' : '🗣️ Speak & Exit', 'color': const Color(0xFF2B8EE8), 'eye_name': eyeName('closed'), 'type': 'speak_and_exit', 'iconAsset': 'icons/volume.png'});
    return result;
  }


  Map<String, dynamic> _groupCard(
      String eye, List<String> letters, String icon, int idx) {
    return {
      'eye': eye,
      'text': letters.where((l) => l.trim().isNotEmpty).take(4).join('  '),
      'color': _groupColor(idx),
      'eye_name': eyeName(eye),
      'type': 'group',
      'index': idx,
      'iconAsset': icon,
    };
  }
 
  Map<String, dynamic> _navCard(
      String eye, String text, String icon, String type) {
    return {
      'eye': eye,
      'text': text,
      'color': const Color(0xFFFF8F00),
      'eye_name': eyeName(eye),
      'type': type,
      'iconAsset': icon,
    };
  }
 
  // ─── بناء عناصر الأدوات ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> _toolsItems() {
    return [
      {
        'eye': 'left',
        'text': _ar ? 'مسح حرف' : 'Delete',
        'color': Colors.orange.shade800,
        'eye_name': eyeName('left'),
        'type': 'tool_backspace',
        'iconAsset': 'assets/icons/backspace.png',
      },
      {
        'eye': 'right',
        'text': _ar ? 'مسح الكل' : 'Clear All',
        'color': Colors.red.shade700,
        'eye_name': eyeName('right'),
        'type': 'tool_clear_all',
        'iconAsset': 'assets/icons/delete.png',
      },
      {
        'eye': 'up',
        'text': _ar ? 'مسافة' : 'Space',
        'color': Colors.teal.shade700,
        'eye_name': eyeName('up'),
        'type': 'tool_space',
        'iconAsset': 'assets/icons/abc.png',
      },
      {
        'eye': 'down',
        'text': _ar ? '🔊 نطق' : '🔊 Speak',
        'color': Colors.indigo.shade700,
        'eye_name': eyeName('down'),
        'type': 'tool_just_speak',
        'iconAsset': 'assets/icons/volume.png',
      },
      {
        'eye': 'closed',
        'text': _ar ? '↩ رجوع للمجموعات' : '↩ Back',
        'color': Colors.blueGrey,
        'eye_name': eyeName('closed'),
        'type': 'back_to_groups_phase',
        'iconAsset': 'assets/icons/back.png',
      },
    ];
  }
 
  // ─── بناء عناصر الحروف ───────────────────────────────────────────────────────
  List<Map<String, dynamic>> _letterItems() {
    final letters = _groups[_groupIdx];
    final List<Map<String, dynamic>> result = [];
    const eyeOrder = ['left', 'right', 'up', 'down'];
 
    for (int i = 0; i < 4 && i < letters.length; i++) {
      final String letter = letters[i];
      result.add({
        'eye': eyeOrder[i],
        'text': letter == ' '
            ? (_ar ? 'مسافة ⎵' : 'Space ⎵')
            : letter,
        'color': _groupColor(_groupIdx),
        'eye_name': eyeName(eyeOrder[i]),
        'type': 'letter',
        'letter': letter,
        'iconAsset': _getLetterImage(letter),
      });
    }
 
    // تعبئة لو أقل من 4
    while (result.length < 4) {
      final emptyEye = eyeOrder[result.length];
      result.add({
        'eye': emptyEye,
        'text': '—',
        'color': Colors.grey.shade400,
        'eye_name': eyeName(emptyEye),
        'type': 'empty',
        'iconAsset': 'assets/icons/abc.png',
      });
    }
 
    result.add({
      'eye': 'closed',
      'text': _ar ? '↩ رجوع للمجموعات' : '↩ Back to Groups',
      'color': Colors.blueGrey,
      'eye_name': eyeName('closed'),
      'type': 'back_to_groups_phase',
      'iconAsset': 'assets/icons/back.png',
    });
 
    return result;
  }
 
  // ─── نطق ثم خروج ─────────────────────────────────────────────────────────────
  Future<void> _speakThenExit() async {
    if (_composed.trim().isNotEmpty) {
      await VoiceService.speak(_composed);
      final int delay = (_composed.length * 350 + 1000).clamp(2000, 7000);
      await Future.delayed(Duration(milliseconds: delay));
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (mounted) Navigator.pop(context);
  }
 
  // ─── معالجة الحدث ────────────────────────────────────────────────────────────
  void _handleAction(String eye) async {
    if (_isProcessingAction) return;
 
    // ─── Phase 0: اختيار مجموعة ─────────────────────────────────────────────
    if (_phase == 0) {
      final items = _groupItems();
      final target =
          items.firstWhere((e) => e['eye'] == eye, orElse: () => {});
      if (target.isEmpty) return;
 
      setState(() => _isProcessingAction = true);
 
      switch (target['type']) {
        case 'group':
          setState(() {
            _groupIdx = target['index'] as int;
            _phase = 1;
          });
          break;
        case 'open_tools':
          setState(() => _phase = 2);
          break;
        case 'next_page':
          setState(() {
            if (_pageOffset == 0) _pageOffset = 3;
            else if (_pageOffset == 3) _pageOffset = 5;
          });
          break;
        case 'prev_page':
          setState(() {
            if (_pageOffset == 5) _pageOffset = 3;
            else if (_pageOffset == 3) _pageOffset = 0;
          });
          break;
        case 'speak_and_exit':
          await _speakThenExit();
          break;
      }
 
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _isProcessingAction = false);
    }
 
    // ─── Phase 1: اختيار حرف ────────────────────────────────────────────────
    else if (_phase == 1) {
      if (eye == 'closed') {
        setState(() {
          _isProcessingAction = true;
          _phase = 0;
        });
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) setState(() => _isProcessingAction = false);
        return;
      }
 
      final items = _letterItems();
      final target =
          items.firstWhere((e) => e['eye'] == eye, orElse: () => {});
      if (target.isEmpty || target['type'] == 'empty') return;
 
      if (target['type'] == 'letter') {
        final letter = target['letter'].toString();
        setState(() {
          _isProcessingAction = true;
          _composed += letter;
        });
 
        if (letter == ' ' || letter == '.') {
          if (_composed.trim().isNotEmpty) VoiceService.speak(_composed);
        } else {
          VoiceService.speak(letter);
        }
 
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) setState(() => _isProcessingAction = false);
      } else if (target['type'] == 'back_to_groups_phase') {
        setState(() {
          _isProcessingAction = true;
          _phase = 0;
        });
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) setState(() => _isProcessingAction = false);
      }
    }
 
    // ─── Phase 2: أدوات النص ────────────────────────────────────────────────
    else if (_phase == 2) {
      final items = _toolsItems();
      final target =
          items.firstWhere((e) => e['eye'] == eye, orElse: () => {});
      if (target.isEmpty) return;
 
      setState(() => _isProcessingAction = true);
 
      switch (target['type']) {
        case 'tool_backspace':
          setState(() {
            if (_composed.isNotEmpty) {
              _composed = _composed.substring(0, _composed.length - 1);
            }
          });
          VoiceService.speak(_ar ? 'مسح' : 'Delete');
          break;
        case 'tool_clear_all':
          setState(() => _composed = '');
          VoiceService.speak(_ar ? 'مسح الكل' : 'Clear');
          break;
        case 'tool_space':
          setState(() => _composed += ' ');
          VoiceService.speak(_ar ? 'مسافة' : 'Space');
          break;
        case 'tool_just_speak':
          if (_composed.isNotEmpty) VoiceService.speak(_composed);
          break;
        case 'back_to_groups_phase':
          setState(() => _phase = 0);
          break;
      }
 
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }
 
  // ─── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final currentItems = _phase == 0
        ? _groupItems()
        : (_phase == 1 ? _letterItems() : _toolsItems());
 
    return Scaffold(
      backgroundColor: kBg1,
      body: SafeArea(
        child: Column(children: [
          // ─── صندوق النص المكتوب ─────────────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            constraints: const BoxConstraints(minHeight: 75),
            decoration: BoxDecoration(
              color: kSurface1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder1),
            ),
            child: Text(
              _composed.isEmpty
                  ? (_ar
                      ? 'ابدأ الكتابة بالعين...'
                      : 'Start typing with eyes...')
                  : _composed,
              style: GoogleFonts.cairo(
                fontSize: 22,
                color: _composed.isEmpty ? Colors.grey : kTextMain1,
                fontWeight: FontWeight.w600,
              ),
              textDirection:
                  _ar ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
 
          // ─── تعليمات الخطوة ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Align(
              alignment:
                  _ar ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                _phase == 0
                    ? (_ar
                        ? 'خطوة 1: اختر مجموعة الحروف أو انطق وأغلق بالرمش'
                        : 'Step 1: Choose letter group or Speak & Exit via blink')
                    : (_phase == 1
                        ? (_ar
                            ? 'خطوة 2: اختر الحرف أو ارجع للمجموعات بالرمش'
                            : 'Step 2: Choose letter or blink to go Back')
                        : (_ar
                            ? 'لوحة أدوات النص المتقدمة'
                            : 'Advanced Text Tools')),
                style: GoogleFonts.cairo(
                  color: const Color(0xFFE82B6A),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
 
          // ─── الشبكة مع الكاميرا ─────────────────────────────────────────
          Expanded(
            child: BaseGridPage(
              title: AppLanguage.t('keyboard'),
              color: const Color(0xFFE82B6A),
              items: currentItems,
              showCameraCard: true,
              cameraCardAspectRatio: 1.0,
              // ✅ كل بطاقة بتستخدم DeviceSwitchCard بشكل صحيح
              itemBuilder:
                  (context, index, item, stable, cd, totalTimer) {
                final String eyeCmd = item['eye'].toString();
                final String cardLabel = item['text'].toString();
                // ✅ المسار الكامل للصورة
                final String iconPath =
                    item['iconAsset']?.toString() ??
                        'assets/icons/abc.png';
 
                return DeviceSwitchCard(
                  iconAsset: iconPath, // ✅ String دائماً
                  isIcon: false,
                  label: cardLabel == '—' ? '' : cardLabel,
                  gestureName: item['eye_name'].toString(),
                  eyeCmd: eyeCmd,
                  activeColor: item['color'] as Color,
                  stable: stable,
                  cd: cd,
                  totalTimer: totalTimer,
                  isOn: null,
                  onTap: () => _handleAction(eyeCmd),
                );
              },
              onAction: (eye, ctx) async {
                _handleAction(eye);
              },
            ),
          ),
        ]),
      ),
    );
  }
}