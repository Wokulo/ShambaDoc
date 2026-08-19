import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shambadoc/services/api_client.dart';

class _FakeClient implements http.Client {
  int requestCount = 0;
  List<int> statusCodes = [];
  Map<String, String>? lastHeaders;

  @override
  void close() {}

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    lastHeaders = headers;
    final statusCode = statusCodes[requestCount.clamp(0, statusCodes.length - 1)];
    requestCount++;
    return http.Response(jsonEncode({'success': true}), statusCode);
  }

  @override
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    lastHeaders = headers;
    final statusCode = statusCodes[requestCount.clamp(0, statusCodes.length - 1)];
    requestCount++;
    return http.Response(jsonEncode({'success': true}), statusCode);
  }

  @override
  Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    lastHeaders = headers;
    final statusCode = statusCodes[requestCount.clamp(0, statusCodes.length - 1)];
    requestCount++;
    return http.Response(jsonEncode({'success': true}), statusCode);
  }

  @override
  Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    lastHeaders = headers;
    final statusCode = statusCodes[requestCount.clamp(0, statusCodes.length - 1)];
    requestCount++;
    return http.Response(jsonEncode({'success': true}), statusCode);
  }

  @override
  Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    lastHeaders = headers;
    final statusCode = statusCodes[requestCount.clamp(0, statusCodes.length - 1)];
    requestCount++;
    return http.Response(jsonEncode({'success': true}), statusCode);
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) async => throw UnimplementedError();

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) async => throw UnimplementedError();

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) async => throw UnimplementedError();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async => throw UnimplementedError();
}

void main() {
  group('ApiClient', () {
    setUp(() {
      ApiClient.resetClient();
      ApiClient.resetTokenProviders();
    });

    tearDown(() {
      ApiClient.resetClient();
      ApiClient.resetTokenProviders();
    });

    test('authenticated request includes Authorization header', () async {
      final client = _FakeClient()..statusCodes = [200];
      ApiClient.setClient(client);
      ApiClient.setTokenProvider(() async => 'fake-firebase-token');

      final response = await ApiClient.get('/test', requiresAuth: true);
      expect(response.statusCode, 200);
      expect(client.lastHeaders?['Authorization'], 'Bearer fake-firebase-token');
      expect(client.lastHeaders?['Content-Type'], 'application/json');
    });

    test('unauthenticated protected request fails appropriately', () async {
      final client = _FakeClient()..statusCodes = [200];
      ApiClient.setClient(client);
      ApiClient.setTokenProvider(() async => null);

      try {
        await ApiClient.get('/test', requiresAuth: true);
        fail('Expected ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 401);
      }
    });

    test('401 triggers one token refresh and retry', () async {
      final client = _FakeClient()..statusCodes = [401, 200];
      ApiClient.setClient(client);
      ApiClient.setTokenProvider(() async => 'first-token');

      final response = await ApiClient.get('/test', requiresAuth: true);
      expect(response.statusCode, 200);
      expect(client.requestCount, 2);
    });

    test('second 401 does not create an infinite loop', () async {
      final client = _FakeClient()..statusCodes = [401, 401];
      ApiClient.setClient(client);
      ApiClient.setTokenProvider(() async => 'token');

      try {
        await ApiClient.get('/test', requiresAuth: true);
        fail('Expected ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 401);
      }
      expect(client.requestCount, 2);
    });

    test('public requests work without authentication', () async {
      final client = _FakeClient()..statusCodes = [200];
      ApiClient.setClient(client);
      ApiClient.setTokenProvider(() async => null);

      final response = await ApiClient.get('/public');
      expect(response.statusCode, 200);
      expect(client.lastHeaders?.containsKey('Authorization'), isFalse);
      expect(client.lastHeaders?['Content-Type'], 'application/json');
    });

    test('API errors are converted to ApiException', () async {
      final client = _FakeClient()..statusCodes = [401];
      ApiClient.setClient(client);
      ApiClient.setTokenProvider(() async => 'token');

      try {
        await ApiClient.get('/test', requiresAuth: true);
        fail('Expected ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, 401);
      }
    });

    test('non-auth errors are not retried', () async {
      final client = _FakeClient()..statusCodes = [500];
      ApiClient.setClient(client);
      ApiClient.setTokenProvider(() async => 'token');

      final response = await ApiClient.get('/test', requiresAuth: true);
      expect(response.statusCode, 500);
      expect(client.requestCount, 1);
    });
  });
}
