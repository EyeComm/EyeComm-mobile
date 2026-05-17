// ════════════════════════════════════════════════════════════════════════════
// wheelchair_cubit.dart
//
// Wheelchair motor control. Same eye-tracking base — different actions.
// Uses EyeTrackingState directly (no extra device fields needed).
// ════════════════════════════════════════════════════════════════════════════

import 'package:eye_comm_project/presentation/core/language_service.dart';
import 'package:eye_comm_project/presentation/core/voice_service.dart';

import '../eye_tracking/eye_tracking_cubit.dart';
import '../eye_tracking/eye_tracking_state.dart';

export '../eye_tracking/eye_tracking_state.dart';

class WheelchairCubit extends EyeTrackingCubit {
  // Faster hold timer for motor commands (3 s instead of 5 s).
  WheelchairCubit() : super(timerSec: 3);

  bool get _ar => AppLanguage.current == 'ar';

  // WheelchairCubit uses EyeTrackingState directly, so NO copyStateWith
  // override is needed — the base class already returns EyeTrackingState.

  @override
  Future<void> onGestureConfirmed(String gesture) async {
    switch (gesture) {
      case 'closed':
        VoiceService.speak(_ar ? 'رجوع' : 'Back');
        // Navigation handled by the UI's BlocConsumer listener.
        break;
      case 'left':
        VoiceService.speak(_ar ? 'يسار' : 'Left');
        // TODO: unawaited(IoTService.wheelchairLeft());
        break;
      case 'right':
        VoiceService.speak(_ar ? 'يمين' : 'Right');
        // TODO: unawaited(IoTService.wheelchairRight());
        break;
      case 'up':
        VoiceService.speak(_ar ? 'للأمام' : 'Forward');
        // TODO: unawaited(IoTService.wheelchairForward());
        break;
      case 'down':
        VoiceService.speak(_ar ? 'للخلف' : 'Backward');
        // TODO: unawaited(IoTService.wheelchairBackward());
        break;
    }
  }
}
