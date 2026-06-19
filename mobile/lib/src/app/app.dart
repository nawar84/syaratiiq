import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/layout/web_desktop_phone_frame.dart';
import 'package:mobile/src/core/auth/app_permissions.dart';
import 'package:mobile/src/core/auth/app_roles.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/core/theme/silver_bottom_navigation_bar.dart';
import 'package:mobile/src/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mobile/src/features/admin/presentation/screens/admin_management_screen.dart';
import 'package:mobile/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/src/features/auth/presentation/screens/auth_screen.dart';
import 'package:mobile/src/features/cars/presentation/providers/car_management_providers.dart';
import 'package:mobile/src/features/cars/presentation/screens/manage_cars_screen.dart';
import 'package:mobile/src/features/exhibitions/presentation/screens/add_exhibition_screen.dart';
import 'package:mobile/src/features/home/presentation/screens/home_screen.dart';
import 'package:mobile/src/features/marketplace/presentation/screens/car_search_screen.dart';
import 'package:mobile/src/features/marketplace/presentation/screens/cars_browse_screen.dart';
import 'package:mobile/src/features/marketplace/presentation/screens/favorites_screen.dart';
import 'package:mobile/src/features/marketplace/presentation/screens/owner_analytics_screen.dart';
import 'package:mobile/src/features/marketplace/presentation/screens/showrooms_list_screen.dart';

class CarsIraqApp extends ConsumerStatefulWidget {
  const CarsIraqApp({super.key});

  @override
  ConsumerState<CarsIraqApp> createState() => _CarsIraqAppState();
}

class _CarsIraqAppState extends ConsumerState<CarsIraqApp> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(authSessionProvider);
    return MaterialApp(
      key: const ValueKey('metallic-silver-v5'),
      title: 'سياراتي IQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) => WebDesktopPhoneFrame(
        child: child ?? const SizedBox.shrink(),
      ),
      home: sessionState.when(
        loading: () => const _StartupSplash(),
        error: (error, stackTrace) => const AuthScreen(),
        data: (session) {
          if (session == null) return const AuthScreen();
          final role = session.role;
          final isBuyer = AppRoles.isBuyer(role);
          final isSeller = AppRoles.isSeller(role);
          final isAdmin = AppRoles.isAdmin(role);
          final myExhibitions = isSeller ? ref.watch(myExhibitionsProvider) : null;
          final canAddShowroom = isSeller
              ? myExhibitions?.when(
                    data: (list) => AppPermissions.canAddShowroom(role, list.length),
                    loading: () => false,
                    error: (_, _) => false,
                  ) ??
                  false
              : false;

          final screens = <Widget>[
            const HomeScreen(),
            const CarsBrowseScreen(),
            const ShowroomsListScreen(),
            if (isBuyer)
              const FavoritesScreen()
            else if (isSeller)
              const ManageCarsScreen()
            else if (isAdmin)
              const AdminManagementScreen(),
          ];

          final navItems = <SilverBottomNavItem>[
            const SilverBottomNavItem(icon: Icons.home_rounded, label: 'الرئيسية'),
            const SilverBottomNavItem(icon: Icons.directions_car_filled_outlined, label: 'السيارات'),
            const SilverBottomNavItem(icon: Icons.storefront_outlined, label: 'المعارض'),
            if (isBuyer)
              const SilverBottomNavItem(icon: Icons.favorite_border, label: 'المفضلة')
            else if (isSeller)
              const SilverBottomNavItem(icon: Icons.inventory_2_outlined, label: 'سياراتي')
            else if (isAdmin)
              const SilverBottomNavItem(icon: Icons.admin_panel_settings_outlined, label: 'الإدارة'),
          ];

          return Builder(
            builder: (navContext) {
              return Scaffold(
                resizeToAvoidBottomInset: true,
                appBar: AppBar(
                  title: MetallicSilverText(
                    'مرحبًا ${session.name}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  actions: [
                    if (isBuyer || isSeller || isAdmin)
                      IconButton(
                        onPressed: () => Navigator.push(
                          navContext,
                          MaterialPageRoute(builder: (_) => const CarSearchScreen()),
                        ),
                        icon: const Icon(Icons.search),
                      ),
                    if (isSeller && canAddShowroom)
                      IconButton(
                        tooltip: 'إضافة معرض',
                        onPressed: () => Navigator.push(
                          navContext,
                          MaterialPageRoute(builder: (_) => const AddExhibitionScreen(embedded: false)),
                        ),
                        icon: const Icon(Icons.add_business_outlined),
                      ),
                    if (isSeller)
                      IconButton(
                        onPressed: () => Navigator.push(
                          navContext,
                          MaterialPageRoute(builder: (_) => const OwnerAnalyticsScreen()),
                        ),
                        icon: const Icon(Icons.analytics_outlined),
                      ),
                    if (isAdmin)
                      IconButton(
                        onPressed: () => Navigator.push(
                          navContext,
                          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                        ),
                        icon: const Icon(Icons.analytics_outlined),
                      ),
                    IconButton(
                      onPressed: () => ref.read(authSessionProvider.notifier).logout(),
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                ),
                body: IndexedStack(index: _index, children: screens),
                bottomNavigationBar: SilverBottomNavigationBar(
                  currentIndex: _index,
                  onTap: (value) => setState(() => _index = value),
                  items: navItems,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF040F2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car_filled_rounded, size: 72, color: Color(0xFFC0C0C0)),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFFFF9412)),
            SizedBox(height: 16),
            Text(
              'سياراتي IQ',
              style: TextStyle(color: Color(0xFFC0C0C0), fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
