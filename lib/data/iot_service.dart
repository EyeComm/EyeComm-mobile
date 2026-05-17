import 'package:http/http.dart' as http;

/// All HTTP calls to the local ESP8266 / IoT device.
/// Change [baseUrl] to match your device's access-point IP.
class IoTService {
  static String baseUrl = 'http://192.168.4.1';

  static Future<void> _send(String endpoint) async {
    try {
      await http
          .get(Uri.parse('$baseUrl$endpoint'))
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  // ── Lights ──────────────────────────────────────────────────────────────
  static Future<void> light1On()  => _send('/light1_on');
  static Future<void> light1Off() => _send('/light1_off');
  static Future<void> light2On()  => _send('/light2_on');
  static Future<void> light2Off() => _send('/light2_off');

  // ── TV ──────────────────────────────────────────────────────────────────
  static Future<void> tvOn()  => _send('/tv_on');
  static Future<void> tvOff() => _send('/tv_off');

  // ── AC ──────────────────────────────────────────────────────────────────
  static Future<void> acHot()  => _send('/hot_ac');
  static Future<void> acCold() => _send('/cold_ac');
  static Future<void> acOff()  => _send('/ac_off');

  // ── Fan ─────────────────────────────────────────────────────────────────
  static Future<void> fanOn()  => _send('/fan_on');
  static Future<void> fanOff() => _send('/fan_off');

  // ── Door ────────────────────────────────────────────────────────────────
  static Future<void> doorOpen()  => _send('/door_open');
  static Future<void> doorClose() => _send('/door_close');

  // ── Window ──────────────────────────────────────────────────────────────
  static Future<void> windowOpen()  => _send('/window_open');
  static Future<void> windowClose() => _send('/window_close');

  // ── Bed ─────────────────────────────────────────────────────────────────
  static Future<void> bedUp()   => _send('/bed_up');
  static Future<void> bedDown() => _send('/bed_down');

  // ── Heater ──────────────────────────────────────────────────────────────
  static Future<void> heaterOn()  => _send('/heater_on');
  static Future<void> heaterOff() => _send('/heater_off');

  // ── Emergency ───────────────────────────────────────────────────────────
  static Future<void> emergency() => _send('/emergency');
  static Future<void> help()      => _send('/help');
  static Future<void> stopAll()   => _send('/stop');
}
