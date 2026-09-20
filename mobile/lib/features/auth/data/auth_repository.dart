import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/session_meta.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_session.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
    GoogleSignIn? googleSignIn,
  })  : _api = apiClient,
        _tokens = tokenStorage,
        _injectedGoogle = googleSignIn;

  final ApiClient _api;
  final TokenStorage _tokens;
  final GoogleSignIn? _injectedGoogle;
  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _google {
    return _injectedGoogle ??
        (_googleSignIn ??= GoogleSignIn(
          scopes: const ['email', 'openid', 'profile'],
          serverClientId: AppConfig.googleClientIdWeb.isEmpty
              ? null
              : AppConfig.googleClientIdWeb,
        ));
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
          'device_info': 'flutter',
        },
        skipAuth: true,
      );
      return await _persistSession(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<AuthSession> loginWithGoogle({
    required String langue,
    String? fuseauHoraire,
  }) async {
    if (AppConfig.googleClientIdWeb.isEmpty) {
      throw ApiException(
        code: 'GOOGLE_NOT_CONFIGURED',
        message:
            'Google Sign-In n’est pas configuré (GOOGLE_CLIENT_ID_WEB manquant).',
      );
    }

    // ignore: avoid_print
    print(
      'Google Sign-In: serverClientId='
      '${AppConfig.googleClientIdWeb.substring(0, 20)}… '
      'androidIdConfigured=${AppConfig.googleClientIdAndroid.isNotEmpty}',
    );

    late final GoogleSignInAccount account;
    try {
      final signedIn = await _google.signIn();
      if (signedIn == null) {
        throw ApiException(
          code: 'GOOGLE_CANCELLED',
          message: 'Connexion Google annulée.',
        );
      }
      account = signedIn;
    } on ApiException {
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('Google Sign-In platform error: $e');
      final detail = e.toString();
      if (detail.contains('ApiException: 10') ||
          detail.contains('DEVELOPER_ERROR')) {
        throw ApiException(
          code: 'GOOGLE_DEVELOPER_ERROR',
          message:
              'Erreur Google 10 (DEVELOPER_ERROR) : package/SHA-1 '
              'ou client OAuth Android incorrect.',
        );
      }
      if (detail.contains('ApiException: 7') ||
          detail.contains('NETWORK_ERROR')) {
        throw ApiException(
          code: 'GOOGLE_NETWORK',
          message: 'Réseau indisponible pour Google Sign-In.',
        );
      }
      if (detail.contains('ApiException: 12500')) {
        throw ApiException(
          code: 'GOOGLE_SIGNIN_FAILED',
          message:
              'Échec Google 12500 — vérifie l’écran de consentement OAuth '
              '(mode test + utilisateurs de test).',
        );
      }
      throw ApiException(
        code: 'GOOGLE_SIGNIN_FAILED',
        message: 'Échec Google Sign-In: $detail',
      );
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      // ignore: avoid_print
      print(
        'Google Sign-In: idToken null (accessToken='
        '${auth.accessToken != null}) — serverClientId WEB requis.',
      );
      throw ApiException(
        code: 'GOOGLE_TOKEN_INVALID',
        message:
            'Pas d’id_token Google. Vérifie que GOOGLE_CLIENT_ID_WEB '
            'est bien un client OAuth de type « Application Web ».',
      );
    }

    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/auth/google',
        data: {
          'id_token': idToken,
          'langue': langue,
          if (fuseauHoraire != null && fuseauHoraire.isNotEmpty)
            'fuseau_horaire': fuseauHoraire,
          'device_info': 'flutter',
        },
        skipAuth: true,
      );
      return await _persistSession(res.data ?? {});
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> register({
    required String email,
    required String langue,
    String? fuseauHoraire,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'email': email.trim().toLowerCase(),
          'langue': langue,
          if (fuseauHoraire != null && fuseauHoraire.isNotEmpty)
            'fuseau_horaire': fuseauHoraire,
        },
        skipAuth: true,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> resendOtp({
    required String email,
    String type = 'inscription',
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/resend-otp',
        data: {
          'email': email.trim().toLowerCase(),
          'type': type,
        },
        skipAuth: true,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<String> verifyOtp({
    required String email,
    required String code,
    String type = 'inscription',
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/auth/verify-otp',
        data: {
          'email': email.trim().toLowerCase(),
          'code': code.trim(),
          'type': type,
        },
        skipAuth: true,
      );
      final token = res.data?['temp_token'] as String?;
      if (token == null || token.isEmpty) {
        throw StateError('temp_token manquant');
      }
      return token;
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> setPassword({
    required String tempToken,
    required String password,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/set-password',
        data: {
          'temp_token': tempToken,
          'password': password,
        },
        skipAuth: true,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/forgot-password',
        data: {'email': email.trim().toLowerCase()},
        skipAuth: true,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> resetPassword({
    String? email,
    String? code,
    String? tempToken,
    required String nouveauPassword,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/reset-password',
        data: {
          'nouveau_password': nouveauPassword,
          if (tempToken != null && tempToken.isNotEmpty)
            'temp_token': tempToken,
          if (email != null && email.isNotEmpty)
            'email': email.trim().toLowerCase(),
          if (code != null && code.isNotEmpty) 'code': code.trim(),
        },
        skipAuth: true,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> changePassword({
    String? currentPassword,
    required String nouveauPassword,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/change-password',
        data: {
          'nouveau_password': nouveauPassword,
          if (currentPassword != null && currentPassword.isNotEmpty)
            'current_password': currentPassword,
        },
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> requestEmailChange({required String nouvelEmail}) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/request-email-change',
        data: {'nouvel_email': nouvelEmail.trim().toLowerCase()},
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<String> confirmEmailChange({
    required String nouvelEmail,
    required String code,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/auth/confirm-email-change',
        data: {
          'nouvel_email': nouvelEmail.trim().toLowerCase(),
          'code': code.trim(),
        },
      );
      return res.data?['email']?.toString() ?? nouvelEmail.trim().toLowerCase();
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> acceptCgu({
    String? tempToken,
    required String version,
  }) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/accept-cgu',
        data: {
          'version': version,
          if (tempToken != null && tempToken.isNotEmpty)
            'temp_token': tempToken,
        },
        skipAuth: tempToken != null && tempToken.isNotEmpty,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  Future<void> acceptConsentementSante({String? tempToken}) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/auth/accept-consentement-sante',
        data: {
          if (tempToken != null && tempToken.isNotEmpty)
            'temp_token': tempToken,
        },
        skipAuth: tempToken != null && tempToken.isNotEmpty,
      );
    } on DioException catch (e) {
      ApiClient.throwApi(e);
    }
  }

  /// Reprend une session persistée (hot restart / relance de l’app).
  Future<AuthSession?> restoreSession() async {
    final access = await _tokens.readAccessToken();
    final refresh = await _tokens.readRefreshToken();
    if ((access == null || access.isEmpty) &&
        (refresh == null || refresh.isEmpty)) {
      return null;
    }

    final sessionId = await _tokens.readSessionId() ?? '';
    try {
      final res = await _api.get<Map<String, dynamic>>('/auth/me');
      final me = res.data ?? {};
      final session = AuthSession(
        accessToken: access ?? '',
        refreshToken: refresh ?? '',
        expiresIn: 0,
        sessionId: sessionId,
        onboardingStep: me['onboarding_step'] as String? ?? 'infos',
        hasPatientProfile: me['has_patient_profile'] as bool? ?? false,
        isAidant: me['is_aidant'] as bool? ?? false,
        needsCgu: me['needs_cgu'] as bool? ?? false,
        needsConsentementSante:
            me['needs_consentement_sante'] as bool? ?? false,
      );
      await persistSessionSnapshot(session);
      return session;
    } on DioException catch (e) {
      if (!await _tokens.hasSession()) return null;
      final status = e.response?.statusCode ?? 0;
      if (e.response == null || status >= 500) {
        return _offlineSessionFromTokens(
          access: access,
          refresh: refresh,
          sessionId: sessionId,
        );
      }
      await _tokens.clear();
      return null;
    }
  }

  /// Persiste onboarding / profil pour le boot offline (hors JWT).
  Future<void> persistSessionSnapshot(AuthSession session) async {
    await _tokens.saveSessionMeta(SessionMeta.fromSession(session));
  }

  Future<AuthSession> _offlineSessionFromTokens({
    required String? access,
    required String? refresh,
    required String sessionId,
  }) async {
    final meta = await _tokens.readSessionMeta();
    if (meta != null) {
      return meta.applyTo(
        accessToken: access ?? '',
        refreshToken: refresh ?? '',
        sessionId: sessionId,
      );
    }
    // Upgrade sans cache : ne pas renvoyer vers « infos » si l’utilisateur
    // avait déjà une session valide.
    return AuthSession(
      accessToken: access ?? '',
      refreshToken: refresh ?? '',
      expiresIn: 0,
      sessionId: sessionId,
      onboardingStep: 'termine',
      hasPatientProfile: true,
      isAidant: false,
    );
  }

  Future<void> logout() async {
    final refresh = await _tokens.readRefreshToken();
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await _api.post<Map<String, dynamic>>(
          '/auth/logout',
          data: {'refresh_token': refresh},
        );
      }
    } on DioException {
      // On nettoie localement même si le serveur est injoignable.
    } finally {
      await _tokens.clear();
      try {
        await _google.signOut();
      } catch (_) {}
    }
  }

  Future<AuthSession> _persistSession(Map<String, dynamic> data) async {
    final session = AuthSession.fromJson(data);
    await _tokens.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      sessionId: session.sessionId,
    );
    await persistSessionSnapshot(session);
    return session;
  }
}
