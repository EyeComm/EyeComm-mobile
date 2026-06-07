import 'dart:async';
import 'package:eye_comm_project/presentation/core/language_service.dart';
import 'package:eye_comm_project/presentation/core/voice_service.dart';

import '../../../data/iot_service.dart';
import '../eye_tracking/eye_tracking_cubit.dart';
import 'smart_home_hub_state.dart';

export 'smart_home_hub_state.dart';

class SmartHomeHubCubit extends EyeTrackingCubit {
  SmartHomeHubCubit() : super(timerSec: 5) {
    emit(const SmartHomeHubState(totalTimer: 5));
  }

  SmartHomeHubState get hubState {
    final s = state;
    if (s is SmartHomeHubState) return s;
    return SmartHomeHubState(
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
    return hubState.copyWith(
      currentEye: currentEye,
      stableDirection: stableDirection,
      countdownSeconds: countdownSeconds,
      totalTimer: totalTimer,
      confirmedGesture: confirmedGesture,
    );
  }

  @override
  Future<void> onGestureConfirmed(String gesture) async {
    if (gesture == 'up' || gesture == 'closed') {
      executeHubCommand(gesture);
    }
  }

  Future<void> executeHubCommand(String gesture) async {
    if (gesture == 'closed') {
      VoiceService.speak(_ar ? 'رجوع' : 'Back');
    } else if (gesture == 'up') {
      final bool nextDoorState = !hubState.isDoorOpen;
      emit(hubState.copyWith(isDoorOpen: nextDoorState));

      VoiceService.speak(
        _ar ? (nextDoorState ? 'الباب مفتوح' : 'الباب مغلق')
            : (nextDoorState ? 'Door Open' : 'Door Closed'),
      );

      await _sendDoorCommand(nextDoorState);
    }
  }

  Future<void> _sendDoorCommand(bool open) async {
    try {
      if (open) {
        await IoTService.doorOpen();
      } else {
        await IoTService.doorClose();
      }
    } catch (e) {
      print("Error sending command to ESP32: $e");
    }
  }
}