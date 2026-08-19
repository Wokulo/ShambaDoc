import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException${statusCode != null ? "($statusCode)" : ""}: $message';
}

class ApiClient {
  static const String baseUrl = String.fromEnvironment(
    'SHAMBADOC_API_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );
  static const _timeout = Duration(seconds: 10);

  static http.Client? _client;
  static Future<String?> Function()? _tokenProvider;
  static Future<String?> Function(bool)? _tokenRefresher;

  static void setClient(http.Client client) => _client = client;
  static void resetClient() => _client = null;
  static void setTokenProvider(Future<String?> Function() provider) => _tokenProvider = provider;
  static void setTokenRefresher(Future<String?> Function(bool forceRefresh) refresher) => _tokenRefresher = refresher;
  static void resetTokenProviders() {
    _tokenProvider = null;
    _tokenRefresher = null;
  }

  static http.Client get _httpClient => _client ?? http.Client();

  static Future<String?> _getToken({bool forceRefresh = false}) async {
  if (forceRefresh && _tokenRefresher != null) return _tokenRefresher!(forceRefresh);
  if (_tokenProvider != null) return _tokenProvider!();
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    return await user.getIdToken(forceRefresh);
  }
  return null;
}

  static Future<Map<String, String>> _authHeaders({bool requiresAuth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await _getToken();
      if (token == null) {
        throw const ApiException('No authenticated user', statusCode: 401);
      }
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<http.Response> _executeWithAuth(
    Future<http.Response> Function(Map<String, String>) request,
    bool requiresAuth,
  ) async {
    final headers = await _authHeaders(requiresAuth: requiresAuth);
    var response = await request(headers).timeout(_timeout);

    if (requiresAuth && response.statusCode == 401) {
      final token = await _getToken(forceRefresh: true);
      if (token != null) {
        final newHeaders = await _authHeaders(requiresAuth: true);
        response = await request(newHeaders).timeout(_timeout);
      }
      if (response.statusCode == 401) {
        throw const ApiException('Authentication failed after token refresh', statusCode: 401);
      }
    }

    return response;
  }

  static Future<http.Response> get(
    String path, {
    bool requiresAuth = false,
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParameters);
    return _executeWithAuth((headers) => _httpClient.get(uri, headers: headers), requiresAuth);
  }

  static Future<http.Response> post(
    String path, {
    bool requiresAuth = false,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    return _executeWithAuth((headers) => _httpClient.post(uri, headers: headers, body: body), requiresAuth);
  }

  static Future<http.Response> put(
    String path, {
    bool requiresAuth = false,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    return _executeWithAuth((headers) => _httpClient.put(uri, headers: headers, body: body), requiresAuth);
  }

  static Future<http.Response> patch(
    String path, {
    bool requiresAuth = false,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    return _executeWithAuth((headers) => _httpClient.patch(uri, headers: headers, body: body), requiresAuth);
  }

  static Future<http.Response> delete(
    String path, {
    bool requiresAuth = false,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    return _executeWithAuth((headers) => _httpClient.delete(uri, headers: headers, body: body), requiresAuth);
  }

  static Future<String?> getAuthToken() async {
    return _getToken();
  }

  static bool get isAuthenticated {
    final user = FirebaseAuth.instance.currentUser;
    return user != null;
  }
}
