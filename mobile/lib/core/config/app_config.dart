import 'dart:convert';

import 'package:flutter/services.dart';

/// Config de l’app. En local : éditer `assets/config/app.json`, puis `flutter run`.
class AppConfig {
  static const String appName = 'Fidel';

  static const String _apiDefine = String.fromEnvironment('API_BASE_URL');
  static const String _googleWebDefine = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_WEB',
  );
  static const String _googleAndroidDefine = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_ANDROID',
  );
  static const String _googleIosDefine = String.fromEnvironment(
    'GOOGLE_CLIENT_ID_IOS',
  );

  static String apiBaseUrl = _apiDefine.isNotEmpty
      ? _apiDefine
      : 'http://10.0.2.2:8000';

  static const String apiV1Prefix = '/api/v1';

  static String get apiV1Base => '$apiBaseUrl$apiV1Prefix';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static String googleClientIdWeb = _googleWebDefine;
  static String googleClientIdAndroid = _googleAndroidDefine;
  static String googleClientIdIos = _googleIosDefine;

  static const String cguCurrentVersion = String.fromEnvironment(
    'CGU_VERSION',
    defaultValue: 'v1.0',
  );

  static const int passwordMinLength = 8;

  static Future<void> load() async {
    try {
      final raw = await rootBundle.loadString('assets/config/app.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (_apiDefine.isEmpty) {
        final fromFile = (map['API_BASE_URL'] as String? ?? '').trim();
        if (fromFile.isNotEmpty) apiBaseUrl = fromFile;
      }
      if (googleClientIdWeb.isEmpty) {
        googleClientIdWeb =
            (map['GOOGLE_CLIENT_ID_WEB'] as String? ?? '').trim();
      }
      if (googleClientIdAndroid.isEmpty) {
        googleClientIdAndroid =
            (map['GOOGLE_CLIENT_ID_ANDROID'] as String? ?? '').trim();
      }
      if (googleClientIdIos.isEmpty) {
        googleClientIdIos =
            (map['GOOGLE_CLIENT_ID_IOS'] as String? ?? '').trim();
      }
    } catch (_) {}
  }
}
