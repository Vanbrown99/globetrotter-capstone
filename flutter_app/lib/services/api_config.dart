import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Default to the API Gateway on port 5400. Emulator mapping for Android
    // uses 10.0.2.2 to reach the host machine.
    if (kIsWeb) {
      return 'http://127.0.0.1:5400/api';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5400/api';
    }

    if (Platform.isIOS) {
      return 'http://127.0.0.1:5400/api';
    }

    return 'http://127.0.0.1:5400/api';
  }
}
