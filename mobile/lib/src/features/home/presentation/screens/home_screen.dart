import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/home/presentation/providers/home_providers.dart';
import 'package:mobile/src/features/home/presentation/widgets/brands_section.dart';
import 'package:mobile/src/features/home/presentation/widgets/hero_car_image.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statisticsProvider);
    final brands = ref.watch(brandsProvider);
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 430).clamp(0.9, 1.2);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(brandsProvider);
          ref.invalidate(statisticsProvider);
          await Future.wait([
            ref.read(brandsProvider.future),
            ref.read(statisticsProvider.future),
          ]);
        },
        child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF061338), Color(0xFF030B24)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 12 * scale),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.notifications_none_rounded, color: Color(0xFFC8D0D8), size: 28),
                    SizedBox(width: 8),
                    Icon(Icons.account_circle_outlined, color: Color(0xFFC8D0D8), size: 30),
                  ],
                ),
                MetallicSilverText(
                  'سياراتي IQ',
                  style: TextStyle(fontSize: 28 * scale, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            SizedBox(height: 12 * scale),
            HeroCarImage(scale: scale),
            SizedBox(height: 12 * scale),
            stats.when(
              data: (data) => Row(
                children: [
                  _StatCard(value: '+${data.cars}', label: 'سيارة', scale: scale),
                  SizedBox(width: 8 * scale),
                  _StatCard(value: '+${data.exhibitions}', label: 'معرض', scale: scale),
                  SizedBox(width: 8 * scale),
                  _StatCard(value: '${data.provinces}', label: 'محافظة', scale: scale),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => const MetallicSilverText('فشل تحميل الإحصائيات'),
            ),
            SizedBox(height: 18 * scale),
            SizedBox(
              width: double.infinity,
              child: MetallicSilverText(
                'أكبر منصة معارض سيارات\nفي العراق',
                headline: true,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 40 * scale, height: 1.1),
              ),
            ),
            SizedBox(height: 8 * scale),
            MetallicSilverText(
              'اعرض سياراتك ووصل الى آلاف المشترين',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17 * scale, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 14 * scale),
            brands.when(
              data: (items) => BrandsSection(brands: items, scale: scale),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => const MetallicSilverText('فشل تحميل الماركات'),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.scale});

  final String value;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12 * scale),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16 * scale),
          border: Border.all(color: const Color(0xFF8FA3D1).withValues(alpha: 0.3)),
          color: const Color(0xFFCED6EC).withValues(alpha: 0.13),
        ),
        child: Column(
          children: [
            MetallicSilverText(
              value,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20 * scale),
            ),
            MetallicSilverText(
              label,
              style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
