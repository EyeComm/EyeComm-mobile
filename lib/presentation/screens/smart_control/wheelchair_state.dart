import '../eye_tracking/eye_tracking_state.dart';

class WheelchairState extends EyeTrackingState {
  final String currentDirection;

  const WheelchairState({
    this.currentDirection = 'S',
    super.currentEye,
    super.stableDirection,
    super.countdownSeconds,
    super.totalTimer,
    super.confirmedGesture,
  });

  @override
  WheelchairState copyWith({
    String? currentDirection,
    String? currentEye,
    String? stableDirection,
    int?    countdownSeconds,
    int?    totalTimer,
    Object? confirmedGesture = kKeepGesture,
  }) {
    return WheelchairState(
      currentDirection : currentDirection ?? this.currentDirection,
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
  List<Object?> get props => [
    ...super.props,
    currentDirection,
  ];
}