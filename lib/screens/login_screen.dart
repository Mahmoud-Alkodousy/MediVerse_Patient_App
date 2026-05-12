import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _tab = 0; // 0=face, 1=nid
  bool _loading = false;
  String? _error;
  final _nidController = TextEditingController();

  Future<void> _loginWithFace() async {
    setState(() { _loading = true; _error = null; });
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );
      if (photo == null) {
        setState(() => _loading = false);
        return;
      }
      await ApiService.loginWithFace(File(photo.path));
      if (mounted) Navigator.pushReplacementNamed(context, '/tracking');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithNationalId() async {
    final nid = _nidController.text.trim();
    if (nid.length != 14) {
      setState(() => _error = 'الرقم القومي لازم يكون 14 رقم');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.loginWithNationalId(nid);
      if (mounted) Navigator.pushReplacementNamed(context, '/tracking');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F5FA), Color(0xFFE3EDF7)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 50),

                // Logo
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A3A5C), Color(0xFF2D6AA0)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A3A5C).withOpacity(0.3),
                        blurRadius: 20, offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text('✦', style: TextStyle(fontSize: 32, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 14),
                Text('MediVerse',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF1A3A5C))),
                Text('تسجيل الدخول',
                    style: TextStyle(fontSize: 14, color: const Color(0xFF6B839E), fontWeight: FontWeight.w600)),
                const SizedBox(height: 32),

                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(children: [
                    _tabBtn(0, '📷', 'التعرف بالوجه'),
                    _tabBtn(1, '🪪', 'الرقم القومي'),
                  ]),
                ),
                const SizedBox(height: 28),

                // Content
                if (_tab == 0) _buildFaceTab() else _buildNidTab(),

                // Error
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(children: [
                      const Text('⚠️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_error!,
                          style: TextStyle(fontSize: 13, color: const Color(0xFFDC2626), fontWeight: FontWeight.w600))),
                    ]),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(int idx, String emoji, String label) {
    final sel = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _tab = idx; _error = null; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF1A3A5C) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(emoji, style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? Colors.white : const Color(0xFF6B839E))),
          ]),
        ),
      ),
    );
  }

  Widget _buildFaceTab() {
    return Column(children: [
      // Face illustration
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF4FF),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Center(child: Text('📷', style: TextStyle(fontSize: 48))),
          ),
          const SizedBox(height: 20),
          Text('تسجيل الدخول بالوجه', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1A3A5C))),
          const SizedBox(height: 6),
          Text('سيتم فتح الكاميرا لالتقاط صورة', style: TextStyle(fontSize: 12, color: const Color(0xFF94A3B8))),
        ]),
      ),
      const SizedBox(height: 20),
      _actionButton(
        onPressed: _loading ? null : _loginWithFace,
        icon: Icons.camera_alt_rounded,
        label: _loading ? 'جاري التعرف...' : 'فتح الكاميرا والتقاط',
        loading: _loading,
      ),
    ]);
  }

  Widget _buildNidTab() {
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: const Color(0xFFEBF4FF), borderRadius: BorderRadius.circular(20)),
            child: const Center(child: Text('🪪', style: TextStyle(fontSize: 40))),
          ),
          const SizedBox(height: 20),
          Text('أدخل الرقم القومي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1A3A5C))),
          const SizedBox(height: 6),
          Text('الرقم المكون من 14 رقم', style: TextStyle(fontSize: 12, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 24),
          TextField(
            controller: _nidController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 14,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF1A3A5C), letterSpacing: 3),
            decoration: InputDecoration(
              counterText: '',
              hintText: '• • • • • • • • • • • • • •',
              hintStyle: TextStyle(fontSize: 20, color: const Color(0xFFCBD5E1), letterSpacing: 3),
              filled: true, fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4A90C8), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      _actionButton(
        onPressed: _loading ? null : _loginWithNationalId,
        icon: Icons.login_rounded,
        label: _loading ? 'جاري الدخول...' : 'تسجيل الدخول',
        loading: _loading,
      ),
    ]);
  }

  Widget _actionButton({VoidCallback? onPressed, required IconData icon, required String label, bool loading = false}) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A3A5C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: const Color(0xFF1A3A5C).withOpacity(0.3),
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 22),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
      ),
    );
  }
}
