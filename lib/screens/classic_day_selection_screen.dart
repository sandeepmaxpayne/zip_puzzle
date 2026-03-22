import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../app_scope.dart';
import '../models/app_progress.dart';
import '../services/app_controller.dart';
import '../services/monetization_config.dart';
import '../widgets/ad_banner_slot.dart';
import 'classic_puzzle_screen.dart';

class ClassicDaySelectionScreen extends StatelessWidget {
  const ClassicDaySelectionScreen({super.key});

  static const routeName = '/classic-days';

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final theme = Theme.of(context);
    final year = DateTime.now().year;
    final totalDays = AppProgress.totalDaysForYear(year);
    final canClaim = controller.progress.canClaimToday(DateTime.now());
    final nextClaimDay = controller.progress.nextClaimDayIndex.clamp(
      1,
      totalDays,
    );
    final advanceUnlockProduct = _productFor(
      controller,
      MonetizationConfig.advanceUnlockProductId,
    );
    final streakFreezeProduct = _productFor(
      controller,
      MonetizationConfig.streakFreezeProductId,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Classic Mode'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$year Daily Ladder',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalDays levels this year. Claim today\'s streak, clear your current day on any difficulty, and the next day opens.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _InfoPill(
                          label: 'Current streak',
                          value:
                              '${controller.progress.currentStreak} day${controller.progress.currentStreak == 1 ? '' : 's'}',
                          color: const Color(0xFFFFD98E),
                        ),
                        _InfoPill(
                          label: 'Claimed days',
                          value: '${controller.progress.totalClaims}',
                          color: const Color(0xFF95F0D0),
                        ),
                        _InfoPill(
                          label: 'Next claim opens',
                          value: 'Day $nextClaimDay',
                          color: const Color(0xFFBDEBFF),
                        ),
                        _InfoPill(
                          label: 'Freeze credits',
                          value: '${controller.progress.streakFreezeCredits}',
                          color: const Color(0xFFE7D0FF),
                        ),
                        _InfoPill(
                          label: 'Advance unlocks',
                          value:
                              '${controller.progress.advanceUnlockDays} days',
                          color: const Color(0xFFFFE4CD),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: canClaim
                            ? () async {
                                await controller.claimToday();
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Streak claimed. Day ${controller.progress.totalClaims} is now counted toward your ladder.',
                                    ),
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.local_fire_department_rounded),
                        label: Text(
                          canClaim
                              ? 'Claim Today\'s Streak'
                              : 'Today Already Claimed',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Boost your ladder',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Google Play handles the payment. Firebase stores the purchase record and your unlock entitlements.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
                    if (controller.billingMessage case final message?)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _PurchaseTile(
                      title: 'Unlock next 5 days',
                      priceLabel: advanceUnlockProduct?.price ?? 'Buy Now',
                      icon: Icons.rocket_launch_rounded,
                      onPressed: controller.isBillingAvailable
                          ? () async {
                              final didStart = await controller
                                  .buyAdvanceUnlockPack();
                              if (!context.mounted || didStart) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'The advance unlock product is not available on this test build yet.',
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _PurchaseTile(
                      title: 'Buy streak freeze',
                      priceLabel: streakFreezeProduct?.price ?? 'Buy Now',
                      icon: Icons.ac_unit_rounded,
                      onPressed: controller.isBillingAvailable
                          ? () async {
                              final didStart = await controller
                                  .buyStreakFreezePack();
                              if (!context.mounted || didStart) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'The streak freeze product is not available on this test build yet.',
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Choose a day',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalDays,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final day = index + 1;
                final isUnlocked = controller.isDayUnlocked(year, day);
                final isCompleted = controller.progress.isDayCompletedAny(
                  year,
                  day,
                );
                return _DayTile(
                  day: day,
                  isUnlocked: isUnlocked,
                  isCompleted: isCompleted,
                  onTap: () {
                    if (!isUnlocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'This day is still locked. Claim the streak and clear the previous day first.',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pushNamed(
                      ClassicPuzzleScreen.routeName,
                      arguments: ClassicPuzzleArgs(year: year, day: day),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            const Center(child: AdBannerSlot()),
          ],
        ),
      ),
    );
  }

  ProductDetails? _productFor(AppController controller, String productId) {
    for (final product in controller.monetizationProducts) {
      if (product.id == productId) {
        return product;
      }
    }
    return null;
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile({
    required this.title,
    required this.priceLabel,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String priceLabel;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF7),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(onPressed: onPressed, child: Text(priceLabel)),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.isUnlocked,
    required this.isCompleted,
    required this.onTap,
  });

  final int day;
  final bool isUnlocked;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color baseColor = isCompleted
        ? const Color(0xFF3CD5B3)
        : isUnlocked
        ? const Color(0xFFFFD98E)
        : const Color(0xFFE4E8E7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: baseColor.withValues(alpha: isUnlocked ? 0.22 : 0.55),
            border: Border.all(
              color: isUnlocked
                  ? baseColor.withValues(alpha: 0.8)
                  : theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  '$day',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isUnlocked
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  isCompleted
                      ? Icons.verified_rounded
                      : isUnlocked
                      ? Icons.lock_open_rounded
                      : Icons.lock_rounded,
                  size: 16,
                  color: isCompleted
                      ? const Color(0xFF0E8A77)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
