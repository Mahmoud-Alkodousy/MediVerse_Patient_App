import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _patient;
  Map<String, dynamic>? _queue;
  List<dynamic> _notifications = [];
  bool _loading = true;
  Timer? _pollTimer;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _loadData();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final pid = ApiService.patientId;
      if (pid == null) { if (mounted) Navigator.pushReplacementNamed(context, '/login'); return; }
      final res = await Future.wait([
        ApiService.getPatientProfile(pid),
        ApiService.getActiveQueue(pid),
        ApiService.getNotifications(pid),
      ]);
      if (mounted) setState(() {
        _patient = res[0]; _queue = res[1];
        _notifications = (res[2] as Map<String, dynamic>)['notifications'] ?? [];
        _loading = false;
      });
    } catch (e) {
      debugPrint('Load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    try {
      final pid = ApiService.patientId;
      if (pid == null) return;
      final res = await Future.wait([ApiService.getActiveQueue(pid), ApiService.getNotifications(pid)]);
      if (!mounted) return;
      final newQ = res[0] as Map<String, dynamic>;
      final wasMyTurn = _queue?['your_turn'] == true;
      final isMyTurn = newQ['your_turn'] == true;
      setState(() { _queue = newQ; _notifications = (res[1] as Map<String, dynamic>)['notifications'] ?? []; });
      if (!wasMyTurn && isMyTurn) _showTurnDialog();
    } catch (_) {}
  }

  void _showTurnDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(24)),
            child: const Center(child: Text('🔔', style: TextStyle(fontSize: 40)))),
          const SizedBox(height: 20),
          Text('جاء دورك!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFF15803D))),
          const SizedBox(height: 8),
          Text('توجه الآن إلى عيادة الطبيب', style: TextStyle(fontSize: 14, color: const Color(0xFF6B839E))),
          if (_queue != null) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('📍', style: TextStyle(fontSize: 16)), const SizedBox(width: 6),
                Text('الدور ${_queue!['floor_number'] ?? ''} — غرفة ${_queue!['room_number'] ?? ''}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1A3A5C))),
              ])),
          ],
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text('حاضر ✓', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          )),
        ]),
      ),
    );
  }

  void _logout() async {
    await ApiService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() { _pollTimer?.cancel(); _pulseCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF0F5FA), Color(0xFFE3EDF7)])),
        child: SafeArea(
          child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A5C)))
            : RefreshIndicator(
                onRefresh: _loadData, color: const Color(0xFF1A3A5C),
                child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildPatientCard(),
                  const SizedBox(height: 16),
                  if (_queue != null && _queue!['in_queue'] == true) ...[
                    _buildDoctorCard(),
                    const SizedBox(height: 16),
                    _buildQueueCard(),
                    const SizedBox(height: 16),
                  ] else _buildNoQueueCard(),
                  if (_notifications.isNotEmpty) ...[_buildNotificationsCard(), const SizedBox(height: 16)],
                  const SizedBox(height: 60),
                ]),
              ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = ApiService.currentUser?['name'] ?? '';
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('أهلاً 👋', style: TextStyle(fontSize: 14, color: const Color(0xFF6B839E))),
        Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1A3A5C))),
      ])),
      GestureDetector(onTap: _logout, child: Container(
        padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
        child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
      )),
    ]);
  }

  Widget _buildPatientCard() {
    if (_patient == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1A3A5C).withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEBF4FF), borderRadius: BorderRadius.circular(14)),
            child: const Center(child: Text('👤', style: TextStyle(fontSize: 22)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('بياناتك', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A3A5C))),
            Text(_patient!['full_name'] ?? '', style: TextStyle(fontSize: 12, color: const Color(0xFF6B839E))),
          ])),
        ]),
        const SizedBox(height: 16),
        _infoRow('🪪', 'الرقم القومي', _patient!['national_id'] ?? '—'),
        _infoRow('🩸', 'فصيلة الدم', _patient!['blood_type'] ?? '—'),
        _infoRow('📞', 'الهاتف', _patient!['phone_number'] ?? '—'),
        if ((_patient!['chronic_diseases'] ?? '').toString().isNotEmpty)
          _infoRow('🏥', 'أمراض مزمنة', _patient!['chronic_diseases']),
        if ((_patient!['allergies'] ?? '').toString().isNotEmpty)
          _infoRow('⚠️', 'حساسية', _patient!['allergies']),
      ]),
    );
  }

  Widget _infoRow(String emoji, String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
      Text(emoji, style: TextStyle(fontSize: 16)), const SizedBox(width: 10),
      Text('$label: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1A3A5C)), textAlign: TextAlign.end)),
    ]));
  }

  Widget _buildDoctorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A3A5C), Color(0xFF2D6AA0)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1A3A5C).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('🩺', style: TextStyle(fontSize: 26)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_queue!['doctor_name'] ?? '', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
            Text(_queue!['doctor_specialty_ar'] ?? _queue!['doctor_specialty'] ?? '', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ])),
          if (_queue!['doctor_rating'] != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 16), const SizedBox(width: 3),
              Text('${_queue!['doctor_rating']}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Text('📍', style: TextStyle(fontSize: 16)), const SizedBox(width: 8),
            Text('الدور ${_queue!['floor_number'] ?? '—'} — غرفة ${_queue!['room_number'] ?? '—'}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          ])),
      ]),
    );
  }

  Widget _buildQueueCard() {
    final yourTurn = _queue?['your_turn'] == true;
    final status = _queue?['queue_status'] ?? _queue?['status'] ?? 'waiting';
    final ahead = _queue?['people_ahead'] ?? _queue?['patients_ahead'] ?? 0;
    final wait = _queue?['estimated_wait_minutes'] ?? 0;
    final position = _queue?['queue_position'] ?? _queue?['position'] ?? 0;

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, child) => Transform.scale(scale: yourTurn ? 0.95 + (_pulseCtrl.value * 0.05) : 1.0, child: child),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: yourTurn ? const Color(0xFF15803D) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: yourTurn ? null : Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: [BoxShadow(
            color: yourTurn ? const Color(0xFF15803D).withOpacity(0.3) : const Color(0xFF1A3A5C).withOpacity(0.06),
            blurRadius: yourTurn ? 24 : 16, offset: const Offset(0, 6))]),
        child: Column(children: [
          if (yourTurn) ...[
            const Text('🔔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('جاء دورك!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 4),
            Text('توجه الآن إلى العيادة', style: TextStyle(fontSize: 14, color: Colors.white70)),
          ] else ...[
            // Position circle
            Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: LinearGradient(colors: status == 'called'
                ? [const Color(0xFFF59E0B), const Color(0xFFEF4444)]
                : [const Color(0xFF1A3A5C), const Color(0xFF4A90C8)]),
              boxShadow: [BoxShadow(color: const Color(0xFF1A3A5C).withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 6))]),
              child: Center(child: Text('#$position', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)))),
            const SizedBox(height: 20),
            // Status badge
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: status == 'called' ? const Color(0xFFFEF3C7) : status == 'in_progress' ? const Color(0xFFDCFCE7) : const Color(0xFFEBF4FF),
                borderRadius: BorderRadius.circular(20)),
              child: Text(
                status == 'called' ? '📢 تم نداؤك' : status == 'in_progress' ? '✅ جاري الكشف' : '⏳ في الانتظار',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: status == 'called' ? const Color(0xFFB45309) : status == 'in_progress' ? const Color(0xFF15803D) : const Color(0xFF1A3A5C)))),
            const SizedBox(height: 20),
            // Stats
            Row(children: [
              _statBox('👥', '$ahead', 'قبلك', const Color(0xFFF0F9FF), const Color(0xFF1A3A5C)),
              const SizedBox(width: 12),
              _statBox('⏱️', '$wait', 'دقيقة', const Color(0xFFFFF7ED), const Color(0xFFB45309)),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _statBox(String emoji, String value, String label, Color bg, Color tc) {
    return Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(emoji, style: TextStyle(fontSize: 22)), const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: tc)),
        Text(label, style: TextStyle(fontSize: 12, color: tc.withOpacity(0.7), fontWeight: FontWeight.w600)),
      ])));
  }

  Widget _buildNoQueueCard() {
    return Container(padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1A3A5C).withOpacity(0.04), blurRadius: 12)]),
      child: Column(children: [
        const Text('🏥', style: TextStyle(fontSize: 48)), const SizedBox(height: 16),
        Text('لا يوجد حجز حالياً', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1A3A5C))),
        const SizedBox(height: 6),
        Text('عند حجز موعد أو الانضمام للطابور\nستظهر بيانات المتابعة هنا',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: const Color(0xFF94A3B8), height: 1.6)),
      ]));
  }

  Widget _buildNotificationsCard() {
    return Container(padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF1A3A5C).withOpacity(0.04), blurRadius: 12)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🔔', style: TextStyle(fontSize: 20)), const SizedBox(width: 8),
          Text('الإشعارات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A3A5C))),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(10)),
            child: Text('${_notifications.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
        ]),
        const SizedBox(height: 12),
        ..._notifications.take(5).map((n) => Padding(padding: const EdgeInsets.only(bottom: 10),
          child: Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n['title'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1A3A5C))),
              const SizedBox(height: 3),
              Text(n['message'] ?? '', style: TextStyle(fontSize: 12, color: const Color(0xFF6B839E))),
            ])))),
      ]));
  }
}
