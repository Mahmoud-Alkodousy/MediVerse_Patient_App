import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      'https://subrhombical-akilah-interproglottidal.ngrok-free.dev';

  static String? _token;
  static Map<String, dynamic>? _user;

  static http.Client _buildClient() {
    final httpClient = HttpClient();
    httpClient.badCertificateCallback = (cert, host, port) => true;
    return IOClient(httpClient);
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
    'User-Agent': 'MediVerseApp/1.0',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<Map<String, dynamic>> loginWithNationalId(String nationalId) async {
    final client = _buildClient();
    try {
      final res = await client.post(
        Uri.parse('$baseUrl/auth/patient-login'),
        headers: _headers,
        body: jsonEncode({'national_id': nationalId}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['access_token'];
        _user = data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', jsonEncode(_user));
        return data;
      }
      final err = jsonDecode(res.body);
      throw Exception(err['detail'] ?? 'فشل تسجيل الدخول');
    } finally {
      client.close();
    }
  }

  // باقي الـ methods زي ما هي بس استبدل http.get/post بـ client.get/post
  static Future<Map<String, dynamic>> getPatientProfile(int patientId) async {
    final client = _buildClient();
    try {
      final res = await client.get(
        Uri.parse('$baseUrl/patients/$patientId'),
        headers: _headers,
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception('فشل تحميل البيانات');
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> getActiveQueue(int patientId) async {
    final client = _buildClient();
    try {
      final res = await client.get(
        Uri.parse('$baseUrl/appointments/queue/patient/$patientId/active'),
        headers: _headers,
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception('فشل تحميل الطابور');
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>> getNotifications(int patientId) async {
    final client = _buildClient();
    try {
      final res = await client.get(
        Uri.parse('$baseUrl/appointments/queue/notifications/$patientId'),
        headers: _headers,
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      throw Exception('فشل تحميل الإشعارات');
    } finally {
      client.close();
    }
  }
