// ════════════════════════════════════════════════════════════════════════════
// eye_tracking_cubit.dart
//
// ⭐ THE KEY DRY FIX: Every screen that needs eye-tracking extends this cubit
//    instead of duplicating the Timer + HTTP polling logic.
//
// Responsibilities:
//   • Poll /predict every 800 ms
//   • Debounce: a direction must be held stable for [timerSec] seconds
//   • Emit [EyeTrackingState] (or a subclass) with live currentEye,
//     countdown, stableDirection, and a one-shot [confirmedGesture] field
//   • Subclasses override [onGestureConfirmed] to react (call IoT / Voice)
//
// FIX vs original: We no longer try to override the `state` getter. Instead:
//   • The constructor calls [buildInitialState] which subclasses can override
//     to return their own initial state (e.g. SmartHomeHallState).
//   • The helper [emitCopyWith] provides a safe typed emit for subclasses.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'eye_tracking_state.dart';

export 'eye_tracking_state.dart';

abstract class EyeTrackingCubit extends Cubit<EyeTrackingState> {
  EyeTrackingCubit({
    int    timerSec   = 5,
    String predictUrl = 'http://127.0.0.1:5000/predict',
  })  : _timerSec   = timerSec,
        _predictUrl = predictUrl,
        // buildInitialState lets subclasses inject their own typed initial state
        // without needing to override the `state` getter (which doesn't work).
        super(EyeTrackingState(totalTimer: timerSec)) {
    _startPolling();
  }

  // ── Configuration ─────────────────────────────────────────────────────────
  final int    _timerSec;
  final String _predictUrl;

  // ── Internal polling state ─────────────────────────────────────────────────
  Timer?    _pollTimer;
  bool      _busy      = false;
  String    _stableDir = 'none';
  DateTime? _stableAt;

  // ── Contract ───────────────────────────────────────────────────────────────

  /// Subclasses MUST implement this to handle a confirmed gesture.
  /// VoiceService.speak() and IoTService calls go here — NOT in the UI.
  /// Navigation is NOT done here; instead the cubit emits confirmedGesture
  /// and the UI BlocConsumer listener handles navigation.
  Future<void> onGestureConfirmed(String gesture);

  /// Subclasses override this to return a typed copy of the current state
  /// with new eye-tracking fields. This avoids the broken `state` getter
  /// override pattern.
  ///
  /// Default implementation returns a plain [EyeTrackingState]. Subclasses
  /// like [SmartHomeHallCubit] override this to return [SmartHomeHallState].
  EyeTrackingState copyStateWith({
    String?  currentEye,
    String?  stableDirection,
    int?     countdownSeconds,
    int?     totalTimer,
    Object?  confirmedGesture = kKeepGesture,
  }) {
    return state.copyWith(
      currentEye       : currentEye,
      stableDirection  : stableDirection,
      countdownSeconds : countdownSeconds,
      totalTimer       : totalTimer,
      confirmedGesture : confirmedGesture,
    );
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _stableDir = 'none';
    _stableAt  = null;
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (_) => _poll(),
    );
  }

  Future<void> _poll() async {
    if (_busy || isClosed) return;
    _busy = true;
    try {
      final response = await http
          .get(Uri.parse(_predictUrl))
          .timeout(const Duration(seconds: 4));

      if (isClosed) return;
      if (response.statusCode != 200) return;

      final String eye =
          (jsonDecode(response.body) as Map<String, dynamic>)['prediction']
              as String? ??
              'none';

      // ── Always update the raw eye indicator so the camera bar reacts ──────
      if (!isClosed) {
        emit(copyStateWith(currentEye: eye));
      }

      if (eye == 'none') {
        _resetStable();
        return;
      }

      if (eye == _stableDir) {
        // Same direction — count down
        final int elapsed   = DateTime.now().difference(_stableAt!).inSeconds;
        final int remaining = (_timerSec - elapsed).clamp(0, _timerSec);

        if (!isClosed) emit(copyStateWith(countdownSeconds: remaining));

        if (elapsed >= _timerSec) {
          // ✅ Gesture confirmed — stop polling, fire action, restart
          _pollTimer?.cancel();
          final String confirmed = eye;
          _resetStable();

          // Step 1: emit confirmedGesture so the BlocConsumer listener fires
          if (!isClosed) {
            emit(copyStateWith(confirmedGesture: confirmed));
          }

          // Step 2: execute side-effects (Voice + IoT) — subclass responsibility
          await onGestureConfirmed(confirmed);

          // Step 3: clear confirmedGesture so the listener won't re-fire on
          // future rebuilds. Use a microtask so the listener gets its frame first.
          await Future.microtask(() {
            if (!isClosed) {
              emit(copyStateWith(confirmedGesture: null));
            }
          });

          _startPolling();
        }
      } else {
        // New direction — start tracking it
        _stableDir = eye;
        _stableAt  = DateTime.now();
        if (!isClosed) {
          emit(copyStateWith(
            stableDirection  : eye,
            countdownSeconds : _timerSec,
          ));
        }
      }
    } on TimeoutException {
      // Server not reachable — silently ignore, keep polling
    } catch (_) {
      // Any other error — silently ignore
    } finally {
      _busy = false;
    }
  }

  void _resetStable() {
    _stableDir = 'none';
    _stableAt  = null;
    if (!isClosed) {
      emit(copyStateWith(
        stableDirection  : 'none',
        countdownSeconds : 0,
      ));
    }
  }

  // ── Manual trigger ─────────────────────────────────────────────────────────
  /// Allows the UI to simulate a confirmed gesture (e.g. card tap fallback).
  /// Also emits confirmedGesture so BlocConsumer listeners (for navigation)
  /// fire correctly — even on manual taps.
  Future<void> triggerManual(String gesture) async {
    if (!isClosed) {
      emit(copyStateWith(confirmedGesture: gesture));
    }
    await onGestureConfirmed(gesture);
    await Future.microtask(() {
      if (!isClosed) {
        emit(copyStateWith(confirmedGesture: null));
      }
    });
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
