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
    // العين أكدت الحركة -> ننفذ الأمر فوراً
    executeCommand(gesture);
  }

  // 🎯 الدالة الجديدة الموحدة لتشغيل الأوامر بالعين أو باليد
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

  void _toggleLight() {
    final bool next = !roomState.lightOn;
    emit(roomState.copyWith(lightOn: next));
    VoiceService.speak(
      _ar ? (next ? 'النور شغال'  : 'النور مطفي')
          : (next ? 'Light ON'   : 'Light OFF'),
    );
    unawaited(next ? IoTService.light1On() : IoTService.light1Off());
  }

  void _toggleFan() {
    final bool next = !roomState.fanOn;
    emit(roomState.copyWith(fanOn: next));
    VoiceService.speak(
      _ar ? (next ? 'المروحة شغالة'  : 'المروحة مطفية')
          : (next ? 'Fan ON'         : 'Fan OFF'),
    );
    unawaited(next ? IoTService.fanOn() : IoTService.fanOff());
  }

  void _toggleBed() {
    final bool next = !roomState.bedUp;
    emit(roomState.copyWith(bedUp: next));
    VoiceService.speak(
      _ar ? (next ? 'السرير اترفع' : 'السرير نزل')
          : (next ? 'Bed UP'       : 'Bed DOWN'),
    );
    unawaited(next ? IoTService.bedUp() : IoTService.bedDown());
  }

  void _toggleWindow() {
    final bool next = !roomState.windowOpen;
    emit(roomState.copyWith(windowOpen: next));
    VoiceService.speak(
      _ar ? (next ? 'الشباك اتفتح' : 'الشباك اتقفل')
          : (next ? 'Window OPEN'  : 'Window CLOSED'),
    );
    unawaited(next ? IoTService.windowOpen() : IoTService.windowClose());
  }
}