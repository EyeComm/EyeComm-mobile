// ════════════════════════════════════════════════════════════════════════════
// smart_home_room_state.dart
//
// Immutable device state for the Bedroom screen.
// Same pattern as SmartHomeHallState — extends EyeTrackingState.
// ════════════════════════════════════════════════════════════════════════════

import '../eye_tracking/eye_tracking_state.dart';

class SmartHomeRoomState extends EyeTrackingState {
  final bool lightOn;
  final bool fanOn;
  final bool bedUp;
  final bool windowOpen;

  const SmartHomeRoomState({
    this.lightOn    = false,
    this.fanOn      = false,
    this.bedUp      = false,
    this.windowOpen = false,
    // Eye-tracking fields forwarded to parent
    super.currentEye,
    super.stableDirection,
    super.countdownSeconds,
    super.totalTimer,
    super.confirmedGesture,
  });

  @override
  SmartHomeRoomState copyWith({
    bool?   lightOn,
    bool?   fanOn,
    bool?   bedUp,
    bool?   windowOpen,
    String? currentEye,
    String? stableDirection,
    int?    countdownSeconds,
    int?    totalTimer,
    Object? confirmedGesture = kKeepGesture,
  }) {
    return SmartHomeRoomState(
      lightOn          : lightOn          ?? this.lightOn,
      fanOn            : fanOn            ?? this.fanOn,
      bedUp            : bedUp            ?? this.bedUp,
      windowOpen       : windowOpen       ?? this.windowOpen,
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
        lightOn,
        fanOn,
        bedUp,
        windowOpen,
      ];
}
