import '../eye_tracking/eye_tracking_state.dart';

enum AcMode { off, hot, cold }

class SmartHomeHallState extends EyeTrackingState {
  final bool   doorOpen;
  final bool   tvOn;
  final bool   heaterOn;
  final AcMode acMode;

  const SmartHomeHallState({
    this.doorOpen = false,
    this.tvOn     = false,
    this.heaterOn = false,
    this.acMode   = AcMode.off,
    super.currentEye,
    super.stableDirection,
    super.countdownSeconds,
    super.totalTimer,
    super.confirmedGesture,
  });

  @override
  SmartHomeHallState copyWith({
    bool?   doorOpen,
    bool?   tvOn,
    bool?   heaterOn,
    AcMode? acMode,
    String? currentEye,
    String? stableDirection,
    int?    countdownSeconds,
    int?    totalTimer,
    Object? confirmedGesture = kKeepGesture,
  }) {
    return SmartHomeHallState(
      doorOpen         : doorOpen         ?? this.doorOpen,
      tvOn             : tvOn             ?? this.tvOn,
      heaterOn         : heaterOn         ?? this.heaterOn,
      acMode           : acMode           ?? this.acMode,
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
    doorOpen,
    tvOn,
    heaterOn,
    acMode,
  ];
}