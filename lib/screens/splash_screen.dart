import 'package:flutter/material.dart';

import '../app_scope.dart';
import 'auth_screen.dart';
import 'game_type_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();
    Future<void>.delayed(const Duration(milliseconds: 2600), _finish);
  }

  void _finish() {
    if (!mounted) {
      return;
    }
    final controller = AppScope.of(context);
    Navigator.of(context).pushReplacementNamed(
      controller.isSignedIn ? GameTypeScreen.routeName : AuthScreen.routeName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [
                    Color(0xFF041616),
                    Color(0xFF0D2D2B),
                    Color(0xFF194543),
                  ]
                : const [
                    Color(0xFFFFFBF4),
                    Color(0xFFE6FFF5),
                    Color(0xFFCFF7E5),
                  ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final curve = CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOutCubic,
              );
              return Opacity(
                opacity: Tween<double>(begin: 0, end: 1)
                    .evaluate(curve)
                    .clamp(0.0, 1.0)
                    .toDouble(),
                child: Transform.scale(
                  scale: Tween<double>(begin: 0.8, end: 1).evaluate(curve),
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 188,
                  height: 188,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(44),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF38D2B0), Color(0xFF0E8A77)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0E8A77).withValues(alpha: 0.28),
                        blurRadius: 32,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _SplashLogoPainter(progress: _controller.value),
                        child: const SizedBox.expand(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Zip Puzzle',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Classic daily boards and the original puzzle now live side by side.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashLogoPainter extends CustomPainter {
  _SplashLogoPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF6FFF9), Color(0xFFCFFAF0)],
      ).createShader(rect);
    final border = Paint()
      ..color = const Color(0xFF0C4C47).withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final cell = size.width / 4.6;
    final startX = (size.width - cell * 3) / 2;
    final startY = (size.height - cell * 3) / 2;

    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            startX + (col * cell),
            startY + (row * cell),
            cell - 8,
            cell - 8,
          ),
          const Radius.circular(12),
        );
        canvas.drawRRect(rrect, fill);
        canvas.drawRRect(rrect, border);
      }
    }

    final route = [
      Offset(startX + cell / 2 - 4, startY + cell / 2 - 4),
      Offset(startX + cell * 1.5 - 4, startY + cell / 2 - 4),
      Offset(startX + cell * 1.5 - 4, startY + cell * 1.5 - 4),
      Offset(startX + cell * 2.5 - 4, startY + cell * 1.5 - 4),
      Offset(startX + cell * 2.5 - 4, startY + cell * 2.5 - 4),
    ];

    final routePath = Path()..moveTo(route.first.dx, route.first.dy);
    for (final point in route.skip(1)) {
      routePath.lineTo(point.dx, point.dy);
    }

    final metric = routePath.computeMetrics().first;
    final extracted = metric.extractPath(0, metric.length * progress);
    final routePaint = Paint()
      ..color = const Color(0xFF0E8A77)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(extracted, routePaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Z',
        style: TextStyle(
          color: Color(0xFF0C4C47),
          fontSize: 52,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, size.height - 74),
    );
  }

  @override
  bool shouldRepaint(covariant _SplashLogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
