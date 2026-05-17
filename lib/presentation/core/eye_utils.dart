import 'language_service.dart';

/// Returns the localised name for an eye-gesture key.
String eyeName(String k) {
  final bool ar = AppLanguage.current == 'ar';
  switch (k) {
    case 'closed': return ar ? 'أغمض'  : 'Close Eye';
    case 'left':   return ar ? 'يسار'  : 'Look Left';
    case 'right':  return ar ? 'يمين'  : 'Look Right';
    case 'up':     return ar ? 'أعلى'  : 'Look Up';
    case 'down':   return ar ? 'أسفل'  : 'Look Down';
    default:       return k;
  }
}

/// Maps an eye-gesture key to its directional asset path.
String assetForEye(String cmd) {
  switch (cmd) {
    case 'left':   return 'assets/look-left.png';
    case 'right':  return 'assets/look-right.png';
    case 'up':     return 'assets/look-up.png';
    case 'down':   return 'assets/look-down.png';
    case 'closed': return 'assets/close.png';
    default:       return 'assets/look-right.png';
  }
}

/// Strips emoji code-points from [text], keeping Arabic / Latin / digits.
String cleanForSpeech(String text) => text
    .replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1FAFF}]|[\u{2600}-\u{27BF}]|[\u{1F600}-\u{1F64F}]'
        r'|[\u{1F900}-\u{1F9FF}]|[\u{2700}-\u{27BF}]',
        unicode: true,
      ),
      '',
    )
    .trim();


