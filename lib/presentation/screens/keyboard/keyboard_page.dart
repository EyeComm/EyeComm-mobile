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
  int _phase = 0;       // 0 = choose group, 1 = choose letter
  int _groupIdx = 0;
  int _pageOffset = 0;  // 0 = المجموعات 1-3، 3 = المجموعات 4-6، وهكذا

  bool get _ar => AppLanguage.current == 'ar';

  // ── مجموعات الحروف العربية ────────────────────────────────────────────────
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

  // ── English letter groups ──────────────────────────────────────────────────
  static const List<List<String>> _enGroups = [
    ['A', 'B', 'C', 'D'],
    ['E', 'F', 'G', 'H'],
    ['I', 'J', 'K', 'L'],
    ['M', 'N', 'O', 'P'],
    ['Q', 'R', 'S', 'T'],
    ['U', 'V', 'W', 'X'],
    ['Y', 'Z', ' ', '.'],
  ];

  List<List<String>> get _groups => _ar ? _arGroups : _enGroups;

  static const _eyeOrder = ['left', 'right', 'up', 'down'];

  List<Map<String, dynamic>> _groupItems() {
    final grps = _groups;
    final List<Map<String, dynamic>> result = [];

    for (int i = 0; i < 3; i++) {
      final actualIdx = _pageOffset + i;
      if (actualIdx < grps.length) {
        result.add({
          'eye': _eyeOrder[i],
          'text': grps[actualIdx].join(' '),
          'color': _groupColor(actualIdx),
          'eye_name': eyeName(_eyeOrder[i]),
          'type': 'group',
          'index': actualIdx,
        });
      } else {
        result.add({
          'eye': _eyeOrder[i],
          'text': '—',
          'color': Colors.grey.shade400,
          'eye_name': eyeName(_eyeOrder[i]),
          'type': 'empty',
        });
      }
    }

    if (_pageOffset == 0 && grps.length > 3) {
      result.add({
        'eye': 'down',
        'text': _ar ? 'التالي ➡️' : 'Next ➡️',
        'color': const Color(0xFFFF8F00),
        'eye_name': eyeName('down'),
        'type': 'next_page',
      });
    } else {
      result.add({
        'eye': 'down',
        'text': _ar ? '⬅️ السابق' : '⬅️ Previous',
        'color': const Color(0xFFFF8F00),
        'eye_name': eyeName('down'),
        'type': 'prev_page',
      });
    }

    // زر النطق والخروج المدمج في القائمة الرئيسية (عن طريق غلق العين)
    result.add({
      'eye': 'closed',
      'text': _ar ? '🗣️ نطق وخروج' : '🗣️ Speak & Exit',
      'color': const Color(0xFF2B8EE8),
      'eye_name': eyeName('closed'),
      'type': 'speak_and_exit',
    });

    return result;
  }
  List<Map<String, dynamic>> _letterItems() {
    final letters = _groups[_groupIdx];
    final List<Map<String, dynamic>> result = [];

    for (int i = 0; i < 4 && i < letters.length; i++) {
      result.add({
        'eye': _eyeOrder[i],
        'text': letters[i] == ' ' ? (_ar ? 'مسافة ␣' : 'Space ␣') : letters[i],
        'color': _groupColor(_groupIdx),
        'eye_name': eyeName(_eyeOrder[i]),
        'type': 'letter',
        'letter': letters[i],
      });
    }

    while (result.length < 4) {
      result.add({
        'eye': _eyeOrder[result.length],
        'text': '—',
        'color': Colors.grey.shade400,
        'eye_name': eyeName(_eyeOrder[result.length]),
        'type': 'empty',
      });
    }

    result.add({
      'eye': 'closed',
      'text': _ar ? '🔙 إلغاء ورجوع' : '🔙 Cancel & Back',
      'color': Colors.blueGrey,
      'eye_name': eyeName('closed'),
      'type': 'back_to_groups',
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
    if (mounted) {
      Navigator.pop(context);
    }
  }
  void _handleAction(String eye) async {
    if (_phase == 0) {
      final currentItems = _groupItems();
      final target = currentItems.firstWhere((element) => element['eye'] == eye, orElse: () => {});
      if (target.isEmpty) return;

      switch (target['type']) {
        case 'group':
          setState(() {
            _groupIdx = target['index'] as int;
            _phase = 1;
          });
          break;
        case 'next_page':
          setState(() => _pageOffset = 3);
          break;
        case 'prev_page':
          setState(() => _pageOffset = 0);
          break;
        case 'speak_and_exit':
          await _speakThenExit();
          break;
      }
    } else {
      if (eye == 'closed') {
        setState(() => _phase = 0);
        return;
      }

      final currentItems = _letterItems();
      final target = currentItems.firstWhere((element) => element['eye'] == eye, orElse: () => {});
      if (target.isEmpty) return;

      if (target['type'] == 'speak_and_exit') {
        await _speakThenExit();
        return;
      }

      if (target['type'] == 'empty') return;

      final selectedLetter = target['letter'].toString();
      setState(() {
        _composed += selectedLetter;
        _phase = 0;
        _pageOffset = 0;
      });

      if (selectedLetter == ' ' || selectedLetter == '.') {
        if (_composed.trim().isNotEmpty) {
          VoiceService.speak(_composed);
        }
      } else {
        VoiceService.speak(selectedLetter);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentItems = _phase == 0 ? _groupItems() : _letterItems();

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
                    : (_ar ? 'خطوة 2: انظر لتأكيد الحرف أو اختر نطق وخروج للإنهاء 🗣️' : 'Step 2: Confirm letter or select Speak & Exit 🗣️'),
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
                return DeviceSwitchCard(
                  iconAsset: _getKeyboardIcon(item['type'].toString()),
                  label: item['text'].toString(),
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

  String _getKeyboardIcon(String type) {
    switch (type) {
      case 'next_page':
        return 'assets/icons/next.png';
      case 'prev_page':
        return 'assets/icons/back.png';
      case 'back_to_groups':
        return 'assets/icons/back.png';
      case 'speak_and_exit':
        return 'assets/icons/volume.png';
      default:
        return 'assets/icons/abc.png';
    }
  }
}