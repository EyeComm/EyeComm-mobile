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
    switch (gesture) {
      case 'closed':
        VoiceService.speak(_ar ? 'رجوع' : 'Back');
        break;
      case 'left':  _toggleAc();     break;
      case 'right': _toggleDoor();   break;
      case 'up':    _toggleTv();     break;
      case 'down':  _toggleHeater(); break;
    }
  }

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

  void _toggleDoor() {
    final bool next = !hallState.doorOpen;
    emit(hallState.copyWith(doorOpen: next));
    VoiceService.speak(
      _ar ? (next ? 'الباب مفتوح' : 'الباب مغلق')
          : (next ? 'Door Open'  : 'Door Closed'),
    );
    unawaited(next ? IoTService.doorOpen() : IoTService.doorClose());
  }

  void _toggleTv() {
    final bool next = !hallState.tvOn;
    emit(hallState.copyWith(tvOn: next));
    VoiceService.speak(
      _ar ? (next ? 'الشاشة شغالة' : 'الشاشة مطفية')
          : (next ? 'TV ON'        : 'TV OFF'),
    );
    unawaited(next ? IoTService.tvOn() : IoTService.tvOff());
  }

  void _toggleHeater() {
    final bool next = !hallState.heaterOn;
    emit(hallState.copyWith(heaterOn: next));
    VoiceService.speak(
      _ar ? (next ? 'الدفاية شغالة' : 'الدفاية مطفية')
          : (next ? 'Heater ON'     : 'Heater OFF'),
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
      case AcMode.cold: return _ar ? 'تكييف بارد'    : 'AC Cold';
      case AcMode.hot: return _ar ? 'تكييف سخن'     : 'AC Hot';
      case AcMode.off: return _ar ? 'التكييف اتطفى' : 'AC OFF';
    }
  }
}

void unawaited(Future<void> future) {
  future;
}