import 'dart:async';
import 'package:eye_comm_project/data/iot_service.dart';
import 'package:eye_comm_project/presentation/core/language_service.dart';
import 'package:eye_comm_project/presentation/core/voice_service.dart';

import '../eye_tracking/eye_tracking_cubit.dart';
import '../eye_tracking/eye_tracking_state.dart';
import 'emergency_state.dart';

export 'emergency_state.dart';

void unawaited(Future<void> future) {
  future;
}

class EmergencyCubit extends EyeTrackingCubit {
  EmergencyCubit() : super(timerSec: 5) {
    emit(const EmergencyState(totalTimer: 5));
  }

  EmergencyState get emergencyState {
    final s = state;
    if (s is EmergencyState) return s;
    return EmergencyState(
      currentEye: s.currentEye,
      stableDirection: s.stableDirection,
      countdownSeconds: s.countdownSeconds,
      totalTimer: s.totalTimer,
      confirmedGesture: s.confirmedGesture,
    );
  }

  bool get _ar => AppLanguage.current == 'ar';

  @override
  EyeTrackingState copyStateWith({
    String? currentEye,
    String? stableDirection,
    int? countdownSeconds,
    int? totalTimer,
    Object? confirmedGesture = kKeepGesture,
  }) {
    return emergencyState.copyWith(
      currentEye: currentEye,
      stableDirection: stableDirection,
      countdownSeconds: countdownSeconds,
      totalTimer: totalTimer,
      confirmedGesture: confirmedGesture,
    );
  }

  @override
  Future<void> onGestureConfirmed(String gesture) async {
    executeCommand(gesture);
  }

  void executeCommand(String gesture) {
    switch (gesture) {
      case 'closed':
        VoiceService.speak(_ar ? 'رجوع' : 'Back');
        break;
      case 'left':
        _triggerHelp();
        break;
      case 'up':
        _triggerEmergency();
        break;
      case 'right':
        _triggerStop();
        break;
     }
  }

  void _triggerHelp() {
    emit(emergencyState.copyWith(activeAlert: 'help'));
    VoiceService.speak(_ar ? 'طلب مساعدة' : 'Help');
    unawaited(IoTService.help());
  }

  void _triggerEmergency() {
    emit(emergencyState.copyWith(activeAlert: 'emergency'));
    VoiceService.speak(_ar ? 'حالة طوارئ' : 'Emergency');
    unawaited(IoTService.emergency());
  }

  void _triggerStop() {
    emit(emergencyState.copyWith(activeAlert: 'none'));
    VoiceService.speak(_ar ? 'إيقاف التنبيه' : 'Stop Alert');
    unawaited(IoTService.stopAll());
  }
}