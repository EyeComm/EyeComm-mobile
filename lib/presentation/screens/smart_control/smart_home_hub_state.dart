import '../eye_tracking/eye_tracking_state.dart';

class SmartHomeHubState extends EyeTrackingState {
  final bool isDoorOpen;

  const SmartHomeHubState({
    this.isDoorOpen = false,
    super.currentEye,
    super.stableDirection,
    super.countdownSeconds,
    super.totalTimer,
    super.confirmedGesture,
  });

  @override
  SmartHomeHubState copyWith({
    bool? isDoorOpen,
    String? currentEye,
    String? stableDirection,
    int? countdownSeconds,
    int? totalTimer,
    Object? confirmedGesture = kKeepGesture,
  }) {
    return SmartHomeHubState(
      isDoorOpen: isDoorOpen ?? this.isDoorOpen,
      currentEye: currentEye ?? this.currentEye,
      stableDirection: stableDirection ?? this.stableDirection,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      totalTimer: totalTimer ?? this.totalTimer,
      confirmedGesture: identical(confirmedGesture, kKeepGesture)
          ? this.confirmedGesture
          : confirmedGesture as String?,
    );
  }

  @override
  List<Object?> get props => [...super.props, isDoorOpen];
}