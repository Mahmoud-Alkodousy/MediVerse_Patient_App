import 'package:flutter/material.dart';

import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  double _textOpacity = 0;
  double _loaderOpacity = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5)),
    );
    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _controller.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _textOpacity = 1);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _loaderOpacity = 1);
    await Future.delayed(const Duration(milliseconds: 1500));

    final hasSession = await ApiService.restoreSession();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, hasSession ? '/tracking' : '/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1F33), Color(0xFF1A3A5C), Color(0xFF1E4D7B)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A90C8).withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text('✦',
                            style: TextStyle(
                                fontSize: 48, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              AnimatedOpacity(
                opacity: _textOpacity,
                duration: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    Text(
                      'MediVerse',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'متابعة دورك في المستشفى',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),

              // Loader
              AnimatedOpacity(
                opacity: _loaderOpacity,
                duration: const Duration(milliseconds: 400),
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
