import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/auth/app_roles.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/src/features/cars/presentation/providers/car_management_providers.dart';
import 'package:mobile/src/features/cars/presentation/screens/add_car_screen.dart';
import 'package:mobile/src/features/home/presentation/providers/home_providers.dart';

class ManageCarsScreen extends ConsumerWidget {
  const ManageCarsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).asData?.value;
    final canManage = session == null || !AppRoles.isSeller(session.role) || session.canManageCars;
    final cars = ref.watch(myCarsProvider);

    Widget renewalBanner() {
      if (session == null || !session.isExpired) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orangeAccent),
        ),
        child: const MetallicSilverText(
          'انتهى اشتراكك. يمكنك تسجيل الدخول وعرض سياراتك، لكن لا يمكنك إضافة أو تعديل السيارات. تواصل مع الإدارة للتجديد.',
          textAlign: TextAlign.right,
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          renewalBanner(),
          Expanded(
            child: cars.when(
              data: (items) => items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const MetallicSilverText('لا توجد سيارات بعد'),
                          if (canManage) ...[
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddCarScreen()),
                              ).then((_) => ref.invalidate(myCarsProvider)),
                              child: const Text('إضافة سيارة'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(myCarsProvider);
                        await ref.read(myCarsProvider.future);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final car = items[i];
                          return Card(
                            color: const Color(0xFF0B1D48),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text('${car.name} ${car.model}', textAlign: TextAlign.right, style: AppTheme.orangeTextStyle),
                              subtitle: Text(
                                '${car.brandName} • ${car.exhibitionName}\n${car.year} • \$${car.price.toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: AppTheme.orangeTextStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              isThreeLine: true,
                              leading: canManage
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () async {
                                        await ref.read(carRemoteDataSourceProvider).deleteCar(car.id);
                                        ref.invalidate(myCarsProvider);
                                        ref.invalidate(statisticsProvider);
                                      },
                                    )
                                  : null,
                              trailing: canManage
                                  ? IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => AddCarScreen(car: car)),
                                      ).then((_) => ref.invalidate(myCarsProvider)),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: MetallicSilverText('خطأ: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCarScreen()),
              ).then((_) => ref.invalidate(myCarsProvider)),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
