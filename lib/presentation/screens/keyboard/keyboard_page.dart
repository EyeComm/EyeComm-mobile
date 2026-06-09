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
  int _phase = 0;
  int _groupIdx = 0;
  int _pageOffset = 0;

  bool _isProcessingAction = false;

  bool get _ar => AppLanguage.current == 'ar';

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

  static const List<List<String>> _enGroups = [
    ['A', 'B', 'C', 'D'],
    ['E', 'F', 'G', 'H'],
    ['I', 'J', 'K', 'L'],
    ['M', 'N', 'O', 'P'],
    ['Q', 'R', 'S', 'T'],
    ['U', 'V', 'W', 'X'],
    ['Y', 'Z', ' ', '.'],
  ];

  // ✅ كل المسارات بدون assets/ في البداية
  static const Map<String, String> _letterImages = {
    'A': 'letters/A.png',
    'B': 'letters/B.png',
    'C': 'letters/C.png',
    'D': 'letters/D.png',
    'E': 'letters/E.png',
    'F': 'letters/F.png',
    'G': 'letters/G.png',
    'H': 'letters/H.png',
    'I': 'letters/I.png',
    'J': 'letters/J.png',
    'K': 'letters/K.png',
    'L': 'letters/L.png',
    'M': 'letters/M.png',
    'N': 'letters/N.png',
    'O': 'letters/O.png',
    'P': 'letters/P.png',
    'Q': 'letters/Q.png',
    'R': 'letters/R.png',
    'S': 'letters/S.png',
    'T': 'letters/T.png',
    'U': 'letters/U.png',
    'V': 'letters/V.png',
    'W': 'letters/W.png',
    'X': 'letters/X.png',
    'Y': 'letters/Y.png',
    'Z': 'letters/Z.png',
    'ا': 'letters/ا.png',
    'ب': 'letters/ب.png',
    'ت': 'letters/ت.png',
    'ث': 'letters/ث.png',
    'ج': 'letters/ج.png',
    'ح': 'letters/ح.png',
    'خ': 'letters/خ.png',
    'د': 'letters/د.png',
    'ذ': 'letters/ذ.png',
    'ر': 'letters/ر.png',
    'ز': 'letters/ز.png',
    'س': 'letters/س.png',
    'ش': 'letters/ش.png',
    'ص': 'letters/ص.png',
    'ض': 'letters/ض.png',
    'ط': 'letters/ط.png',
    'ظ': 'letters/ظ.png',
    'ع': 'letters/ع.png',
    'غ': 'letters/غ.png',
    'ف': 'letters/ف.png',
    'ق': 'letters/ق.png',
    'ك': 'letters/ك.png',
    'ل': 'letters/ل.png',
    'م': 'letters/م.png',
    'ن': 'letters/ن.png',
    'ه': 'letters/ه.png',
    'و': 'letters/و.png',
    'ي': 'letters/ي.png',
    ' ': 'letters/space.png',
    '.': 'letters/dot.png',
    '؟': 'letters/q_ar.png',
    '،': 'letters/comma_ar.png',
  };

  String _getLetterImage(String letter) {
    return _letterImages[letter] ?? 'icons/abc.png';
  }

  static const List<String> _enGroupIcons = [
    'img_1.png', 'img.png', 'IJKL.png',
    'MNOP.png', 'QRST.png', 'UVWX.png', 'YZ.png',
  ];

  static const List<String> _arGroupIcons = [
    'AR_GROUP1.png', 'AR_GROUP2.png', 'AR_GROUP3.png',
    'AR_GROUP4.png', 'AR_GROUP5.png', 'AR_GROUP6.png',
    'AR_GROUP7.png', 'AR_PUNCT.png',
  ];

  List<List<String>> get _groups => _ar ? _arGroups : _enGroups;
  List<String> get _groupIcons => _ar ? _arGroupIcons : _enGroupIcons;

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
        result.add({'eye': 'up', 'text': grps[7].join(' '), 'color': _groupColor(7), 'eye_name': eyeName('up'), 'type': 'group', 'index': 7, 'iconAsset': icons[7]});
      } else {
        result.add({
          'eye': 'up',
          'text': '🛠️ Text Tools',
          'color': const Color(0xFF9C27B0),
          'eye_name': eyeName('up'),
          'type': 'open_tools',
          'iconAsset': 'icons/settings.png'
        });
      }

      result.add({'eye': 'down', 'text': _ar ? '⬅️ السابق' : '⬅️ Previous', 'color': const Color(0xFFFF8F00), 'eye_name': eyeName('down'), 'type': 'prev_page', 'iconAsset': 'icons/back.png'});
    }

    result.add({'eye': 'closed', 'text': _ar ? '🗣️ نطق وخروج' : '🗣️ Speak & Exit', 'color': const Color(0xFF2B8EE8), 'eye_name': eyeName('closed'), 'type': 'speak_and_exit', 'iconAsset': 'icons/volume.png'});
    return result;
  }

  List<Map<String, dynamic>> _toolsItems() {
    return [
      {'eye': 'left', 'text': '⌫ Delete Last', 'color': Colors.orange.shade800, 'eye_name': eyeName('left'), 'type': 'tool_backspace', 'iconAsset': 'icons/backspace.png'},
      {'eye': 'right', 'text': '🗑️ Clear All', 'color': Colors.red.shade700, 'eye_name': eyeName('right'), 'type': 'tool_clear_all', 'iconAsset': 'icons/delete.png'},
      {'eye': 'up', 'text': '␣ Quick Space', 'color': Colors.teal.shade700, 'eye_name': eyeName('up'), 'type': 'tool_space', 'iconAsset': 'icons/abc.png'},
      {'eye': 'down', 'text': '🔊 Just Speak', 'color': Colors.indigo.shade700, 'eye_name': eyeName('down'), 'type': 'tool_just_speak', 'iconAsset': 'icons/volume.png'},
      {'eye': 'closed', 'text': '🔙 Back to Groups', 'color': Colors.blueGrey, 'eye_name': eyeName('closed'), 'type': 'back_to_groups_phase', 'iconAsset': 'icons/back.png'},
    ];
  }

  List<Map<String, dynamic>> _letterItems() {
    final letters = _groups[_groupIdx];
    final List<Map<String, dynamic>> result = [];
    const eyeOrder = ['left', 'right', 'up', 'down'];

    for (int i = 0; i < 4 && i < letters.length; i++) {
      final String letter = letters[i];

      // ✅ استخدام _getLetterImage مباشرة
      final String iconPath = _getLetterImage(letter);

      result.add({
        'eye': eyeOrder[i],
        'text': letter == ' ' ? (_ar ? 'مسافة ␣' : 'Space ␣') : letter,
        'color': _groupColor(_groupIdx),
        'eye_name': eyeName(eyeOrder[i]),
        'type': 'letter',
        'letter': letter,
        'iconAsset': iconPath,
      });
    }

    while (result.length < 4) {
      result.add({
        'eye': eyeOrder[result.length],
        'text': '—',
        'color': Colors.grey.shade400,
        'eye_name': eyeName(eyeOrder[result.length]),
        'type': 'empty',
        'iconAsset': 'icons/abc.png',
      });
    }

    result.add({
      'eye': 'closed',
      'text': _ar ? '🔙 رجوع للمجموعات' : '🔙 Back to Groups',
      'color': Colors.blueGrey,
      'eye_name': eyeName('closed'),
      'type': 'back_to_groups_phase',
      'iconAsset': 'icons/back.png',
    });

    return result;
  }

  Color _groupColor(int i) {
    const cols = [
      Color(0xFF1E88E5), Color(0xFF43A047), Color(0xFFE53935),
      Color(0xFF8E24AA), Color(0xFFFF8F00), Color(0xFF00897B),
      Color(0xFF6D4C41), Color(0xFF0097A7),
    ];
    return cols[i % cols.length];
  }

  Future<void> _speakThenExit() async {
    if (_composed.trim().isNotEmpty) {
      await VoiceService.speak(_composed);
      final int calculatedDelay = (_composed.length * 350) + 1000;
      final int finalDelay = calculatedDelay.clamp(2000, 7000);
      await Future.delayed(Duration(milliseconds: finalDelay));
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (mounted) Navigator.pop(context);
  }

  void _handleAction(String eye) async {
    if (_isProcessingAction) return;

    if (_phase == 0) {
      final currentItems = _groupItems();
      final target = currentItems.firstWhere((element) => element['eye'] == eye, orElse: () => {});
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

      final currentItems = _letterItems();
      final target = currentItems.firstWhere((element) => element['eye'] == eye, orElse: () => {});
      if (target.isEmpty || target['type'] == 'empty') return;

      if (target['type'] == 'letter') {
        final selectedLetter = target['letter'].toString();

        setState(() {
          _isProcessingAction = true;
          _composed += selectedLetter;
        });

        if (selectedLetter == ' ' || selectedLetter == '.') {
          if (_composed.trim().isNotEmpty) VoiceService.speak(_composed);
        } else {
          VoiceService.speak(selectedLetter);
        }

        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) setState(() => _isProcessingAction = false);
      }
    }
    else if (_phase == 2) {
      final currentItems = _toolsItems();
      final target = currentItems.firstWhere((element) => element['eye'] == eye, orElse: () => {});
      if (target.isEmpty) return;

      setState(() => _isProcessingAction = true);

      switch (target['type']) {
        case 'tool_backspace':
          setState(() {
            if (_composed.isNotEmpty) _composed = _composed.substring(0, _composed.length - 1);
          });
          VoiceService.speak("Delete");
          break;
        case 'tool_clear_all':
          setState(() => _composed = '');
          VoiceService.speak("Clear");
          break;
        case 'tool_space':
          setState(() => _composed += ' ');
          VoiceService.speak("Space");
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

  @override
  Widget build(BuildContext context) {
    final currentItems = _phase == 0
        ? _groupItems()
        : (_phase == 1 ? _letterItems() : _toolsItems());

    return Scaffold(
      backgroundColor: kBg1,
      body: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: kSurface1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder1),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  _composed.isEmpty
                      ? (_ar ? 'ابدأ الكتابة بالعين...' : 'Start typing with eyes...')
                      : _composed,
                  style: GoogleFonts.cairo(
                      fontSize: 22,
                      color: _composed.isEmpty ? Colors.grey : kTextMain1,
                      fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, size: 28),
                color: const Color(0xFF2B8EE8),
                onPressed: () {
                  if (_composed.isNotEmpty) VoiceService.speak(_composed);
                },
              ),
              IconButton(
                icon: const Icon(Icons.backspace_rounded, size: 26),
                color: Colors.orange,
                onPressed: () {
                  if (_composed.isNotEmpty) {
                    setState(() => _composed = _composed.substring(0, _composed.length - 1));
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, size: 28),
                color: Colors.red,
                onPressed: () => setState(() => _composed = ''),
              ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: _ar ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                _phase == 0
                    ? (_ar ? 'خطوة 1: اختر مجموعة الحروف أو انطق واقفل بالرمش 🔍' : 'Step 1: Choose group or Speak & Exit via blink 🔍')
                    : (_phase == 1
                    ? (_ar ? 'خطوة 2: انظر لتأكيد الحرف أو اختر رجوع للمجموعات 🗣️' : 'Step 2: Confirm letter or select Back to Groups 🗣️')
                    : (_ar ? 'لوحة التحكم بالنص المتقدمة 🛠️' : 'Advanced Text Tools Control Board 🛠️')),
                style: GoogleFonts.cairo(
                    color: const Color(0xFFE82B6A),
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: BaseGridPage(
              title: AppLanguage.t('keyboard'),
              color: const Color(0xFFE82B6A),
              items: currentItems,
              itemBuilder: (context, index, item, stable, cd, totalTimer) {
                final String currentEye = item['eye'].toString();
                final String cardLabel = item['text'].toString();

                final String finalIconPath = item['iconAsset']?.toString() ?? 'icons/abc.png';

                return DeviceSwitchCard(
                  iconAsset: finalIconPath,
                  isIcon: false,
                  label: cardLabel == '—' ? '' : cardLabel,
                  gestureName: item['eye_name'].toString(),
                  eyeCmd: currentEye,
                  activeColor: item['color'] as Color,
                  stable: stable,
                  cd: cd,
                  totalTimer: totalTimer,
                  isOn: null,
                  onTap: () => _handleAction(currentEye),
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