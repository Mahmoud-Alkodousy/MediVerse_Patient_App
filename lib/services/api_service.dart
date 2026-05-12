import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      'https://subrhombical-akilah-interproglottidal.ngrok-free.dev';

  static String? _token;
  static Map<String, dynamic>? _user;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': '1',
    'User-Agent': 'MediVerseApp/1.0',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Auth ──────────────────────────────────
  static Future<Map<String, dynamic>> loginWithNationalId(String nationalId) async {
    final res = await http.post(
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
  }

  static Future<Map<String, dynamic>> loginWithFace(File imageFile) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/check-face'));
    req.headers['ngrok-skip-browser-warning'] = 'true';
    if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
    req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    final stream = await req.send();
    final res = await http.Response.fromStream(stream);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['exists'] == true && data['patient'] != null) {
        final nid = data['patient']['national_id'];
        if (nid != null && nid.toString().isNotEmpty) {
          return await loginWithNationalId(nid);
        }
      }
      throw Exception(data['message'] ?? 'لم يتم التعرف على الوجه');
    }
    throw Exception('فشل التعرف على الوجه');
  }

  // ── Patient ───────────────────────────────
  static Future<Map<String, dynamic>> getPatientProfile(int patientId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/patients/$patientId'),
      headers: _headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('فشل تحميل البيانات');
  }

  // ── Queue ─────────────────────────────────
  static Future<Map<String, dynamic>> getActiveQueue(int patientId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/appointments/queue/patient/$patientId/active'),
      headers: _headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('فشل تحميل الطابور');
  }

  // ── Notifications ─────────────────────────
  static Future<Map<String, dynamic>> getNotifications(int patientId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/appointments/queue/notifications/$patientId'),
      headers: _headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('فشل تحميل الإشعارات');
  }

  // ── Session ───────────────────────────────
  static Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userStr = prefs.getString('user');
    if (_token != null && userStr != null) {
      _user = jsonDecode(userStr);
      return true;
    }
    return false;
  }

  static Map<String, dynamic>? get currentUser => _user;
  static int? get patientId => _user?['user_id'];

  static Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }
}
