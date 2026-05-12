import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../models/patient.dart';
import '../models/queue_status.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final Patient patient;
  const HomeScreen({Key? key, required this.patient}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  QueueStatus? _queueStatus;
  bool         _isLoading = true;
  bool         _hasError  = false;
  DateTime?    _lastUpdate;
  Timer?       _refreshTimer;

  bool _notifSent1 = false;
  bool _notifSent2 = false;

  late final AnimationController _entryAnim;
  late final AnimationController _pulseAnim;
  late final AnimationController _counterAnim;
  late final AnimationController _rotateAnim;
  late final AnimationController _bgAnim;

  late Animation<double> _fadeIn;
  late Animation<double> _counterValue;

  int _prevPatientsAhead = -1;

  @override
  void initState() {
    super.initState();
    NotificationService.initialize();

    _entryAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900),
    )..forward();

    _pulseAnim = AnimationController(
      vsync: this, duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _counterAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    );

    _rotateAnim = AnimationController(
      vsync: this, duration: const Duration(seconds: 20),
    )..repeat();

    _bgAnim = AnimationController(
      vsync: this, duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _entryAnim, curve: Curves.easeOut);
    _counterValue = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _counterAnim, curve: Curves.easeOutCubic),
    );

    _loadData();
    _startTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _entryAnim.dispose();
    _pulseAnim.dispose();
    _counterAnim.dispose();
    _rotateAnim.dispose();
    _bgAnim.dispose();
    super.dispose();
  }

  void _startTimer() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadData(silent: true),
    );
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() { _isLoading = true; _hasError = false; });

    try {
      final status = await ApiService.getQueueStatus(widget.patient.id);

      if (!mounted) return;

      // Animate counter if value changed
      if (status != null && status.patientsAhead != _prevPatientsAhead) {
        _counterAnim.forward(from: 0);
        _prevPatientsAhead = status.patientsAhead;
      }

      setState(() {
        _queueStatus = status;
        _lastUpdate  = DateTime.now();
        _isLoading   = false;
        _hasError    = false;
      });

      if (status != null) _checkNotifications(status);
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _hasError = silent ? _hasError : true; });
    }
  }

  void _checkNotifications(QueueStatus s) {
    if (s.patientsAhead == 1 && !_notifSent1) {
      NotificationService.notifyTurnSoon(s.doctorName, s.locationText);
      _notifSent1 = true;
    }
    if (s.isCalled && !_notifSent2) {
      NotificationService.notifyYourTurn(s.doctorName, s.locationText);
      _notifSent2 = true;
    }
  }

  String _timeSince() {
    if (_lastUpdate == null) return '';
    final d = DateTime.now().difference(_lastUpdate!);
    if (d.inSeconds < 60)  return 'منذ ${d.inSeconds} ثانية';
    if (d.inMinutes < 60)  return 'منذ ${d.inMinutes} دقيقة';
    return 'منذ ${d.inHours} ساعة';
  }

  Color get _statusColor {
    switch (_queueStatus?.status) {
      case 'called':          return AppColors.warning;
      case 'in_consultation': return AppColors.success;
      case 'completed':       return AppColors.textMuted;
      default:                return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: Stack(
        children: [
          _buildBg(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: _isLoading && _queueStatus == null
                        ? _buildInitialLoading()
                        : _buildBody(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ──────────────────────────────────────────────
  Widget _buildBg() {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (_, __) {
        final t = _bgAnim.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [AppColors.bgDeep, AppColors.bgSurface, AppColors.bgDeep],
              begin: Alignment(-0.5 + t * 0.3, -1),
              end:   Alignment(0.5 - t * 0.3,  1),
            ),
          ),
          child: Stack(children: [
            Positioned(
              top: -120 + t * 40, right: -80,
              child: _glowCircle(260.w, AppColors.primary, 0.15),
            ),
            Positioned(
              bottom: -100 + t * 30, left: -60,
              child: _glowCircle(220.w, AppColors.accent, 0.12),
            ),
          ]),
        );
      },
    );
  }

  Widget _glowCircle(double size, Color color, double opacity) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }

  // ── Top Bar ─────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
      child: Row(
        children: [
          // Avatar + name
          Container(
            width: 42.w, height: 42.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12)],
            ),
            child: Center(
              child: Text(
                widget.patient.fullName.isNotEmpty
                    ? widget.patient.fullName[0]
                    : 'م',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً، ${widget.patient.fullName.split(' ').first}',
                  style: TextStyle(
                    fontSize:   16.sp,
                    fontWeight: FontWeight.bold,
                    color:      AppColors.textPrimary,
                  ),
                ),
                Text(
                  'متابعة الدور في الوقت الفعلي',
                  style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Refresh
          _isLoading
              ? SizedBox(
                  width: 18.w, height: 18.w,
                  child: const CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2,
                  ),
                )
              : _iconBtn(Icons.refresh_rounded, () => _loadData()),
          SizedBox(width: 8.w),
          _iconBtn(Icons.logout_rounded, _confirmLogout),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38.w, height: 38.w,
        decoration: BoxDecoration(
          color:        AppColors.glassWhite,
          borderRadius: BorderRadius.circular(10.r),
          border:       Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18.sp),
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────
  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () => _loadData(),
      color:     AppColors.primary,
      backgroundColor: AppColors.bgCard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 4.h),
            _buildPatientCard(),
            SizedBox(height: 16.h),
            _queueStatus != null ? _buildQueueSection() : _buildNoBooking(),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48.w, height: 48.w,
            child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2,
              backgroundColor: AppColors.primary.withOpacity(0.1),
            ),
          ),
          SizedBox(height: 16.h),
          Text('جاري التحميل...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
        ],
      ),
    );
  }

  // ── Patient Card ────────────────────────────────────────────
  Widget _buildPatientCard() {
    final p = widget.patient;
    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                child: Icon(Icons.person_rounded, color: Colors.white, size: 18.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                'البيانات الشخصية',
                style: TextStyle(
                  fontSize: 12.sp, fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary, letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            p.fullName,
            style: TextStyle(
              fontSize: 22.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            p.nationalId,
            style: TextStyle(
              fontSize: 13.sp, color: AppColors.textMuted, letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _chip(Icons.water_drop_rounded, p.bloodTypeDisplay, AppColors.error),
              SizedBox(width: 10.w),
              if (p.age != null) _chip(Icons.calendar_today_rounded, '${p.age} سنة', AppColors.primary),
              SizedBox(width: 10.w),
              _chip(Icons.person_outline_rounded, p.genderAr, AppColors.accentGlow),
            ],
          ),
          if (p.chronicDiseases.isNotEmpty) ...[
            SizedBox(height: 14.h),
            _divider(),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 6.h,
              children: p.chronicDiseases.map((d) => _tag(d)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border:       Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12.sp),
          SizedBox(width: 5.w),
          Text(text, style: TextStyle(color: color, fontSize: 12.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color:        AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6.r),
        border:       Border.all(color: AppColors.warning.withOpacity(0.2)),
      ),
      child: Text(label, style: TextStyle(color: AppColors.warning, fontSize: 11.sp)),
    );
  }

  // ── Queue Section ───────────────────────────────────────────
  Widget _buildQueueSection() {
    final s = _queueStatus!;
    return Column(
      children: [
        _buildQueueHero(s),
        SizedBox(height: 16.h),
        _buildInfoGrid(s),
        SizedBox(height: 16.h),
        _buildProgressTrack(s),
        SizedBox(height: 10.h),
        _buildLastUpdate(),
      ],
    );
  }

  // ── Queue Hero Card (أبرز عنصر) ────────────────────────────
  Widget _buildQueueHero(QueueStatus s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: AppColors.queueGradient,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color:      AppColors.primary.withOpacity(0.35),
            blurRadius: 30,
            offset:     const Offset(0, 10),
            spreadRadius: -5,
          ),
          BoxShadow(
            color:      AppColors.accent.withOpacity(0.2),
            blurRadius: 50,
            offset:     const Offset(0, 20),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative rotating ring
          Positioned(
            top: -30, right: -30,
            child: AnimatedBuilder(
              animation: _rotateAnim,
              builder: (_, __) => Transform.rotate(
                angle: _rotateAnim.value * 2 * math.pi,
                child: Container(
                  width: 100.w, height: 100.w,
                  decoration: BoxDecoration(
                    shape:  BoxShape.circle,
                    border: Border.all(
                      color:  Colors.white.withOpacity(0.08),
                      width:  1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -20, left: -20,
            child: AnimatedBuilder(
              animation: _rotateAnim,
              builder: (_, __) => Transform.rotate(
                angle: -_rotateAnim.value * 2 * math.pi,
                child: Container(
                  width: 80.w, height: 80.w,
                  decoration: BoxDecoration(
                    shape:  BoxShape.circle,
                    border: Border.all(
                      color:  Colors.white.withOpacity(0.06),
                      width:  1,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.medical_services_rounded, color: Colors.white, size: 18.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.doctorName,
                          style: TextStyle(
                            fontSize: 17.sp, fontWeight: FontWeight.bold, color: Colors.white,
                          ),
                        ),
                        Text(
                          s.specialtyAr ?? s.specialty ?? 'تخصص عام',
                          style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20.r),
                      border:       Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      s.statusLabel,
                      style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                '📍 ${s.locationText}',
                style: TextStyle(color: Colors.white60, fontSize: 12.sp),
              ),
              SizedBox(height: 24.h),

              // ── BIG Counter ─────────────────────────────
              Center(
                child: Column(
                  children: [
                    Text(
                      AppStrings.patientsAhead,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color:    Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    AnimatedBuilder(
                      animation: _counterValue,
                      builder: (_, __) {
                        return Text(
                          '${s.patientsAhead}',
                          style: TextStyle(
                            fontSize:   96.sp,
                            fontWeight: FontWeight.w900,
                            color:      Colors.white,
                            height:     0.9,
                            shadows: [
                              Shadow(
                                color:       Colors.black.withOpacity(0.3),
                                blurRadius:  20,
                                offset:      const Offset(0, 4),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Text(
                      AppStrings.patients,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color:    Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Estimated time
              Container(
                width:   double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
                decoration: BoxDecoration(
                  color:        Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14.r),
                  border:       Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, child) => Opacity(
                        opacity: 0.6 + 0.4 * _pulseAnim.value,
                        child: child,
                      ),
                      child: Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 18.sp),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${AppStrings.estimatedTime}: ~${s.estimatedWaitMinutes} ${AppStrings.minutes}',
                      style: TextStyle(
                        color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Info Grid ───────────────────────────────────────────────
  Widget _buildInfoGrid(QueueStatus s) {
    return Row(
      children: [
        Expanded(child: _infoTile(
          Icons.format_list_numbered_rounded,
          'رقمك في الطابور',
          '#${s.position}',
          AppColors.accent,
        )),
        SizedBox(width: 12.w),
        Expanded(child: _infoTile(
          Icons.schedule_rounded,
          'وقت الانضمام',
          '${s.joinTime.hour.toString().padLeft(2, '0')}:${s.joinTime.minute.toString().padLeft(2, '0')}',
          AppColors.primary,
        )),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value, Color color) {
    return _glass(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 10.h),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp)),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary, fontSize: 22.sp, fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress Track ──────────────────────────────────────────
  Widget _buildProgressTrack(QueueStatus s) {
    const total  = 10;
    final filled = (total - s.patientsAhead).clamp(0, total);
    final pct    = filled / total;

    return _glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.yourPosition,
                style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12.sp,
                  fontWeight: FontWeight.w600, letterSpacing: 0.5,
                ),
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: TextStyle(
                  color: AppColors.primary, fontSize: 12.sp, fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Segmented bar
          Row(
            children: List.generate(total, (i) {
              final active = i < filled;
              return Expanded(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300 + i * 50),
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  height: 6.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3.r),
                    gradient: active ? AppColors.primaryGradient : null,
                    color:    active ? null : AppColors.textMuted.withOpacity(0.2),
                    boxShadow: active
                        ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 4)]
                        : null,
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 10.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('بداية الطابور', style: TextStyle(color: AppColors.textMuted, fontSize: 10.sp)),
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape:  BoxShape.circle,
                      color:  AppColors.primary,
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.6), blurRadius: 6)],
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Text('أنت هنا', style: TextStyle(color: AppColors.primary, fontSize: 10.sp, fontWeight: FontWeight.bold)),
                ],
              ),
              Text('العيادة', style: TextStyle(color: AppColors.textMuted, fontSize: 10.sp)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdate() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
              shape:  BoxShape.circle,
              color:  AppColors.success.withOpacity(0.5 + 0.5 * _pulseAnim.value),
              boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 4)],
            ),
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          '${AppStrings.lastUpdate}: ${_timeSince()} • ${AppStrings.autoRefresh}',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp),
        ),
      ],
    );
  }

  // ── No Booking ───────────────────────────────────────────────
  Widget _buildNoBooking() {
    return _glass(
      padding: EdgeInsets.symmetric(vertical: 48.h, horizontal: 24.w),
      child: Column(
        children: [
          Container(
            width: 72.w, height: 72.w,
            decoration: BoxDecoration(
              shape:  BoxShape.circle,
              color:  AppColors.textMuted.withOpacity(0.08),
              border: Border.all(color: AppColors.textMuted.withOpacity(0.15)),
            ),
            child: Icon(Icons.event_busy_rounded, size: 32.sp, color: AppColors.textMuted),
          ),
          SizedBox(height: 20.h),
          Text(
            AppStrings.noBooking,
            style: TextStyle(
              fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            AppStrings.noBookingSub,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────
  Widget _glass({required Widget child, EdgeInsets? padding}) {
    return Container(
      width:   double.infinity,
      padding: padding ?? EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color:        AppColors.glassWhite,
        borderRadius: BorderRadius.circular(20.r),
        border:       Border.all(color: AppColors.glassBorder),
        boxShadow:    [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }

  Widget _divider() => Container(
    height: 1,
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Colors.transparent, AppColors.glassBorder, Colors.transparent]),
    ),
  );

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded, color: AppColors.error, size: 40.sp),
              SizedBox(height: 16.h),
              Text('تسجيل الخروج؟', style: TextStyle(color: AppColors.textPrimary, fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              Text('هل تريد الخروج من حسابك؟', style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.glassBorder),
                        foregroundColor: AppColors.textSecondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: const Text('خروج'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
