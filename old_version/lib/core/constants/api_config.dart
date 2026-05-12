class ApiConfig {
  // ✅ ngrok URL - غيّرها لو اتغيرت
  static const String baseUrl =
      'https://subrhombical-akilah-interproglottidal.ngrok-free.dev';

  // ── Endpoints ────────────────────────────────────────────
  static const String checkNationalId = '/check-national-id';
  static const String queueStatus     = '/queue/patient';

  // ── Headers ───────────────────────────────────────────────
  // ضروري لـ ngrok عشان يتخطى صفحة التحذير
  static const Map<String, String> ngrokHeaders = {
    'ngrok-skip-browser-warning': 'true',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Timeouts ─────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // ── Polling Interval ─────────────────────────────────────
  static const Duration refreshInterval = Duration(seconds: 15);
}
