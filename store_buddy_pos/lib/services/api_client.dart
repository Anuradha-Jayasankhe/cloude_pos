import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String localBaseUrl = 'http://localhost:5000/api/v1';
  static const String cloudBaseUrl =
      'https://cloude-pos-theta.vercel.app/api/v1';

  static const String _defaultBaseUrl =
      kReleaseMode ? cloudBaseUrl : localBaseUrl;
  static const String configuredBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: _defaultBaseUrl,
  );

  String _baseUrl;
  late final Dio _dio;

  String get baseUrl => _baseUrl;

  ApiClient({String? baseUrl}) : _baseUrl = baseUrl ?? configuredBaseUrl {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(DeviceInterceptor());
    _dio.interceptors.add(TenantInterceptor());

    if (baseUrl == null) {
      autoDetectEnvironment();
    }
  }

  Future<void> autoDetectEnvironment() async {
    // If an explicit API_URL was supplied at build time, do not auto-switch
    if (const bool.hasEnvironment('API_URL')) return;

    if (kReleaseMode) {
      // In production release builds, always use Cloud Server
      updateBaseUrl(cloudBaseUrl);
      return;
    }

    // In local development/debug mode, auto-detect if local server is running
    final localAlive = await checkHealth(localBaseUrl);
    if (localAlive) {
      updateBaseUrl(localBaseUrl);
    } else {
      // If local server is not running, fall back to Cloud Server
      updateBaseUrl(cloudBaseUrl);
    }
  }

  void updateBaseUrl(String url) {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), '');
    _dio.options.baseUrl = _baseUrl;
  }

  Future<void> saveBaseUrl(String url) async {
    updateBaseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', _baseUrl);
  }

  Future<bool> checkHealth([String? testUrl]) async {
    try {
      final target = (testUrl ?? _baseUrl).replaceAll(RegExp(r'/+$'), '');
      final healthUrl = target.endsWith('/api/v1')
          ? target.replaceAll('/api/v1', '/health')
          : '$target/health';
      final dioClient = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      final res = await dioClient.get(healthUrl);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.put(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.patch(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.delete(path, queryParameters: queryParameters);
  }
}

class AuthInterceptor extends Interceptor {
  bool _isExpiredJwt(String token) {
    if (token.startsWith('platform-session-token') ||
        token.startsWith('store-session-token-')) {
      return false;
    }

    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      return true;
    }
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && !_isExpiredJwt(token)) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
    }

    handler.next(err);
  }
}

class TenantInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final tenantId = prefs.getString('tenant_id');

    if (tenantId != null) {
      options.headers['x-tenant-id'] = tenantId;
    }

    handler.next(options);
  }
}

class DeviceInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id');

    if (deviceId != null && deviceId.trim().isNotEmpty) {
      options.headers['x-device-id'] = deviceId.trim();
    }

    handler.next(options);
  }
}
