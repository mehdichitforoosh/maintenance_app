import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffoldShell extends StatelessWidget {
  final Widget child;
  final String location;

  const AppScaffoldShell({
    super.key,
    required this.child,
    required this.location,
  });

  int _getCurrentIndex(String loc) {
    if (loc.startsWith('/assets')) return 1;
    if (loc.startsWith('/work-orders')) return 2;
    if (loc.startsWith('/inventory')) return 3;
    if (loc.startsWith('/settings') || loc.startsWith('/locations') || loc.startsWith('/maintenance-plans') || loc.startsWith('/purchases') || loc.startsWith('/alerts')) {
      return 4;
    }
    return 0; // Dashboard
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/assets');
        break;
      case 2:
        context.go('/work-orders');
        break;
      case 3:
        context.go('/inventory');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: const Color(0xFFDBEAFE),
          elevation: 0,
          height: 65,
          onDestinationSelected: (index) => _onItemTapped(context, index),
          destinations: const [
            NavigationDestination(
              icon: Icon(EneftyIcons.home_2_outline),
              selectedIcon: Icon(EneftyIcons.home_2_bold,),
              label: 'داشبورد',
            ),
            NavigationDestination(
              icon: Icon(EneftyIcons.cpu_outline),
              selectedIcon: Icon(EneftyIcons.cpu_bold,),
              label: 'تجهیزات',
            ),
            NavigationDestination(
              icon: Icon(EneftyIcons.document_text_outline),
              selectedIcon: Icon(EneftyIcons.document_text_bold,),
              label: 'دستورات کار',
            ),
            NavigationDestination(
              icon: Icon(EneftyIcons.box_outline),
              selectedIcon: Icon(EneftyIcons.box_bold,),
              label: 'انبار',
            ),
            NavigationDestination(
              icon: Icon(EneftyIcons.setting_2_outline),
              selectedIcon: Icon(EneftyIcons.setting_2_bold,),
              label: 'تنظیمات',
            ),
          ],
        ),
      ),
    );
  }
}
