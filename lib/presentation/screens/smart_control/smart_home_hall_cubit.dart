import 'package:eye_comm_project/data/iot_service.dart';
import 'package:eye_comm_project/presentation/core/language_service.dart';
import 'package:eye_comm_project/presentation/core/voice_service.dart';

import '../eye_tracking/eye_tracking_cubit.dart';
import '../eye_tracking/eye_tracking_state.dart';
import 'smart_home_hall_state.dart';

export 'smart_home_hall_state.dart';

class SmartHomeHallCubit extends EyeTrackingCubit {
  SmartHomeHallCubit() : super(timerSec: 5) {
    // FIX: Immediately promote the initial EyeTrackingState to SmartHomeHallState.
    // Without this, the first frame sees EyeTrackingState and the UI cast crashes.
    emit(SmartHomeHallState(totalTimer: 5));
  }

  // ── Typed state accessor ──────────────────────────────────────────────────
  SmartHomeHallState get hallState {
    final s = state;
    if (s is SmartHomeHallState) return s;
    // Should never happen after the constructor emit, but safe fallback:
    return SmartHomeHallState(
      currentEye       : s.currentEye,
      stableDirection  : s.stableDirection,
      countdownSeconds : s.countdownSeconds,
      totalTimer       : s.totalTimer,
      confirmedGesture : s.confirmedGesture,
    );
  }

  bool get _ar => AppLanguage.current == 'ar';

  // ── KEY FIX: override copyStateWith so ALL base-class polling emits
  //    preserve the device fields (doorOpen, tvOn, etc.).
  //    Without this, every /predict poll would wipe device state back to
  //    defaults because the base class would emit a plain EyeTrackingState.
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

  // ── Gesture handler — called when stable hold timer fires ─────────────────
  @override
  Future<void> onGestureConfirmed(String gesture) async {
    switch (gesture) {
      case 'closed':
        // Navigation is handled in the UI via BlocConsumer listener.
        // VoiceService is unawaited — fires immediately, never blocks.
        VoiceService.speak(_ar ? 'رجوع' : 'Back');
        break;

      case 'left':  _toggleAc();     break;
      case 'right': _toggleDoor();   break;
      case 'up':    _toggleTv();     break;
      case 'down':  _toggleHeater(); break;
    }
  }

  // ── Device actions ─────────────────────────────────────────────────────────
  // Pattern for each:
  //   1. Compute next value
  //   2. Emit new state immediately (UI re-renders instantly)
  //   3. Speak feedback immediately (no await — non-blocking UX)
  //   4. Fire IoT call as fire-and-forget (no await — hardware latency hidden)

  void _toggleAc() {
    final AcMode next = _nextAcMode(hallState.acMode);
    emit(hallState.copyWith(acMode: next));
    VoiceService.speak(_acFeedback(next)); // 🔊 immediate, unawaited
    switch (next) {                         // 🌐 fire-and-forget
      case AcMode.cold: unawaited(IoTService.acCold()); break;
      case AcMode.hot:  unawaited(IoTService.acHot());  break;
      case AcMode.off:  unawaited(IoTService.acOff());  break;
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

  // ── Helpers ───────────────────────────────────────────────────────────────

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
      case AcMode.hot:  return _ar ? 'تكييف سخن'     : 'AC Hot';
      case AcMode.off:  return _ar ? 'التكييف اتطفى' : 'AC OFF';
    }
  }
}

// ── Dart doesn't have a built-in `unawaited` — use this helper ───────────────
// (Or add `package:async` and use `unawaited` from there. This is simpler.)
void unawaited(Future<void> future) {
  // ignore: unawaited_futures
  future;
}
