// ════════════════════════════════════════════════════════════════════════════
// wheelchair_state.dart
//
// Wheelchair has no device toggles, so we reuse EyeTrackingState directly.
// The part file is kept for symmetry and future expansion.
// ════════════════════════════════════════════════════════════════════════════

part of 'wheelchair_cubit.dart';

// WheelchairCubit uses EyeTrackingState directly — no extra fields needed.
// If motor speed or mode controls are added later, create a WheelchairState
// that extends EyeTrackingState (same pattern as SmartHomeHallState).
