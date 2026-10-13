import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/storage/key_value_storage.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      icon: EneftyIcons.cpu_bold,
      title: 'مدیریت تجهیزات و ماشین‌آلات',
      description: 'ثبت دقیق شناسنامه فنی تجهیزات، مشخصات سازنده، کدگذاری یکتا و ساختار درختی والد/فرزند برای تمام دستگاه‌های کارگاه.',
      color: Color(0xFF2563EB),
    ),
    _OnboardingPageData(
      icon: EneftyIcons.calendar_2_bold,
      title: 'نگهداری و تعمیرات پیشگیرانه (PM)',
      description: 'زمان‌بندی هوشمند بر اساس فواصل تقویمی، کارکردی (ساعت کارکرد)، شرطی و یک‌باره جهت جلوگیری از توقف‌های ناگهانی تولید.',
      color: Color(0xFF0284C7),
    ),
    _OnboardingPageData(
      icon: EneftyIcons.document_text_bold,
      title: 'دستورکارهای تعمیراتی و مصرف انبار',
      description: 'ثبت و پیگیری دستورکارها، ثبت زمان توقف و نیروی انسانی، و کسر خودکار قطعات یدکی و مواد مصرفی از انبار کارگاه.',
      color: Color(0xFFD97706),
    ),
    _OnboardingPageData(
      icon: EneftyIcons.chart_2_bold,
      title: 'داشبورد تحلیلی و کنترل انبار',
      description: 'مشاهده سررسیدهای روزانه، هشدارهای کمبود موجودی انبار و مدیریت کامل فعالیت‌های کارگاه بدون نیاز به اینترنت.',
      color: Color(0xFF16A34A),
    ),
  ];

  Future<void> _completeOnboarding() async {
    await KeyValueStorage.instance.setOnboardingCompleted();
    if (mounted) {
      context.go('/setup/facility');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Skip Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('CMMS سیستم نگهداری', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  if (!isLastPage)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text('رد شدن'),
                    ),
                ],
              ),
            ),

            // Onboarding Slides PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  final data = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: data.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(data.icon, size: 70, color: data.color),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          data.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          data.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  height: 8.0,
                  width: _currentPage == index ? 24.0 : 8.0,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: isLastPage
                  ? SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        icon: const Icon(EneftyIcons.building_bold),
                        label: const Text('شروع راه‌اندازی کارگاه', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: _completeOnboarding,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage > 0)
                          OutlinedButton(
                            onPressed: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            ),
                            child: const Text('قبلی'),
                          )
                        else
                          const SizedBox(width: 80),
                        FilledButton.icon(
                          icon: const Icon(EneftyIcons.arrow_left_3_bold, size: 18),
                          label: const Text('بعدی'),
                          onPressed: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
