import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/key_value_storage.dart';
import 'widgets/onboarding_bottom_navigation.dart';
import 'widgets/onboarding_header.dart';
import 'widgets/onboarding_page_content.dart';
import 'widgets/onboarding_page_indicator.dart';

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
      description:
          'ثبت دقیق شناسنامه فنی تجهیزات، مشخصات سازنده، کدگذاری یکتا و ساختار درختی والد/فرزند برای تمام دستگاه‌های کارگاه.',
      color: Color(0xFF2563EB),
    ),
    _OnboardingPageData(
      icon: EneftyIcons.calendar_2_bold,
      title: 'نگهداری و تعمیرات پیشگیرانه (PM)',
      description:
          'زمان‌بندی هوشمند بر اساس فواصل تقویمی، کارکردی (ساعت کارکرد)، شرطی و یک‌باره جهت جلوگیری از توقف‌های ناگهانی تولید.',
      color: Color(0xFF0284C7),
    ),
    _OnboardingPageData(
      icon: EneftyIcons.document_text_bold,
      title: 'دستورکارهای تعمیراتی و مصرف انبار',
      description:
          'ثبت و پیگیری دستورکارها، ثبت زمان توقف و نیروی انسانی، و کسر خودکار قطعات یدکی و مواد مصرفی از انبار کارگاه.',
      color: Color(0xFFD97706),
    ),
    _OnboardingPageData(
      icon: EneftyIcons.chart_2_bold,
      title: 'داشبورد تحلیلی و کنترل انبار',
      description:
          'مشاهده سررسیدهای روزانه، هشدارهای کمبود موجودی انبار و مدیریت کامل فعالیت‌های کارگاه بدون نیاز به اینترنت.',
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
            OnboardingHeader(
              showSkip: !isLastPage,
              onSkip: _completeOnboarding,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) => OnboardingPageContent(
                  icon: _pages[index].icon,
                  title: _pages[index].title,
                  description: _pages[index].description,
                  color: _pages[index].color,
                  compact: MediaQuery.sizeOf(context).height < 700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OnboardingPageIndicator(
                pageCount: _pages.length,
                currentPage: _currentPage,
              ),
            ),
            SizedBox(height: MediaQuery.sizeOf(context).height < 700 ? 12 : 24),
            OnboardingBottomNavigation(
              currentPage: _currentPage,
              pageCount: _pages.length,
              onPrevious: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              onNext: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              onComplete: _completeOnboarding,
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
