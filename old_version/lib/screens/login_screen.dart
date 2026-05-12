import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../services/api_service.dart';
import '../models/patient.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _controller  = TextEditingController();
  final _formKey     = GlobalKey<FormState>();
  bool  _isLoading   = false;
  bool  _hasError    = false;
  String _errorMsg   = '';

  late final AnimationController _bgAnim;
  late final AnimationController _entryAnim;
  late final AnimationController _pulseAnim;
  late final AnimationController _orbitAnim;

  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _entryAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _orbitAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _fadeIn = CurvedAnimation(
      parent: _entryAnim,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end:   Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryAnim,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(
      parent: _entryAnim,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ));

    _entryAnim.forward();
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _entryAnim.dispose();
    _pulseAnim.dispose();
    _orbitAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _hasError = false; });

    try {
      final patient = await ApiService.checkNationalId(_controller.text.trim());
      if (!mounted) return;

      if (patient != null) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, __) => HomeScreen(patient: patient),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      } else {
        setState(() {
          _hasError = true;
          _errorMsg = AppStrings.notFoundError;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMsg = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          // ── Animated Background ──────────────────────────
          _buildBackground(),

          // ── Orbiting Particles ───────────────────────────
          _buildOrbitingParticles(),

          // ── Main Content ─────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      children: [
                        SizedBox(height: 40.h),
                        _buildLogo(),
                        SizedBox(height: 40.h),
                        _buildForm(),
                        SizedBox(height: 40.h),
                        _buildFooter(),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Animated Gradient Background ───────────────────────────
  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (_, __) {
        final t = _bgAnim.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [AppColors.bgDeep, AppColors.bgSurface, AppColors.bgDeep],
              begin: Alignment(-1 + t * 0.5, -1),
              end:   Alignment(1 - t * 0.5,  1),
            ),
          ),
          child: Stack(
            children: [
              // Glow top-right
              Positioned(
                top:   -100 + t * 40,
                right: -80,
                child: Container(
                  width:  280.w,
                  height: 280.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x2500D4FF), Colors.transparent],
                    ),
                  ),
                ),
              ),
              // Glow bottom-left
              Positioned(
                bottom: -80 + t * 30,
                left:   -60,
                child: Container(
                  width:  240.w,
                  height: 240.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x207C3AED), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Orbiting dots ───────────────────────────────────────────
  Widget _buildOrbitingParticles() {
    return AnimatedBuilder(
      animation: _orbitAnim,
      builder: (_, __) {
        final angle = _orbitAnim.value * 2 * math.pi;
        final cx    = MediaQuery.of(context).size.width  / 2;
        final cy    = 220.h;
        final r     = 80.w;
        return Stack(
          children: [
            for (int i = 0; i < 3; i++)
              Positioned(
                left: cx + r * math.cos(angle + i * 2.1) - 3,
                top:  cy + r * 0.4 * math.sin(angle + i * 2.1) - 3,
                child: Opacity(
                  opacity: 0.4 + 0.3 * math.sin(angle + i).abs(),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape:  BoxShape.circle,
                      color:  i == 0 ? AppColors.primary : AppColors.accentGlow,
                      boxShadow: [
                        BoxShadow(
                          color:     i == 0 ? AppColors.primary : AppColors.accentGlow,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Logo Section ────────────────────────────────────────────
  Widget _buildLogo() {
    return ScaleTransition(
      scale: _scale,
      child: Column(
        children: [
          // Pulsing ring + icon
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer pulse ring
                  Container(
                    width:  100.w + 20 * _pulseAnim.value,
                    height: 100.w + 20 * _pulseAnim.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(
                          0.15 + 0.15 * _pulseAnim.value,
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),
                  // Mid ring
                  Container(
                    width:  90.w,
                    height: 90.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child!,
                ],
              );
            },
            child: Container(
              width:  72.w,
              height: 72.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color:      AppColors.primary.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color:      AppColors.accent.withOpacity(0.3),
                    blurRadius: 50,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.local_hospital_rounded,
                color: Colors.white,
                size: 36.sp,
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // App Name
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              AppStrings.appName,
              style: TextStyle(
                fontSize:   44.sp,
                fontWeight: FontWeight.w900,
                color:      Colors.white,
                letterSpacing: 3,
              ),
            ),
          ),
          SizedBox(height: 8.h),

          Text(
            AppStrings.appTagline,
            style: TextStyle(
              fontSize:      14.sp,
              color:         AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Login Form ──────────────────────────────────────────────
  Widget _buildForm() {
    return Container(
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        color:        AppColors.glassWhite,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset:     const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              AppStrings.welcomeBack,
              style: TextStyle(
                fontSize:   26.sp,
                fontWeight: FontWeight.bold,
                color:      AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              AppStrings.loginSubtitle,
              style: TextStyle(
                fontSize: 14.sp,
                color:    AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 28.h),

            // Input
            _buildInput(),
            SizedBox(height: 12.h),

            // Error
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0),
              secondChild: _buildError(),
              crossFadeState: _hasError
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            SizedBox(height: 20.h),

            // Button
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الرقم القومي',
          style: TextStyle(
            fontSize:   12.sp,
            fontWeight: FontWeight.w600,
            color:      AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller:    _controller,
          keyboardType:  TextInputType.number,
          maxLength:     14,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize:      18.sp,
            fontWeight:    FontWeight.w600,
            color:         AppColors.textPrimary,
            letterSpacing: 2,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) {
            if (_hasError) setState(() => _hasError = false);
          },
          validator: (v) {
            if (v == null || v.isEmpty) return AppStrings.enterNatId;
            if (v.length != 14)        return AppStrings.nationalIdErr;
            return null;
          },
          decoration: InputDecoration(
            hintText:  AppStrings.nationalIdHint,
            hintStyle: TextStyle(
              color:    AppColors.textMuted,
              fontSize: 14.sp,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 16.w, right: 12.w),
              child: Icon(
                Icons.credit_card_rounded,
                color: AppColors.primary,
                size:  22.sp,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(),
            counterText: '',
            filled:     true,
            fillColor:  AppColors.bgDeep.withOpacity(0.6),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical:   18.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:   const BorderSide(color: AppColors.textMuted, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:   const BorderSide(color: AppColors.textMuted, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:   const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:   const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:   const BorderSide(color: AppColors.error, width: 2),
            ),
            errorStyle: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color:        AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
        border:       Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _errorMsg,
              style: TextStyle(color: AppColors.error, fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width:  double.infinity,
      height: 56.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient:     _isLoading ? null : AppColors.primaryGradient,
          color:        _isLoading ? AppColors.textMuted.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color:      AppColors.primary.withOpacity(0.4),
                    blurRadius: 20,
                    offset:     const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor:  Colors.transparent,
            shadowColor:      Colors.transparent,
            foregroundColor:  Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width:  22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(
                    color:       Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.login,
                      style: TextStyle(
                        fontSize:   18.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.arrow_forward_rounded, size: 20.sp),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Footer ──────────────────────────────────────────────────
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          'متصل بالسيرفر',
          style: TextStyle(
            fontSize: 12.sp,
            color:    AppColors.textSecondary,
          ),
        ),
        SizedBox(width: 16.w),
        Container(width: 1, height: 12, color: AppColors.textMuted),
        SizedBox(width: 16.w),
        Icon(Icons.lock_outline_rounded, size: 12.sp, color: AppColors.textMuted),
        SizedBox(width: 4.w),
        Text(
          'اتصال آمن',
          style: TextStyle(
            fontSize: 12.sp,
            color:    AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
