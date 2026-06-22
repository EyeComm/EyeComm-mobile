import 'package:eye_comm_project/data/iot_service.dart';
import 'package:eye_comm_project/presentation/core/language_service.dart';
import 'package:eye_comm_project/presentation/core/voice_service.dart';

import '../eye_tracking/eye_tracking_cubit.dart';
import '../eye_tracking/eye_tracking_state.dart';
import 'smart_home_room_state.dart';

export 'smart_home_room_state.dart';

void unawaited(Future<void> future) {
  future;
}

class SmartHomeRoomCubit extends EyeTrackingCubit {
  SmartHomeRoomCubit() : super(timerSec: 5) {
    emit(const SmartHomeRoomState(totalTimer: 5));
  }

  SmartHomeRoomState get roomState {
    final s = state;
    if (s is SmartHomeRoomState) return s;
    return SmartHomeRoomState(
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
      case 'down':   return null;  // النور بينطق من جوه
      case 'left':   return null;  // المروحة بينطق من جوه
      case 'right':  return null;  // السرير بينطق من جوه
      case 'up':     return null;  // الشباك بينطق من جوه
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
    return roomState.copyWith(
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
      case 'down':  _toggleLight();  break;
      case 'left':  _toggleFan();    break;
      case 'right': _toggleBed();    break;
      case 'up':    _toggleWindow(); break;
    }
  }

  // ✅ النور: تم فتح / تم غلق
  void _toggleLight() {
    final bool next = !roomState.lightOn;
    emit(roomState.copyWith(lightOn: next));
    VoiceService.speak(
      _ar ? (next ? 'تم فتح النور' : 'تم غلق النور')
          : (next ? 'Light ON'     : 'Light OFF'),
    );
    unawaited(next ? IoTService.light1On() : IoTService.light1Off());
  }

  // ✅ المروحة: المروحة مفتوحة / المروحة مقفولة
  void _toggleFan() {
    final bool next = !roomState.fanOn;
    emit(roomState.copyWith(fanOn: next));
    VoiceService.speak(
      _ar ? (next ? 'المروحة مفتوحة' : 'المروحة مقفولة')
          : (next ? 'Fan ON'         : 'Fan OFF'),
    );
    unawaited(next ? IoTService.fanOn() : IoTService.fanOff());
  }

  // ✅ السرير: تم رفع السرير / تم غلق السرير
  void _toggleBed() {
    final bool next = !roomState.bedUp;
    emit(roomState.copyWith(bedUp: next));
    VoiceService.speak(
      _ar ? (next ? 'تم رفع السرير' : 'تم غلق السرير')
          : (next ? 'Bed UP'        : 'Bed DOWN'),
    );
    unawaited(next ? IoTService.bedUp() : IoTService.bedDown());
  }

  // ✅ الشباك: الشباك مفتوح / الشباك مقفول
  void _toggleWindow() {
    final bool next = !roomState.windowOpen;
    emit(roomState.copyWith(windowOpen: next));
    VoiceService.speak(
      _ar ? (next ? 'الشباك مفتوح' : 'الشباك مقفول')
          : (next ? 'Window OPEN'  : 'Window CLOSED'),
    );
    unawaited(next ? IoTService.windowOpen() : IoTService.windowClose());
  }
}