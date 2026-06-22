import 'package:http/http.dart' as http;

class IoTService {
  // ✅ عنوان الأسمارت هوم
  static String smartHomeUrl = 'http://192.168.4.1';
  
  // ✅ عنوان الكرسي المتحرك
  static String wheelchairUrl = 'http://192.168.4.2';

  static Future<void> _send(String url, String endpoint) async {
    try {
      await http
          .get(Uri.parse('$url$endpoint'))
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  // ─── أسمارت هوم ──────────────────────────────────────────
  static Future<void> light1On()  => _send(smartHomeUrl, '/light1_on');
  static Future<void> light1Off() => _send(smartHomeUrl, '/light1_off');
  static Future<void> light2On()  => _send(smartHomeUrl, '/light2_on');
  static Future<void> light2Off() => _send(smartHomeUrl, '/light2_off');

  static Future<void> tvOn()  => _send(smartHomeUrl, '/tv_on');
  static Future<void> tvOff() => _send(smartHomeUrl, '/tv_off');

  static Future<void> acHot()  => _send(smartHomeUrl, '/hot_ac');
  static Future<void> acCold() => _send(smartHomeUrl, '/cold_ac');
  static Future<void> acOff()  => _send(smartHomeUrl, '/ac_off');

  static Future<void> fanOn()  => _send(smartHomeUrl, '/fan_on');
  static Future<void> fanOff() => _send(smartHomeUrl, '/fan_off');

  static Future<void> doorOpen()  => _send(smartHomeUrl, '/door_open');
  static Future<void> doorClose() => _send(smartHomeUrl, '/door_close');

  static Future<void> windowOpen()  => _send(smartHomeUrl, '/window_open');
  static Future<void> windowClose() => _send(smartHomeUrl, '/window_close');

  static Future<void> bedUp()   => _send(smartHomeUrl, '/bed_up');
  static Future<void> bedDown() => _send(smartHomeUrl, '/bed_down');

  static Future<void> heaterOn()  => _send(smartHomeUrl, '/heater_on');
  static Future<void> heaterOff() => _send(smartHomeUrl, '/heater_off');

  static Future<void> emergency() => _send(smartHomeUrl, '/emergency');
  static Future<void> help()      => _send(smartHomeUrl, '/help');
  static Future<void> stopAll()   => _send(smartHomeUrl, '/stop');

  // ─── الكرسي المتحرك ──────────────────────────────────────
  static Future<void> wheelchairForward()  => _send(wheelchairUrl, '/move?dir=F');
  static Future<void> wheelchairBackward() => _send(wheelchairUrl, '/move?dir=B');
  static Future<void> wheelchairLeft()     => _send(wheelchairUrl, '/move?dir=L');
  static Future<void> wheelchairRight()    => _send(wheelchairUrl, '/move?dir=R');
}