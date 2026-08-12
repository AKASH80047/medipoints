import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/billing')) return 1;
    if (location.startsWith('/stock')) return 2;
    if (location.startsWith('/purchase')) return 3;
    if (location.startsWith('/reports')) return 4;
    if (location.startsWith('/settings')) return 5;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/billing');
        break;
      case 2:
        context.go('/stock');
        break;
      case 3:
        context.go('/purchase');
        break;
      case 4:
        context.go('/reports');
        break;
      case 5:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isTablet = MediaQuery.of(context).size.width >= 720;

    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (idx) => _onItemTapped(idx, context),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'MP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Text('🏠', style: TextStyle(fontSize: 20)),
                  selectedIcon: Text('🏠', style: TextStyle(fontSize: 22)),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Text('🧾', style: TextStyle(fontSize: 20)),
                  selectedIcon: Text('🧾', style: TextStyle(fontSize: 22)),
                  label: Text('Billing'),
                ),
                NavigationRailDestination(
                  icon: Text('📦', style: TextStyle(fontSize: 20)),
                  selectedIcon: Text('📦', style: TextStyle(fontSize: 22)),
                  label: Text('Stock'),
                ),
                NavigationRailDestination(
                  icon: Text('🛒', style: TextStyle(fontSize: 20)),
                  selectedIcon: Text('🛒', style: TextStyle(fontSize: 22)),
                  label: Text('Purchase'),
                ),
                NavigationRailDestination(
                  icon: Text('📊', style: TextStyle(fontSize: 20)),
                  selectedIcon: Text('📊', style: TextStyle(fontSize: 22)),
                  label: Text('Reports'),
                ),
                NavigationRailDestination(
                  icon: Text('⚙️', style: TextStyle(fontSize: 20)),
                  selectedIcon: Text('⚙️', style: TextStyle(fontSize: 22)),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (idx) => _onItemTapped(idx, context),
        destinations: const [
          NavigationDestination(
            icon: Text('🏠', style: TextStyle(fontSize: 20)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Text('🧾', style: TextStyle(fontSize: 20)),
            label: 'Billing',
          ),
          NavigationDestination(
            icon: Text('📦', style: TextStyle(fontSize: 20)),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Text('🛒', style: TextStyle(fontSize: 20)),
            label: 'Purchase',
          ),
          NavigationDestination(
            icon: Text('📊', style: TextStyle(fontSize: 20)),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Text('⚙️', style: TextStyle(fontSize: 20)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
