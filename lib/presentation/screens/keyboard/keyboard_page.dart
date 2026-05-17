import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/language_service.dart';
import '../../core/voice_service.dart';
import '../../core/eye_utils.dart';
import '../../core/app_theme.dart';
import '../../shared/base_grid_page.dart';

class KeyboardPage extends StatefulWidget {
  const KeyboardPage({super.key});

  @override
  State<KeyboardPage> createState() => _KeyboardPageState();
}

class _KeyboardPageState extends State<KeyboardPage> {
  String _composed = '';
  int _phase = 0;       // 0 = choose group, 1 = choose letter
  int _groupIdx = 0;

  bool get _ar => AppLanguage.current == 'ar';

  // ── Arabic letter groups ───────────────────────────────────────────────────
  static const List<List<String>> _arGroups = [
    ['ا', 'ب', 'ت', 'ث'],
    ['ج', 'ح', 'خ', 'د'],
    ['ذ', 'ر', 'ز', 'س'],
    ['ش', 'ص', 'ض', 'ط'],
    ['ظ', 'ع', 'غ', 'ف'],
    ['ق', 'ك', 'ل', 'م'],
    ['ن', 'ه', 'و', 'ي'],
  ];

  // ── English letter groups ──────────────────────────────────────────────────
  static const List<List<String>> _enGroups = [
    ['A', 'B', 'C', 'D'],
    ['E', 'F', 'G', 'H'],
    ['I', 'J', 'K', 'L'],
    ['M', 'N', 'O', 'P'],
    ['Q', 'R', 'S', 'T'],
    ['U', 'V', 'W', 'X'],
    ['Y', 'Z'],
  ];

  List<List<String>> get _groups => _ar ? _arGroups : _enGroups;

  // ── Eyes map to grid positions ─────────────────────────────────────────────
  // Phase 0: closed=g0,left=g1,right=g2,up=g3 then 'down' pages forward
  // Phase 1: closed=l0,left=l1,right=l2,up=l3
  static const _eyeOrder = ['closed', 'left', 'right', 'up'];

  List<Map<String, dynamic>> _groupItems() {
    final grps = _groups;
    final List<Map<String, dynamic>> result = [];
    for (int i = 0; i < 4 && i < grps.length; i++) {
      result.add({
        'eye':      _eyeOrder[i],
        'text':     grps[i].join(' '),
        'color':    _groupColor(i),
        'eye_name': eyeName(_eyeOrder[i]),
      });
    }
    result.add({
      'eye':      'down',
      'text':     '⏸️ ${AppLanguage.t("back")}',
      'color':    Colors.grey,
      'eye_name': eyeName('down'),
    });
    return result;
  }

  List<Map<String, dynamic>> _letterItems() {
    final letters = _groups[_groupIdx];
    final List<Map<String, dynamic>> result = [];
    for (int i = 0; i < 4 && i < letters.length; i++) {
      result.add({
        'eye':      _eyeOrder[i],
        'text':     letters[i],
        'color':    _groupColor(_groupIdx),
        'eye_name': eyeName(_eyeOrder[i]),
      });
    }
    // Fill remaining slots
    while (result.length < 4) {
      result.add({
        'eye':      _eyeOrder[result.length],
        'text':     '—',
        'color':    Colors.grey.shade400,
        'eye_name': eyeName(_eyeOrder[result.length]),
      });
    }
    result.add({
      'eye':      'down',
      'text':     '⬅️ ${_ar ? "رجوع للمجموعات" : "Back to groups"}',
      'color':    Colors.grey,
      'eye_name': eyeName('down'),
    });
    return result;
  }

  Color _groupColor(int i) {
    const cols = [
      Color(0xFF1E88E5),
      Color(0xFF43A047),
      Color(0xFFE53935),
      Color(0xFF8E24AA),
      Color(0xFFFF8F00),
      Color(0xFF00897B),
      Color(0xFF6D4C41),
    ];
    return cols[i % cols.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg1,
      body: SafeArea(
        child: Column(children: [
          // ── Composed text display ──────────────────────────────────────────
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
                      ? (_ar ? 'ابدأ الكتابة...' : 'Start typing...')
                      : _composed,
                  style: GoogleFonts.cairo(
                      fontSize: 20,
                      color: _composed.isEmpty ? Colors.grey : kTextMain1,
                      fontWeight: FontWeight.w600),
                ),
              ),
              // Action buttons
              IconButton(
                icon: const Icon(Icons.volume_up_rounded),
                color: const Color(0xFF2B8EE8),
                onPressed: () {
                  if (_composed.isNotEmpty) VoiceService.speak(_composed);
                },
              ),
              IconButton(
                icon: const Icon(Icons.backspace_rounded),
                color: Colors.orange,
                onPressed: () {
                  if (_composed.isNotEmpty) {
                    setState(() => _composed =
                        _composed.substring(0, _composed.length - 1));
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded),
                color: Colors.red,
                onPressed: () => setState(() => _composed = ''),
              ),
            ]),
          ),

          // ── Phase label ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: _ar ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                _phase == 0
                    ? AppLanguage.t('kb_select_group')
                    : AppLanguage.t('kb_select_letter'),
                style: GoogleFonts.cairo(
                    color: kTextSub1,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // ── Grid ──────────────────────────────────────────────────────────
          Expanded(
            child: BaseGridPage(
              title: AppLanguage.t('keyboard'),
              color: const Color(0xFFE82B6A),
              items: _phase == 0 ? _groupItems() : _letterItems(),
              onAction: (eye, ctx) async {
                if (_phase == 0) {
                  if (eye == 'down') { Navigator.pop(ctx); return; }
                  final idx = _eyeOrder.indexOf(eye);
                  if (idx < 0 || idx >= _groups.length) return;
                  setState(() { _groupIdx = idx; _phase = 1; });
                } else {
                  if (eye == 'down') { setState(() => _phase = 0); return; }
                  final idx = _eyeOrder.indexOf(eye);
                  final letters = _groups[_groupIdx];
                  if (idx < 0 || idx >= letters.length) return;
                  final letter = letters[idx];
                  setState(() {
                    _composed += letter;
                    _phase = 0;
                  });
                  VoiceService.speak(letter);
                }
              },
            ),
          ),
        ]),
      ),
    );
  }
}
