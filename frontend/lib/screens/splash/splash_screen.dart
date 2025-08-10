import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _rotate = Tween<double>(
      begin: -0.15,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo));
    _controller.forward();
    // Navegação após pequena espera (pode ajustar depois para checar token)
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/register');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _decorativeCircle({
    required double size,
    required Alignment align,
    double opacity = .06,
  }) {
    return Align(
      alignment: align,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(opacity),
              Colors.white.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient de fundo
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6C63FF),
                  Color(0xFF5146D9),
                  Color(0xFF4036B5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Círculos decorativos
          _decorativeCircle(
            size: 280,
            align: const Alignment(-1.1, -1.0),
            opacity: 0.09,
          ),
          _decorativeCircle(
            size: 200,
            align: const Alignment(1.1, -0.8),
            opacity: 0.07,
          ),
          _decorativeCircle(
            size: 260,
            align: const Alignment(1.2, 1.1),
            opacity: 0.08,
          ),
          // Conteúdo central
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Opacity(
                  opacity: _fade.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: _rotate.value * math.pi,
                          child: Hero(
                            tag: 'app_icon',
                            child: Container(
                              width: 140,
                              height: 140,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Image.asset('assets/icons/icon.png'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'TalkTo',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Conecte-se em tempo real',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            letterSpacing: .5,
                          ),
                        ),
                        const SizedBox(height: 36),
                        SizedBox(
                          width: 54,
                          height: 54,
                          child: CircularProgressIndicator(
                            strokeWidth: 5,
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                            backgroundColor: Colors.white.withOpacity(0.25),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Versão / créditos (opcional)
          const Positioned(
            bottom: 18,
            right: 18,
            child: Text(
              'v1.0.0',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
