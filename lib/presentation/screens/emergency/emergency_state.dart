import '../eye_tracking/eye_tracking_state.dart';

class EmergencyState extends EyeTrackingState {
  final String activeAlert;

  const EmergencyState({
    this.activeAlert = 'none',
    super.currentEye,
    super.stableDirection,
    super.countdownSeconds,
    super.totalTimer,
    super.confirmedGesture,
  });

  @override
  EmergencyState copyWith({
    String? activeAlert,
    String? currentEye,
    String? stableDirection,
    int?    countdownSeconds,
    int?    totalTimer,
    Object? confirmedGesture = kKeepGesture,
  }) {
    return EmergencyState(
      activeAlert      : activeAlert      ?? this.activeAlert,
      currentEye       : currentEye       ?? this.currentEye,
      stableDirection  : stableDirection  ?? this.stableDirection,
      countdownSeconds : countdownSeconds ?? this.countdownSeconds,
      totalTimer       : totalTimer       ?? this.totalTimer,
      confirmedGesture : identical(confirmedGesture, kKeepGesture)
          ? this.confirmedGesture
          : confirmedGesture as String?,
    );
  }

  @override
  List<Object?> get props => [...super.props, activeAlert];
}