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
    if (loc.startsWith('/settings') ||
        loc.startsWith('/reports') ||
        loc.startsWith('/locations') ||
        loc.startsWith('/maintenance-plans') ||
        loc.startsWith('/purchases') ||
        loc.startsWith('/alerts')) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;

    final isMobile = width < 600;
    final isExpanded = width >= 900;

    if (!isMobile) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: currentIndex,
              onDestinationSelected: (index) => _onItemTapped(context, index),
              extended: isExpanded,
              labelType: isExpanded
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              backgroundColor: colorScheme.surface,
              indicatorColor: colorScheme.primaryContainer,
              leading: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            EneftyIcons.setting_5_bold,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'مدیریت نگهداری و تعمیرات',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Icon(
                        EneftyIcons.setting_5_bold,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                    ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(EneftyIcons.home_2_outline),
                  selectedIcon: Icon(EneftyIcons.home_2_bold),
                  label: Text('داشبورد'),
                ),
                NavigationRailDestination(
                  icon: Icon(EneftyIcons.cpu_outline),
                  selectedIcon: Icon(EneftyIcons.cpu_bold),
                  label: Text('تجهیزات'),
                ),
                NavigationRailDestination(
                  icon: Icon(EneftyIcons.document_text_outline),
                  selectedIcon: Icon(EneftyIcons.document_text_bold),
                  label: Text('دستورات کار'),
                ),
                NavigationRailDestination(
                  icon: Icon(EneftyIcons.box_outline),
                  selectedIcon: Icon(EneftyIcons.box_bold),
                  label: Text('انبار'),
                ),
                NavigationRailDestination(
                  icon: Icon(EneftyIcons.setting_2_outline),
                  selectedIcon: Icon(EneftyIcons.setting_2_bold),
                  label: Text('تنظیمات'),
                ),
              ],
            ),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: colorScheme.primaryContainer,
          elevation: 0,
          height: 75,
          onDestinationSelected: (index) => _onItemTapped(context, index),
          destinations: const [
            NavigationDestination(
              icon: Icon(EneftyIcons.home_2_outline),
              selectedIcon: Icon(EneftyIcons.home_2_bold),
              label: 'داشبورد',
            ),
            NavigationDestination(
              icon: Icon(EneftyIcons.cpu_outline),
              selectedIcon: Icon(EneftyIcons.cpu_bold),
              label: 'تجهیزات',
            ),
            NavigationDestination(
              icon: Icon(EneftyIcons.document_text_outline),
              selectedIcon: Icon(EneftyIcons.document_text_bold),
              label: 'دستورات کار',
            ),
            NavigationDestination(
              icon: Icon(EneftyIcons.box_outline),
              selectedIcon: Icon(EneftyIcons.box_bold),
              label: 'انبار',
            ),
            NavigationDestination(
              icon: Icon(EneftyIcons.setting_2_outline),
              selectedIcon: Icon(EneftyIcons.setting_2_bold),
              label: 'تنظیمات',
            ),
          ],
        ),
      ),
    );
  }
}
