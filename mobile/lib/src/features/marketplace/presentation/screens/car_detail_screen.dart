import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/auth/app_permissions.dart';
import 'package:mobile/src/core/auth/app_roles.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/core/utils/contact_launcher.dart';
import 'package:mobile/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/src/features/cars/domain/entities/car_management_entities.dart';
import 'package:mobile/src/features/cars/presentation/providers/car_management_providers.dart';
import 'package:mobile/src/features/cars/presentation/screens/add_car_screen.dart';
import 'package:mobile/src/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:mobile/src/features/marketplace/presentation/screens/showroom_details_screen.dart';
import 'package:mobile/src/features/marketplace/presentation/widgets/car_image_gallery.dart';

class CarDetailScreen extends ConsumerWidget {
  const CarDetailScreen({super.key, required this.carId});

  final int carId;

  Future<void> _openEdit(BuildContext context, WidgetRef ref) async {
    final cars = await ref.read(myCarsProvider.future);
    OwnerCar? match;
    for (final car in cars) {
      if (car.id == carId) {
        match = car;
        break;
      }
    }
    if (!context.mounted) return;
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن تعديل هذه السيارة')),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddCarScreen(car: match)),
    );
    ref.invalidate(myCarsProvider);
    ref.invalidate(carDetailProvider(carId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final car = ref.watch(carDetailProvider(carId));
    final session = ref.watch(authSessionProvider).asData?.value;
    final role = session?.role ?? AppRoles.buyer;
    final myShowroomIds = ref.watch(myShowroomIdsProvider);
    final favorite = ref.watch(isFavoriteProvider(carId));
    final repo = ref.read(marketplaceRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const MetallicSilverText('تفاصيل السيارة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: car.when(
        data: (item) {
          final isOwnCar = myShowroomIds.when(
            data: (ids) => AppPermissions.isOwnShowroom(ids, item.showroomId),
            loading: () => false,
            error: (_, _) => false,
          );
          final canContact = AppPermissions.canContactAboutCar(role, isOwnCar: isOwnCar);
          final canEdit = AppPermissions.canEditCar(role, isOwnCar: isOwnCar);
          final canFavorite = AppPermissions.canUseFavorites(role);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (item.imageUrls.isNotEmpty)
                CarImageGallery(imageUrls: item.imageUrls)
              else
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF152A55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Icon(Icons.directions_car, size: 64, color: Color(0xFF8A97BF))),
                ),
              const SizedBox(height: 16),
              MetallicSilverText(item.title, headline: true, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              MetallicSilverText('\$${item.price.toStringAsFixed(0)}', headline: true, style: const TextStyle(fontSize: 22)),
              if (isOwnCar && AppRoles.isSeller(role))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: MetallicSilverText(
                    'سيارتك المعروضة في معرضك',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF8FA3D1)),
                    textAlign: TextAlign.right,
                  ),
                ),
              const SizedBox(height: 12),
              _row('الماركة', item.brandName),
              _row('الموديل', item.model),
              _row('السنة', '${item.year}'),
              _row('اللون', item.color.isNotEmpty ? item.color : '—'),
              _row('العداد', item.mileage > 0 ? '${item.mileage} km' : '—'),
              _row('الوقود', item.fuelType.isNotEmpty ? item.fuelType : '—'),
              _row('القير', item.transmission.isNotEmpty ? item.transmission : '—'),
              if (item.description.isNotEmpty) _row('الوصف', item.description),
              if (item.damageNotes.isNotEmpty) _row('ملاحظات الأضرار', item.damageNotes),
              const Divider(height: 24),
              InkWell(
                onTap: item.showroomId > 0
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ShowroomDetailsScreen(showroomId: item.showroomId)),
                        )
                    : null,
                child: _row('المعرض', '${item.showroomName} ←'),
              ),
              _row('المحافظة', item.provinceName),
              if (canEdit) ...[
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  style: AppTheme.tonalButtonStyle,
                  onPressed: () => _openEdit(context, ref),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('تعديل السيارة'),
                ),
              ],
              if (canContact) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: AppTheme.contactButtonStyle,
                        onPressed: () {
                          ContactLauncher.openPhoneOrNotify(context, item.showroomPhone);
                          repo.trackPhoneClick(carId).catchError((_) {});
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('اتصال', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        style: AppTheme.contactButtonStyle,
                        onPressed: () {
                          ContactLauncher.openWhatsAppOrNotify(context, item.showroomPhone);
                          repo.trackWhatsAppClick(carId).catchError((_) {});
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('واتساب', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ] else if (AppRoles.isSeller(role) && isOwnCar)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: MetallicSilverText(
                    'الاتصال متاح للمشترين على سياراتك',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              if (canFavorite) ...[
                const SizedBox(height: 10),
                favorite.when(
                  data: (isFav) => FilledButton.tonal(
                    style: AppTheme.tonalButtonStyle,
                    onPressed: () async {
                      if (isFav) {
                        await repo.removeFavorite(carId);
                      } else {
                        await repo.addFavorite(carId);
                      }
                      ref.invalidate(isFavoriteProvider(carId));
                      ref.invalidate(favoritesProvider);
                    },
                    child: Text(isFav ? 'إزالة من المفضلة' : 'حفظ في المفضلة'),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: MetallicSilverText('خطأ: $e')),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: MetallicSilverText(value, textAlign: TextAlign.right)),
          const SizedBox(width: 12),
          MetallicSilverText(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
