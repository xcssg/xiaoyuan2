import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'models.dart';

class ApiClient {
  ApiClient(this._prefs) : _token = _prefs.getString(_tokenKey);

  static const String _tokenKey = 'wszz_wall_token';

  final SharedPreferences _prefs;
  final http.Client _client = http.Client();
  String? _token;

  String? get token => _token;

  Future<void> setToken(String token) async {
    _token = token;
    await _prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _prefs.remove(_tokenKey);
  }

  String get _base {
    final value = kApiBaseUrl.trim();
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  Future<dynamic> get(String path) => _request('GET', path);

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _request('POST', path, body: body);

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) =>
      _request('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _request('DELETE', path);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_base$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
    };
    final encoded = body == null ? null : jsonEncode(body);

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 20));
          break;
        case 'POST':
          response = await _client.post(uri, headers: headers, body: encoded).timeout(const Duration(seconds: 20));
          break;
        case 'PATCH':
          response = await _client.patch(uri, headers: headers, body: encoded).timeout(const Duration(seconds: 20));
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: headers).timeout(const Duration(seconds: 20));
          break;
        default:
          throw StoreException('不支持的请求方式');
      }
    } on TimeoutException {
      throw StoreException('连接服务器超时，请检查网络后重试');
    } on SocketException {
      throw StoreException('无法连接服务器，请检查网络后重试');
    } on http.ClientException {
      throw StoreException('无法连接服务器，请检查网络后重试');
    }

    dynamic data;
    if (response.bodyBytes.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        data = null;
      }
    }

    if (response.statusCode >= 400) {
      final message = data is Map && data['error'] is String
          ? data['error'] as String
          : '请求失败（${response.statusCode}）';
      throw StoreException(message);
    }
    return data;
  }

  void dispose() {
    _client.close();
  }
}
