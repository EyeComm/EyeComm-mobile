// ════════════════════════════════════════════════════════════════════════════
// eye_tracking_state.dart
//
// Base immutable state shared by every eye-tracking screen.
// Defined as a STANDALONE file (not a part file) so subclasses in other
// files can extend it without needing the cubit as a part.
// ════════════════════════════════════════════════════════════════════════════

import 'package:equatable/equatable.dart';

/// Sentinel used by [copyWith] to distinguish "not provided" from null.
/// Placed here so all subclass copyWith methods can reference it.
const Object kKeepGesture = Object();

/// What the UI needs to display the ModernTrackingQualityBar and react
/// to confirmed gestures without holding any business logic itself.
class EyeTrackingState extends Equatable {
  /// The raw prediction from the Python /predict endpoint.
  /// Possible values: 'left', 'right', 'up', 'down', 'closed', 'none'
  final String currentEye;

  /// The direction that has been held stable long enough to start counting.
  final String stableDirection;

  /// Seconds remaining until the gesture fires (counts DOWN from [totalTimer]).
  final int countdownSeconds;

  /// The total countdown duration — passed to ModernTrackingQualityBar for
  /// rendering the progress arc correctly.
  final int totalTimer;

  /// Non-null for exactly one emission when a gesture is confirmed.
  /// The cubit emits this and immediately emits null so the BlocConsumer
  /// listener fires exactly once per gesture.
  final String? confirmedGesture;

  const EyeTrackingState({
    this.currentEye       = 'none',
    this.stableDirection  = 'none',
    this.countdownSeconds = 0,
    this.totalTimer       = 5,
    this.confirmedGesture,
  });

  EyeTrackingState copyWith({
    String? currentEye,
    String? stableDirection,
    int?    countdownSeconds,
    int?    totalTimer,
    // Use sentinel so callers can explicitly clear confirmedGesture to null.
    Object? confirmedGesture = kKeepGesture,
  }) {
    return EyeTrackingState(
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
        currentEye,
        stableDirection,
        countdownSeconds,
        totalTimer,
        confirmedGesture,
      ];
}
