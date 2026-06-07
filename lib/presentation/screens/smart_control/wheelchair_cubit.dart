import 'dart:async';
import 'package:eye_comm_project/data/iot_service.dart';
import 'package:eye_comm_project/presentation/core/language_service.dart';
import 'package:eye_comm_project/presentation/core/voice_service.dart';

import '../eye_tracking/eye_tracking_cubit.dart';
import 'wheelchair_state.dart';

export 'wheelchair_state.dart';

class WheelchairCubit extends EyeTrackingCubit {
  // الكرسي يحتاج عداد أسرع (3 ثوانٍ)
  WheelchairCubit() : super(timerSec: 3) {
    emit(const WheelchairState(totalTimer: 3));
  }

  WheelchairState get wheelchairState {
    final s = state;
    if (s is WheelchairState) return s;
    return WheelchairState(
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
    return wheelchairState.copyWith(
      currentEye       : currentEye,
      stableDirection  : stableDirection,
      countdownSeconds : countdownSeconds,
      totalTimer       : totalTimer,
      confirmedGesture : confirmedGesture,
    );
  }

  @override
  Future<void> onGestureConfirmed(String gesture) async {
    executeCommand(gesture);
  }

  // 🎯 الدالة الموحدة لتنفيذ الأوامر بالعين أو بالضغط باليد فوراً
  void executeCommand(String gesture) {
    switch (gesture) {
      case 'closed':
        VoiceService.speak(_ar ? 'رجوع' : 'Back');
        break;
      case 'up':    _moveForward();  break;
      case 'down':  _moveBackward(); break;
      case 'left':  _turnLeft();     break;
      case 'right': _turnRight();    break;
    }
  }

  void _moveForward() {
    emit(wheelchairState.copyWith(currentDirection: 'F'));
    VoiceService.speak(_ar ? 'للأمام' : 'Forward');
    unawaited(IoTService.wheelchairForward());
  }

  void _moveBackward() {
    emit(wheelchairState.copyWith(currentDirection: 'B'));
    VoiceService.speak(_ar ? 'للخلف' : 'Backward');
    unawaited(IoTService.wheelchairBackward());
  }

  void _turnLeft() {
    emit(wheelchairState.copyWith(currentDirection: 'L'));
    VoiceService.speak(_ar ? 'يسار' : 'Left');
    unawaited(IoTService.wheelchairLeft());
    _resetToStopAfterTurn();
  }

  void _turnRight() {
    emit(wheelchairState.copyWith(currentDirection: 'R'));
    VoiceService.speak(_ar ? 'يمين' : 'Right');
    unawaited(IoTService.wheelchairRight());
    _resetToStopAfterTurn();
  }

  // بما أن السيرفر يلف لفترة قصيرة ثم يقف تلقائياً، نعيد الحالة لـ متوقف بعد الدوران
  void _resetToStopAfterTurn() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (wheelchairState.currentDirection == 'L' || wheelchairState.currentDirection == 'R') {
        emit(wheelchairState.copyWith(currentDirection: 'S'));
      }
    });
  }
}

void unawaited(Future<void> future) {
  future;
}