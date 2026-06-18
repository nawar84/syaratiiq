import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/marketplace/presentation/providers/marketplace_providers.dart';

class OwnerAnalyticsScreen extends ConsumerWidget {
  const OwnerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(ownerAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const MetallicSilverText('إحصائيات السيارات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: analytics.when(
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(ownerAnalyticsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _statCard('إجمالي السيارات', '${data.totalCars}'),
                  _statCard('المشاهدات', '${data.totalViews}'),
                  _statCard('نقرات الاتصال', '${data.totalPhoneClicks}'),
                  _statCard('نقرات واتساب', '${data.totalWhatsappClicks}'),
                ],
              ),
              const SizedBox(height: 20),
              MetallicSilverText('تفاصيل كل سيارة', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 10),
              ...data.cars.map(
                (car) => Card(
                  color: const Color(0xFF0B1D48),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(car.title, style: AppTheme.orangeTextStyle.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          '${car.brandName} • ${car.showroomName}',
                          style: AppTheme.orangeTextStyle.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _miniStat(Icons.visibility_outlined, '${car.viewsCount}'),
                            _miniStat(Icons.phone_outlined, '${car.phoneClicksCount}'),
                            _miniStat(Icons.chat_outlined, '${car.whatsappClicksCount}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: MetallicSilverText('خطأ: $e')),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF0B1D48),
        border: Border.all(color: const Color(0xFF8FA3D1).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(value, style: AppTheme.orangeTextStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: AppTheme.orangeTextStyle.copyWith(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8A97BF)),
        const SizedBox(width: 4),
        Text(value, style: AppTheme.orangeTextStyle),
      ],
    );
  }
}
