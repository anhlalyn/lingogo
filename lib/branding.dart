import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48});
  final double size;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .24),
    child: Image.asset(
      'assets/branding/lingogo_logo.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Logo LingoGo',
    ),
  );
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.size = 32, this.fontSize = 26});
  final double size, fontSize;
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: size),
        const SizedBox(width: 10),
        Text(
          'LingoGo',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF7566E8),
            letterSpacing: -.7,
          ),
        ),
      ],
    ),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    super.key,
    this.failed = false,
    this.onRetry,
    this.message = 'Đang chuẩn bị hành trình của bạn…',
  });
  final bool failed;
  final VoidCallback? onRetry;
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F7FF),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Positioned(
              right: -100,
              top: -100,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEFEAFF),
                ),
              ),
            ),
            Positioned(
              left: -80,
              bottom: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEFEAFF),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: .92 + value * .08,
                      child: child,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(38),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x247566E8),
                              blurRadius: 36,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: const AppLogo(size: 144),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'LingoGo',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7566E8),
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Mở lời chào. Mở thế giới.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          color: Color(0xFF58516E),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (failed) ...[
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: Color(0xFF7566E8),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa kết nối được dịch vụ đăng nhập.\nKiểm tra kết nối và thử lại.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: onRetry,
                          child: const Text('Thử lại'),
                        ),
                      ] else ...[
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF7566E8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF858198),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (constraints.maxHeight > 600)
              const Positioned(
                left: 20,
                right: 20,
                bottom: 28,
                child: Text(
                  'EN   ·   中   ·   あ   ·   한\nHọc mỗi ngày, tự tin mỗi bước',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF858198),
                    fontSize: 12,
                    height: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
