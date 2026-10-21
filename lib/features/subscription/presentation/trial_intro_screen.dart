import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/subscription/providers/subscription_providers.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isStartingTrial = false;

  Future<void> _startTrial() async {
    setState(() => _isStartingTrial = true);
    try {
      await ref.read(subscriptionActionsProvider).startTrial();
      if (mounted) context.go('/onboarding');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('شروع دوره آزمایشی ناموفق بود: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingTrial = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFEAF4FF), Color(0xFFF8FAFF), Color(0xFFE8F7F3)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -75,
              left: -55,
              child: _BackgroundGlow(size: 190),
            ),
            const Positioned(
              bottom: 30,
              right: -85,
              child: _BackgroundGlow(size: 220),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _HeroArtwork(),
                        const SizedBox(height: 24),
                        Text(
                          'مدیریت نگهداری و تعمیرات کارگاه',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'تجهیزات، برنامه‌های سرویس، دستورکارها و موجودی قطعات را در یک برنامه آفلاین مدیریت کنید.',
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colors.outlineVariant.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                          child: const Column(
                            children: [
                              _FeatureTile(
                                icon: Icons.precision_manufacturing_outlined,
                                title: 'شناسنامه و ساختار تجهیزات',
                              ),
                              _FeatureTile(
                                icon: Icons.event_repeat_outlined,
                                title: 'برنامه‌ریزی نگهداری پیشگیرانه',
                              ),
                              _FeatureTile(
                                icon: Icons.inventory_2_outlined,
                                title: 'دستورکار و کنترل موجودی انبار',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: _isStartingTrial ? null : _startTrial,
                            icon: _isStartingTrial
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.rocket_launch_outlined),
                            label: const Text('شروع ۱۵ روز دسترسی کامل'),
                          ),
                        ),
                        TextButton(
                          onPressed: _isStartingTrial
                              ? null
                              : () => context.go('/onboarding'),
                          child: const Text('ادامه بدون شروع دوره آزمایشی'),
                        ),
                        Text(
                          'بدون پرداخت درون‌برنامه‌ای؛ پس از پایان دوره آزمایشی، برنامه در حالت فقط‌خواندنی قرار می‌گیرد.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF3478D4), Color(0xFF2456A6), Color(0xFF183B77)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2456A6).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -48,
              right: -12,
              child: _ArtworkCircle(
                size: 150,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              bottom: -70,
              left: 20,
              child: _ArtworkCircle(
                size: 170,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            const Icon(
              EneftyIcons.buildings_2_outline,
              size: 82,
              color: Colors.white,
            ),
            Positioned(
              bottom: 25,
              right: 30,
              child: _FloatingArtworkIcon(
                icon: Icons.settings_outlined,
                color: Color(0xFFB8E6D8),
              ),
            ),
            Positioned(
              top: 26,
              left: 35,
              child: _FloatingArtworkIcon(
                icon: Icons.check_circle_outline,
                color: Color(0xFFFFD88A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  final double size;

  const _BackgroundGlow({required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _ArtworkCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _ArtworkCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _FloatingArtworkIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _FloatingArtworkIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FeatureTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
    );
  }
}
