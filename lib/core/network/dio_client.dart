import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../errors/app_exception.dart';
import '../logging/app_logger.dart';

/// Tạo và cấu hình Dio singleton cho toàn bộ ứng dụng.
///
/// Tích hợp sẵn:
/// - [AuthInterceptor]: Tự động gắn `Authorization: Bearer <token>`
/// - [TokenRefreshInterceptor]: Tự động refresh token khi nhận 401 và retry
/// - [ErrorInterceptor]: Convert `DioException` → `AppException`
class DioClient {
  DioClient._();

  static Dio? _instance;
  static void Function()? _onSessionExpired;

  /// Dio instance chính — có đầy đủ interceptors.
  /// Dùng cho mọi request đến `/api/*`.
  static Dio get instance {
    if (_instance == null) {
      throw StateError(
        'DioClient chưa được khởi tạo. Gọi DioClient.initialize() trước.',
      );
    }
    return _instance!;
  }

  /// Dio instance "sạch" — không có auth interceptor.
  /// Dùng cho các request không cần token: `/auth/register`, `/auth/login`,
  /// `/auth/refresh`.
  static Dio get publicInstance {
    return Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ))
      ..interceptors.add(ApiLogInterceptor())
      ..interceptors.add(ErrorInterceptor());
  }

  /// Khởi tạo Dio singleton.
  ///
  /// [onSessionExpired] được gọi khi refresh token thất bại (401/403) —
  /// thường dùng để logout user và quay về màn hình đăng nhập.
  static void initialize({void Function()? onSessionExpired}) {
    _onSessionExpired = onSessionExpired;
    _debugApiLog('[DioClient] initialize baseUrl=${ApiConfig.baseUrl}');

    _instance = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _instance!.interceptors.addAll([
      AuthInterceptor(),
      TokenRefreshInterceptor(_instance!, onSessionExpired: _onSessionExpired),
      ApiLogInterceptor(),
      ErrorInterceptor(),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Interceptors
// ---------------------------------------------------------------------------

/// Tự động đọc access token từ SharedPreferences và gắn vào header
/// `Authorization: Bearer <token>` cho mọi request.
class AuthInterceptor extends Interceptor {
  static const _accessTokenKey = 'access_token';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      _debugApiLog(
        '[AuthInterceptor] Attached access token for ${options.method} ${options.path}',
      );
    } else {
      _debugApiLog(
        '[AuthInterceptor] No access token for ${options.method} ${options.path}',
      );
    }

    handler.next(options);
  }
}

class ApiLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _debugApiLog(
      '[API Request] ${options.method} ${options.uri}\n'
      'headers: ${_sanitizeHeaders(options.headers)}\n'
      'query: ${options.queryParameters}\n'
      'data: ${_sanitizeData(options.data)}',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _debugApiLog(
      '[API Response] ${response.statusCode} '
      '${response.requestOptions.method} ${response.requestOptions.uri}\n'
      'data: ${_sanitizeData(response.data)}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _debugApiLog(
      '[API Error] ${err.response?.statusCode ?? 'no-status'} '
      '${err.requestOptions.method} ${err.requestOptions.uri}\n'
      'type: ${err.type}\n'
      'message: ${err.message}\n'
      'response: ${_sanitizeData(err.response?.data)}',
    );
    handler.next(err);
  }
}

/// Khi server trả 401 (Unauthorized):
/// 1. Dùng refresh_token để lấy access_token mới
/// 2. Lưu access_token mới vào SharedPreferences
/// 3. Retry request gốc với token mới
///
/// Nếu refresh cũng thất bại (401/403) → gọi [onSessionExpired] để logout.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor(
    this._dio, {
    this.onSessionExpired,
  });

  final Dio _dio;
  final void Function()? onSessionExpired;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  bool _isRefreshing = false;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Tránh vòng lặp refresh
    if (_isRefreshing) {
      return handler.next(err);
    }

    _isRefreshing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (refreshToken == null || refreshToken.isEmpty) {
        _debugApiLog('[TokenRefresh] Missing refresh token. Session expired.');
        onSessionExpired?.call();
        return handler.next(err);
      }

      _debugApiLog(
        '[TokenRefresh] 401 received. Refreshing token for '
        '${err.requestOptions.method} ${err.requestOptions.uri}',
      );

      // Gọi refresh bằng Dio instance mới (không đi qua interceptor)
      final refreshDio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = response.data['access_token'] as String;

      // Lưu token mới
      await prefs.setString(_accessTokenKey, newAccessToken);
      _debugApiLog(
          '[TokenRefresh] Token refreshed. Retrying original request.');

      // Retry request gốc với token mới
      final requestOptions = err.requestOptions;
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryResponse = await _dio.fetch(requestOptions);
      return handler.resolve(retryResponse);
    } on DioException catch (refreshError) {
      final statusCode = refreshError.response?.statusCode;

      if (statusCode == 401 || statusCode == 403) {
        // Refresh token cũng hết hạn → buộc logout
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_accessTokenKey);
        await prefs.remove(_refreshTokenKey);
        _debugApiLog(
          '[TokenRefresh] Refresh failed with $statusCode. Session expired.',
        );
        onSessionExpired?.call();
      }

      _debugApiLog(
        '[TokenRefresh] Refresh request failed: ${refreshError.message}',
      );
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}

/// Convert mọi `DioException` thành `AppException` với message tiếng Việt.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    if (response != null) {
      final data = response.data;
      String message = 'Có lỗi xảy ra, vui lòng thử lại';

      if (data is Map<String, dynamic> && data.containsKey('error')) {
        message = data['error'] as String;
      }

      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: AppException(message, statusCode: response.statusCode),
        ),
      );
      return;
    }

    // Lỗi kết nối mạng
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          type: err.type,
          error: const AppException('Không thể kết nối máy chủ'),
        ),
      );
      return;
    }

    handler.next(err);
  }
}

void _debugApiLog(String message) {
  AppLogger.debug(message);
}

Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
  return headers.map((key, value) {
    if (key.toLowerCase() == 'authorization') {
      return MapEntry(key, _maskToken(value?.toString() ?? ''));
    }
    return MapEntry(key, value);
  });
}

Object? _sanitizeData(Object? data) {
  if (data is Map) {
    return data.map((key, value) {
      final keyText = key.toString().toLowerCase();
      if (keyText.contains('password') ||
          keyText.contains('token') ||
          keyText == 'authorization') {
        return MapEntry(key, _maskToken(value?.toString() ?? ''));
      }
      return MapEntry(key, _sanitizeData(value));
    });
  }

  if (data is List) {
    return data.map(_sanitizeData).toList();
  }

  return data;
}

String _maskToken(String value) {
  if (value.isEmpty) return '';
  if (value.startsWith('Bearer ')) {
    return 'Bearer ${_maskToken(value.substring(7))}';
  }
  if (value.length <= 10) return '***';
  return '${value.substring(0, 6)}...${value.substring(value.length - 4)}';
}
