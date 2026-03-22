import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/game_type.dart';
import 'auth_screen.dart';
import 'classic_day_selection_screen.dart';
import 'profile_screen.dart';

class GameTypeScreen extends StatelessWidget {
  const GameTypeScreen({super.key});

  static const routeName = '/game-types';

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.scaffoldBackgroundColor,
                isDark ? const Color(0xFF0B1E1F) : const Color(0xFFFFF8EE),
                isDark ? const Color(0xFF102D2E) : const Color(0xFFE7FFF3),
              ],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            children: [
              Text(
                'Choose your game type',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Classic adds daily progression, streak claims, and three difficulty tracks. Original opens the existing puzzle flow.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 22),
              _ModeCard(
                gameType: GameType.classic,
                colors: const [Color(0xFFFFD98E), Color(0xFF39D5B3)],
                icon: Icons.auto_awesome_mosaic_rounded,
                accent: const Color(0xFF11423E),
                onTap: () {
                  Navigator.of(context).pushNamed(
                    ClassicDaySelectionScreen.routeName,
                  );
                },
              ),
              const SizedBox(height: 18),
              _ModeCard(
                gameType: GameType.original,
                colors: const [Color(0xFFB8EDFF), Color(0xFF69C6D0)],
                icon: Icons.alt_route_rounded,
                accent: const Color(0xFF14353B),
                onTap: () {
                  Navigator.of(context).pushNamed('/original');
                },
              ),
              const SizedBox(height: 22),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            const Color(0xFF39D5B3).withValues(alpha: 0.16),
                        backgroundImage: controller.authProfile?.photoUrl != null
                            ? NetworkImage(controller.authProfile!.photoUrl!)
                            : null,
                        child: controller.authProfile?.photoUrl == null
                            ? const Icon(Icons.person_rounded)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.authProfile?.shortName ?? 'Player',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.authProfile?.email ??
                                  'Signed in profile ready for sync',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color:
                                    theme.colorScheme.onSurface.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(ProfileScreen.routeName);
                        },
                        icon: const Icon(Icons.edit_rounded),
                        tooltip: 'Edit profile',
                      ),
                      IconButton(
                        onPressed: () async {
                          await controller.signOut();
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AuthScreen.routeName,
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout_rounded),
                        tooltip: 'Sign out',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: const Color(0xFF39D5B3).withValues(alpha: 0.14),
                        ),
                        child: const Icon(Icons.cloud_done_rounded),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.isCloudReady
                                  ? 'Cloud sync is ready'
                                  : 'Cloud sync is scaffolded',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.isCloudReady
                                  ? 'Signed in as ${controller.authProfile?.email ?? controller.authProfile?.shortName ?? controller.cloudUserId?.substring(0, 8) ?? 'guest'} and saving progress locally + in Firebase.'
                                  : 'Dummy Firebase options are wired in. Replace them with your real credentials to start online sync.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.gameType,
    required this.colors,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final GameType gameType;
  final List<Color> colors;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(34),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(icon, color: accent, size: 30),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_rounded, color: accent),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  gameType.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  gameType.subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: accent.withValues(alpha: 0.88),
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
