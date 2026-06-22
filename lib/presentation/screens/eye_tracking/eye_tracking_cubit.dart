import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../../core/voice_service.dart';
import 'eye_tracking_state.dart';

export 'eye_tracking_state.dart';

abstract class EyeTrackingCubit extends Cubit<EyeTrackingState> {
  EyeTrackingCubit({
    int    timerSec   = 7,
    String predictUrl = 'http://127.0.0.1:5000/predict',
  })  : _timerSec   = timerSec,
        _predictUrl = predictUrl,
        super(EyeTrackingState(totalTimer: timerSec)) {
    cooldownUntil = DateTime.now().add(const Duration(milliseconds: 1500));
    _startPolling();
  }

  final int    _timerSec;
  final String _predictUrl;

  Timer?    _pollTimer;
  bool      _busy      = false;
  String    _stableDir = 'none';
  DateTime? _stableAt;
  DateTime  cooldownUntil = DateTime.now();

  bool _isActive = true;
  bool _isDisposed = false;
  bool _faceDetected = false;  // ✅ متغير لتتبع وجود الوجه

  // ✅ تتبع آخر مرة شُوف فيها وجه - لمنع الأوامر بعد الابتعاد
  DateTime _lastFaceSeenAt = DateTime.now();
  static const Duration _faceGracePeriod = Duration(milliseconds: 1500);

  Future<void> onGestureConfirmed(String gesture);

  // ✅ labelForGesture للنطق عند تأكيد الأمر (بعد العد)
  String? labelForGesture(String gesture) => null;

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

  void _startPolling() {
    _pollTimer?.cancel();
    _isActive = true;
    _isDisposed = false;
    _stableDir = 'none';
    _stableAt  = null;
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (_) => _poll(),
    );
  }

  void resumePolling() {
    if (isClosed) return;
    _startPolling();
  }

  void stopPolling() {
    _isActive = false;
    _isDisposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    _stableDir = 'none';
    _stableAt  = null;
    if (!isClosed) {
      emit(copyStateWith(
        currentEye: 'none',
        stableDirection: 'none',
        countdownSeconds: 0,
      ));
    }
  }

  Future<void> _poll() async {
    if (!_isActive || _isDisposed || _busy || isClosed) return;

    if (DateTime.now().isBefore(cooldownUntil)) {
      _stableDir = 'none';
      _stableAt  = null;
      return;
    }

    _busy = true;
    try {
      final response = await http
          .get(Uri.parse(_predictUrl))
          .timeout(const Duration(seconds: 4));

      if (isClosed || !_isActive || _isDisposed) return;
      if (response.statusCode != 200) return;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final String eye = body['prediction'] as String? ?? 'none';

      // ✅ تحديث متغيرات الوجه
      final bool faceDetected = body['face_detected'] as bool? ?? true;
      final bool faceVerified = body['face_verified'] as bool? ?? true;
      _faceDetected = faceDetected;  // ✅ حفظ حالة الوجه

      if (faceDetected && faceVerified) {
        _lastFaceSeenAt = DateTime.now();
      }

      // ✅ لو الوجه اختفى أو غير موثق، إعادة ضبط العداد فوراً
      final bool faceActive = faceDetected &&
          (faceVerified ||
              DateTime.now().difference(_lastFaceSeenAt) < _faceGracePeriod);

      if (!faceActive) {
        if (!isClosed && _isActive && !_isDisposed) {
          emit(copyStateWith(currentEye: 'none'));
        }
        _resetStable();
        return;
      }

      if (!isClosed && _isActive && !_isDisposed) {
        emit(copyStateWith(currentEye: eye));
      }

      if (eye == 'none') {
        _resetStable();
        return;
      }

      if (eye == _stableDir) {
        final int elapsed   = DateTime.now().difference(_stableAt!).inSeconds;
        final int remaining = (_timerSec - elapsed).clamp(0, _timerSec);

        if (!isClosed && _isActive && !_isDisposed) {
          emit(copyStateWith(countdownSeconds: remaining));
        }

        if (elapsed >= _timerSec) {
          _pollTimer?.cancel();
          final String confirmed = eye;
          _resetStable();

          cooldownUntil = DateTime.now().add(const Duration(milliseconds: 1500));

          if (!isClosed && _isActive && !_isDisposed) {
            emit(copyStateWith(confirmedGesture: confirmed));
          }

          // ✅ النطق هنا بعد اكتمال العد
          final String? label = labelForGesture(confirmed);
          if (label != null && label.isNotEmpty) {
            VoiceService.speak(label);
          }

          if (_isActive && !_isDisposed && !isClosed) {
            await onGestureConfirmed(confirmed);
          }

          await Future.microtask(() {
            if (!isClosed && _isActive && !_isDisposed) {
              emit(copyStateWith(confirmedGesture: null));
            }
          });

          if (_isActive && !_isDisposed && !isClosed) {
            _startPolling();
          }
        }
      } else {
        _stableDir = eye;
        _stableAt  = DateTime.now();

        if (!isClosed && _isActive && !_isDisposed) {
          emit(copyStateWith(
            stableDirection  : eye,
            countdownSeconds : _timerSec,
          ));
        }
      }
    } on TimeoutException {
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  void _resetStable() {
    _stableDir = 'none';
    _stableAt  = null;
    if (!isClosed && _isActive && !_isDisposed) {
      emit(copyStateWith(
        stableDirection  : 'none',
        countdownSeconds : 0,
      ));
    }
  }

  Future<void> triggerManual(String gesture) async {
    if (!isClosed && _isActive && !_isDisposed) {
      emit(copyStateWith(confirmedGesture: gesture));
    }
    if (_isActive && !_isDisposed && !isClosed) {
      await onGestureConfirmed(gesture);
    }
    await Future.microtask(() {
      if (!isClosed && _isActive && !_isDisposed) {
        emit(copyStateWith(confirmedGesture: null));
      }
    });
  }

  @override
  Future<void> close() {
    _isActive = false;
    _isDisposed = true;
    _pollTimer?.cancel();
    return super.close();
  }
}