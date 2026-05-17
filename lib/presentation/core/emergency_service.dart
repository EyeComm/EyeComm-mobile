import 'dart:async';
import 'package:flutter/material.dart';

import 'language_service.dart';
import 'voice_service.dart';

// ══════════════════════════════════════════════════════════════════
// EmergencyDetector
// Watches for eye-movement inactivity and escalates alerts.
// ══════════════════════════════════════════════════════════════════
class EmergencyDetector {
  static Timer? _t;
  static DateTime? _last;
  static bool _activated = false;
  static bool _warn1 = false, _warn2 = false, _warn3 = false;

  /// Called whenever a valid eye-tracking result is received.
  static void recordMovement() {
    _last = DateTime.now();
    _activated = false;
    _start();
  }

  static void stop() {
    _t?.cancel();
    _activated = false;
  }

  /// Subscribe to receive the inactivity duration in seconds.
  static Function(int seconds)? onWarning;

  static void _start() {
    _t?.cancel();
    _warn1 = _warn2 = _warn3 = false;
    _t = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_last == null) return;
      final int s = DateTime.now().difference(_last!).inSeconds;
      onWarning?.call(s);
      if (s >= 150 && s < 210 && !_warn1) {
        _warn1 = true;
        VoiceService.speak(AppLanguage.t('are_you_ok'));
      }
      if (s >= 210 && s < 270 && !_warn2) {
        _warn2 = true;
        VoiceService.speak(AppLanguage.t('no_movement_warn'));
      }
      if (s >= 270 && s < 300 && !_warn3) {
        _warn3 = true;
        VoiceService.speak(AppLanguage.t('emergency_alert'));
      }
      if (s >= 300 && !_activated) {
        _activated = true;
        _callSequence();
      }
    });
  }

  static void _callSequence() async {
    VoiceService.speak(AppLanguage.t('calling_caregiver'));
    await Future.delayed(const Duration(seconds: 2));
    for (final num in CaregiverNumberManager.numbers) {
      await VoiceService.speak(AppLanguage.current == 'ar'
          ? 'جاري الاتصال بـ $num'
          : 'Calling $num');
      await Future.delayed(const Duration(seconds: 5));
    }
    await VoiceService.speak(AppLanguage.current == 'ar'
        ? 'جاري الاتصال بالطوارئ 123'
        : 'Calling emergency 123');
  }
}

// ══════════════════════════════════════════════════════════════════
// CaregiverNumberManager
// Simple in-memory list of caregiver phone numbers.
// ══════════════════════════════════════════════════════════════════
class CaregiverNumberManager {
  static List<String> numbers = [];

  static void add(String n) {
    if (n.isNotEmpty && !numbers.contains(n)) numbers.add(n);
  }

  static void remove(int i) {
    if (i >= 0 && i < numbers.length) numbers.removeAt(i);
  }
}

// ══════════════════════════════════════════════════════════════════
// MedicationAlarmManager
// ══════════════════════════════════════════════════════════════════
class MedicationAlarmManager {
  static TimeOfDay? alarmTime;
  static Timer? _t;
  static bool ringing = false;

  static void set(TimeOfDay t) {
    alarmTime = t;
    _startCheck();
  }

  static void cancel() {
    alarmTime = null;
    _t?.cancel();
  }

  static void _startCheck() {
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 30), (_) {
      if (alarmTime != null && !ringing) {
        final n = TimeOfDay.now();
        if (n.hour == alarmTime!.hour && n.minute == alarmTime!.minute) {
          _ring();
        }
      }
    });
  }

  static void _ring() async {
    ringing = true;
    for (int i = 0; i < 5; i++) {
      await VoiceService.speak(AppLanguage.t('medication_time'));
      await Future.delayed(const Duration(seconds: 3));
    }
    ringing = false;
    alarmTime = null;
  }
}
