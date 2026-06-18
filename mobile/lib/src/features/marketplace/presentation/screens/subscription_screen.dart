import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/cars/presentation/providers/car_management_providers.dart';
import 'package:mobile/src/features/marketplace/presentation/providers/marketplace_providers.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exhibitions = ref.watch(myExhibitionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const MetallicSilverText('اشتراك المعرض', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: exhibitions.when(
        data: (items) => items.isEmpty
            ? const Center(child: MetallicSilverText('لا يوجد معرض — أنشئ معرضًا أولاً'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final ex = items[i];
                  final status = ref.watch(subscriptionStatusProvider(ex.id));
                  return Card(
                    color: const Color(0xFF0B1D48),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: status.when(
                        data: (sub) => Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(ex.name, style: AppTheme.orangeTextStyle.copyWith(fontWeight: FontWeight.w700, fontSize: 18)),
                            const SizedBox(height: 8),
                            Text(
                              sub.canManageCars ? 'الاشتراك نشط' : 'الاشتراك منتهي — المعرض غير نشط',
                              style: TextStyle(
                                color: sub.canManageCars ? const Color(0xFF4ADE80) : const Color(0xFFFF6B6B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (sub.expiresAt != null)
                              Text(
                                'ينتهي: ${DateFormat('yyyy-MM-dd').format(sub.expiresAt!)}',
                                style: AppTheme.orangeTextStyle.copyWith(fontSize: 13),
                              ),
                            const SizedBox(height: 12),
                            if (!sub.canManageCars)
                              FilledButton(
                                onPressed: () async {
                                  await ref.read(marketplaceRepositoryProvider).renewSubscription(ex.id);
                                  ref.invalidate(subscriptionStatusProvider(ex.id));
                                  ref.invalidate(myExhibitionsProvider);
                                },
                                child: const Text('تجديد الاشتراك'),
                              ),
                          ],
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => MetallicSilverText('خطأ: $e'),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: MetallicSilverText('خطأ: $e')),
      ),
    );
  }
}
