import 'package:eye_comm_project/data/iot_service.dart';
import 'package:eye_comm_project/presentation/core/language_service.dart';
import 'package:eye_comm_project/presentation/core/voice_service.dart';

import '../eye_tracking/eye_tracking_cubit.dart';
import 'smart_home_hall_state.dart';

export 'smart_home_hall_state.dart';

class SmartHomeHallCubit extends EyeTrackingCubit {
  SmartHomeHallCubit() : super(timerSec: 5) {
    emit(const SmartHomeHallState(totalTimer: 5));
  }

  SmartHomeHallState get hallState {
    final s = state;
    if (s is SmartHomeHallState) return s;
    return SmartHomeHallState(
      currentEye       : s.currentEye,
      stableDirection  : s.stableDirection,
      countdownSeconds : s.countdownSeconds,
      totalTimer       : s.totalTimer,
      confirmedGesture : s.confirmedGesture,
    );
  }

  bool get _ar => AppLanguage.current == 'ar';

  // ✅ labelForGesture بترجع null للزرار اللي ليها نطق خاص
  @override
  String? labelForGesture(String gesture) {
    switch (gesture) {
      case 'left':   return null;  // التكييف بينطق من جوه
      case 'right':  return null;  // النور بينطق من جوه
      case 'up':     return null;  // الشاشة بينطق من جوه
      case 'down':   return null;  // الدفاية بينطق من جوه
      case 'closed': return _ar ? 'رجوع' : 'Back';
      default:       return null;
    }
  }

  @override
  EyeTrackingState copyStateWith({
    String?  currentEye,
    String?  stableDirection,
    int?     countdownSeconds,
    int?     totalTimer,
    Object?  confirmedGesture = kKeepGesture,
  }) {
    return hallState.copyWith(
      currentEye       : currentEye,
      stableDirection  : stableDirection,
      countdownSeconds : countdownSeconds,
      totalTimer       : totalTimer,
      confirmedGesture : confirmedGesture,
    );
  }

  @override
  Future<void> onGestureConfirmed(String gesture) async {
    if (DateTime.now().isBefore(_cooldownUntil)) return;
    _cooldownUntil = DateTime.now().add(const Duration(seconds: 2));
    executeCommand(gesture);
  }

  DateTime _cooldownUntil = DateTime.now();

  void executeCommand(String gesture) {
    switch (gesture) {
      case 'closed':
        VoiceService.speak(_ar ? 'رجوع' : 'Back');
        break;
      case 'left':  _toggleAc();     break;
      case 'right': _toggleLight();  break;
      case 'up':    _toggleTv();     break;
      case 'down':  _toggleHeater(); break;
    }
  }

  // ✅ أول ضغطة: بارد - تاني ضغطة: سخن - تالت ضغطة: غلق
  void _toggleAc() {
    final AcMode next = _nextAcMode(hallState.acMode);
    emit(hallState.copyWith(acMode: next));
    VoiceService.speak(_acFeedback(next));
    switch (next) {
      case AcMode.off:  unawaited(IoTService.acOff());  break;
      case AcMode.cold: unawaited(IoTService.acCold()); break;
      case AcMode.hot:  unawaited(IoTService.acHot());  break;
    }
  }

  // ✅ النور: تم فتح / تم غلق
  void _toggleLight() {
    final bool next = !hallState.lightOn;
    emit(hallState.copyWith(lightOn: next));
    VoiceService.speak(
      _ar ? (next ? 'تم فتح النور' : 'تم غلق النور')
          : (next ? 'Light ON'     : 'Light OFF'),
    );
    unawaited(next ? IoTService.light2On() : IoTService.light2Off());
  }

  // ✅ الشاشة: تم فتح / تم غلق
  void _toggleTv() {
    final bool next = !hallState.tvOn;
    emit(hallState.copyWith(tvOn: next));
    VoiceService.speak(
      _ar ? (next ? 'تم فتح الشاشة' : 'تم غلق الشاشة')
          : (next ? 'TV ON'         : 'TV OFF'),
    );
    unawaited(next ? IoTService.tvOn() : IoTService.tvOff());
  }

  // ✅ الدفاية: تم فتح / تم غلق
  void _toggleHeater() {
    final bool next = !hallState.heaterOn;
    emit(hallState.copyWith(heaterOn: next));
    VoiceService.speak(
      _ar ? (next ? 'تم فتح الدفاية' : 'تم غلق الدفاية')
          : (next ? 'Heater ON'      : 'Heater OFF'),
    );
    unawaited(next ? IoTService.heaterOn() : IoTService.heaterOff());
  }

  AcMode _nextAcMode(AcMode current) {
    switch (current) {
      case AcMode.off:  return AcMode.cold;
      case AcMode.cold: return AcMode.hot;
      case AcMode.hot:  return AcMode.off;
    }
  }

  String _acFeedback(AcMode mode) {
    switch (mode) {
      case AcMode.cold: return _ar ? 'تكييف شغال على البارد' : 'AC Cold';
      case AcMode.hot:  return _ar ? 'تكييف شغال على سخن'    : 'AC Hot';
      case AcMode.off:  return _ar ? 'تم غلق التكييف'        : 'AC OFF';
    }
  }
}

void unawaited(Future<void> future) {
  future;
}