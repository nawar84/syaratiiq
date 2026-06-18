import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/auth/app_permissions.dart';
import 'package:mobile/src/core/auth/app_roles.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/core/utils/contact_launcher.dart';
import 'package:mobile/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/src/features/cars/presentation/providers/car_management_providers.dart';
import 'package:mobile/src/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:mobile/src/features/marketplace/presentation/screens/car_detail_screen.dart';
import 'package:mobile/src/features/marketplace/presentation/widgets/car_studio_card.dart';

class ShowroomDetailsScreen extends ConsumerWidget {
  const ShowroomDetailsScreen({super.key, required this.showroomId});

  final int showroomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showroom = ref.watch(showroomDetailProvider(showroomId));
    final session = ref.watch(authSessionProvider).asData?.value;
    final role = session?.role ?? AppRoles.buyer;
    final myShowroomIds = ref.watch(myShowroomIdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const MetallicSilverText('تفاصيل المعرض', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: showroom.when(
        data: (item) {
          final isOwnShowroom = myShowroomIds.when(
            data: (ids) => AppPermissions.isOwnShowroom(ids, item.id),
            loading: () => false,
            error: (_, _) => false,
          );
          final canContact = AppPermissions.canContactShowroom(role, isOwnShowroom: isOwnShowroom);
          final showVisitors = AppPermissions.canViewShowroomVisitors(role, isOwnShowroom: isOwnShowroom);

          final width = MediaQuery.of(context).size.width;
          final scale = (width / 430).clamp(0.9, 1.2);

          return CustomScrollView(
            slivers: [
              if (item.coverImageUrl != null)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: Image.network(item.coverImageUrl!, fit: BoxFit.cover),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        if (item.logoUrl != null)
                          CircleAvatar(radius: 32, backgroundImage: NetworkImage(item.logoUrl!))
                        else
                          const CircleAvatar(radius: 32, child: Icon(Icons.storefront, size: 32)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              MetallicSilverText(item.name, headline: true, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
                              MetallicSilverText(item.provinceName, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (showVisitors) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF0B1D48),
                          border: Border.all(color: const Color(0xFF8FA3D1).withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${item.viewsCount}',
                                  style: AppTheme.orangeTextStyle.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'زيارات صفحة المعرض',
                                  style: AppTheme.orangeTextStyle.copyWith(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.visibility_outlined, color: Color(0xFF8FA3D1), size: 28),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _info(Icons.location_on_outlined, 'العنوان', item.address),
                    _info(Icons.phone_outlined, 'الهاتف', item.phone, valueFontSize: 21),
                    if (item.description.isNotEmpty) _info(Icons.info_outline, 'الوصف', item.description),
                    const SizedBox(height: 8),
                    MetallicSilverText(
                      'إجمالي السيارات: ${item.carsCount}',
                      headline: true,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    if (canContact) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: AppTheme.contactButtonStyle,
                              onPressed: () => ContactLauncher.openPhoneOrNotify(context, item.phone),
                              icon: const Icon(Icons.phone),
                              label: const Text('اتصال', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              style: AppTheme.contactButtonStyle,
                              onPressed: () => ContactLauncher.openWhatsAppOrNotify(context, item.phone),
                              icon: const Icon(Icons.chat),
                              label: const Text('واتساب', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ] else if (AppRoles.isSeller(role) && isOwnShowroom)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: MetallicSilverText(
                          'هذا معرضك — زر الاتصال يظهر للمشترين والبائعين الآخرين',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 24),
                    const MetallicSilverText('سيارات المعرض', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
              if (item.cars.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: MetallicSilverText(
                      'لا توجد سيارات معروضة حالياً',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(14 * scale, 0, 14 * scale, 16 * scale),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12 * scale,
                      mainAxisSpacing: 12 * scale,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final car = item.cars[index];
                        return CarStudioCard(
                          car: car,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CarDetailScreen(carId: car.id)),
                          ),
                        );
                      },
                      childCount: item.cars.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: MetallicSilverText('خطأ: $e')),
      ),
    );
  }

  Widget _info(IconData icon, String label, String value, {double? valueFontSize}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8A97BF), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MetallicSilverText(label, style: const TextStyle(fontSize: 12)),
                MetallicSilverText(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: valueFontSize ?? 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
