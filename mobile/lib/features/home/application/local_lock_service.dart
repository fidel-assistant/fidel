import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/locale/locale_controller.dart';

final localLockServiceProvider = Provider<LocalLockService>((ref) {
  return LocalLockService(
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

/// Verrouillage local PIN + biométrie (réglages, pas onboarding).
class LocalLockService {
  LocalLockService({
    required SharedPreferences prefs,
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
  })  : _prefs = prefs,
        _storage = storage ?? const FlutterSecureStorage(),
        _auth = localAuth ?? LocalAuthentication();

  static const _kEnabled = 'local_lock_enabled_v1';
  static const _kBiometrics = 'local_lock_biometrics_v1';
  static const _kPinHash = 'local_lock_pin_hash_v1';
  static const _kSalt = 'local_lock_pin_salt_v1';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth;

  bool get isEnabled => _prefs.getBool(_kEnabled) ?? false;

  bool get biometricsEnabled => _prefs.getBool(_kBiometrics) ?? false;

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<void> enablePin(String pin) async {
    final salt = base64Encode(
      List<int>.generate(16, (i) => DateTime.now().microsecondsSinceEpoch + i),
    );
    final hash = _hash(pin, salt);
    await _storage.write(key: _kSalt, value: salt);
    await _storage.write(key: _kPinHash, value: hash);
    await _prefs.setBool(_kEnabled, true);
  }

  Future<void> disable() async {
    await _prefs.setBool(_kEnabled, false);
    await _prefs.setBool(_kBiometrics, false);
    await _storage.delete(key: _kPinHash);
    await _storage.delete(key: _kSalt);
  }

  Future<void> setBiometrics(bool enabled) async {
    if (enabled && !isEnabled) return;
    await _prefs.setBool(_kBiometrics, enabled);
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _kSalt);
    final expected = await _storage.read(key: _kPinHash);
    if (salt == null || expected == null) return false;
    return _hash(pin, salt) == expected;
  }

  Future<bool> authenticateBiometrics({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('LocalLock biometrics failed: $e');
      return false;
    }
  }

  String _hash(String pin, String salt) {
    final bytes = utf8.encode('$salt::$pin');
    return sha256.convert(bytes).toString();
  }
}
