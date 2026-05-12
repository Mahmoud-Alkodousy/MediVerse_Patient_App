import 'package:dio/dio.dart';
import '../core/constants/api_config.dart';
import '../models/patient.dart';
import '../models/queue_status.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl:        ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers:        ApiConfig.ngrokHeaders,
    ),
  );

  // ── تسجيل الدخول بالرقم القومي ───────────────────────────
  static Future<Patient?> checkNationalId(String nationalId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.checkNationalId}/$nationalId',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // يدعم الـ format: { exists: true, patient: {...} }
        // أو مباشرةً بيانات المريض
        if (data is Map<String, dynamic>) {
          if (data['exists'] == true && data['patient'] != null) {
            return Patient.fromJson(data['patient']);
          } else if (data['id'] != null) {
            return Patient.fromJson(data);
          }
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('الرقم القومي غير مسجّل في النظام');
      }
      throw Exception('تعذّر الاتصال بالسيرفر');
    } catch (e) {
      throw Exception('حدث خطأ غير متوقع');
    }
  }

  // ── حالة الدور ────────────────────────────────────────────
  static Future<QueueStatus?> getQueueStatus(int patientId) async {
    try {
      final response = await _dio.get(
        '${ApiConfig.queueStatus}/$patientId/active',
      );

      if (response.statusCode == 200 && response.data != null) {
        return QueueStatus.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception('تعذّر الاتصال بالسيرفر');
    }
  }
}
