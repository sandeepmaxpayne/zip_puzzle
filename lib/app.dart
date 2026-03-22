import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_scope.dart';
import 'screens/auth_screen.dart';
import 'screens/classic_day_selection_screen.dart';
import 'screens/classic_puzzle_screen.dart';
import 'screens/game_type_screen.dart';
import 'screens/original_puzzle_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'services/app_controller.dart';

class ZipPuzzleApp extends StatefulWidget {
  const ZipPuzzleApp({super.key});

  @override
  State<ZipPuzzleApp> createState() => _ZipPuzzleAppState();
}

class _ZipPuzzleAppState extends State<ZipPuzzleApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController()..initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return MaterialApp(
            title: 'Zip Puzzle',
            debugShowCheckedModeBanner: false,
            themeMode: _controller.themeMode,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            home: _controller.initialized
                ? (_controller.isSignedIn
                    ? const SplashScreen()
                    : const AuthScreen())
                : const SplashScreen(),
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case AuthScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (_) => const AuthScreen(),
                    settings: settings,
                  );
                case ProfileScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (_) => const ProfileScreen(),
                    settings: settings,
                  );
                case SplashScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (_) => const SplashScreen(),
                    settings: settings,
                  );
                case GameTypeScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (_) => const GameTypeScreen(),
                    settings: settings,
                  );
                case ClassicDaySelectionScreen.routeName:
                  return MaterialPageRoute<void>(
                    builder: (_) => const ClassicDaySelectionScreen(),
                    settings: settings,
                  );
                case ClassicPuzzleScreen.routeName:
                  final args = settings.arguments as ClassicPuzzleArgs;
                  return MaterialPageRoute<void>(
                    builder: (_) => ClassicPuzzleScreen(args: args),
                    settings: settings,
                  );
                case '/original':
                  return MaterialPageRoute<void>(
                    builder: (_) => ZipPuzzleHome(
                      themeMode: _controller.themeMode,
                      onThemeChanged: _controller.toggleTheme,
                    ),
                    settings: settings,
                  );
                default:
                  return MaterialPageRoute<void>(
                    builder: (_) => const SplashScreen(),
                    settings: settings,
                  );
              }
            },
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: isDark ? const Color(0xFF7FF0CC) : const Color(0xFF0F8C7A),
      brightness: brightness,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );
    final textTheme = GoogleFonts.soraTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        textStyle: base.textTheme.displayLarge,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        textStyle: base.textTheme.displayMedium,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        textStyle: base.textTheme.displaySmall,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        textStyle: base.textTheme.headlineLarge,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        textStyle: base.textTheme.headlineMedium,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        textStyle: base.textTheme.headlineSmall,
        fontWeight: FontWeight.w700,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF061516)
          : const Color(0xFFF7FAF4),
      textTheme: textTheme.apply(
        bodyColor: isDark ? const Color(0xFFE6FFF5) : const Color(0xFF173432),
        displayColor:
            isDark ? const Color(0xFFE6FFF5) : const Color(0xFF173432),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF102425) : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
