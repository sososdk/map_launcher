import 'dart:async';

import 'package:flutter/services.dart';

class MapLauncher {
  static const MethodChannel _channel =
      const MethodChannel('map_launcher');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
