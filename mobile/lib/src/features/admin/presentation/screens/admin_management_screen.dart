import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/auth/app_roles.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/src/features/admin/presentation/screens/seller_accounts_tab.dart';
import 'package:mobile/src/features/home/presentation/providers/home_providers.dart';

final adminUsersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await ref.read(apiClientProvider).dio.get('/admin/users');
  final payload = response.data as Map<String, dynamic>;
  return List<Map<String, dynamic>>.from(payload['data'] as List? ?? []);
});

final adminShowroomsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await ref.read(apiClientProvider).dio.get('/admin/showrooms');
  final payload = response.data as Map<String, dynamic>;
  return List<Map<String, dynamic>>.from(payload['data'] as List? ?? []);
});

final adminCarsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await ref.read(apiClientProvider).dio.get('/admin/cars');
  final payload = response.data as Map<String, dynamic>;
  return List<Map<String, dynamic>>.from(payload['data'] as List? ?? []);
});

final adminSubscriptionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await ref.read(apiClientProvider).dio.get('/admin/subscriptions');
  final payload = response.data as Map<String, dynamic>;
  return List<Map<String, dynamic>>.from(payload['data'] as List? ?? []);
});

final adminRevenueProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response = await ref.read(apiClientProvider).dio.get('/admin/revenue');
  return response.data as Map<String, dynamic>;
});

class AdminManagementScreen extends ConsumerWidget {
  const AdminManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).asData?.value;
    if (session == null || !AppRoles.isAdmin(session.role)) {
      return const Scaffold(
        body: Center(child: MetallicSilverText('غير مصرح — هذه الصفحة للأدمن فقط')),
      );
    }

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const MetallicSilverText('إدارة المنصة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'المستخدمون'),
              Tab(text: 'حسابات البائعين'),
              Tab(text: 'المعارض'),
              Tab(text: 'السيارات'),
              Tab(text: 'الاشتراكات'),
              Tab(text: 'الإيرادات'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UsersTab(),
            SellerAccountsTab(),
            _ShowroomsTab(),
            _CarsTab(),
            _SubscriptionsTab(),
            _RevenueTab(),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  Future<void> _updateRole(WidgetRef ref, int userId, String role) async {
    await ref.read(apiClientProvider).dio.put('/admin/users/$userId/role', data: {'role': role});
    ref.invalidate(adminUsersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).asData?.value;
    final users = ref.watch(adminUsersProvider);
    return users.when(
      data: (items) => ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          final u = items[i];
          final userId = u['id'] as int;
          final currentRole = u['role'] as String? ?? AppRoles.buyer;
          final isSelf = session?.id == userId;
          return ListTile(
            title: MetallicSilverText('${u['name']}', textAlign: TextAlign.right),
            subtitle: MetallicSilverText('${u['phone']} • ${AppRoles.label(currentRole)}', textAlign: TextAlign.right),
            trailing: isSelf
                ? const MetallicSilverText('أنت')
                : DropdownButton<String>(
                    value: currentRole,
                    items: AppRoles.assignableRoles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: MetallicSilverText(AppRoles.label(r)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null || value == currentRole) return;
                      _updateRole(ref, userId, value);
                    },
                  ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: MetallicSilverText('خطأ: $e')),
    );
  }
}

class _ShowroomsTab extends ConsumerWidget {
  const _ShowroomsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(adminShowroomsProvider);
    return items.when(
      data: (list) => ListView.builder(
        itemCount: list.length,
        itemBuilder: (_, i) {
          final s = list[i];
          return ListTile(
            title: MetallicSilverText('${s['name']}', textAlign: TextAlign.right),
            subtitle: MetallicSilverText('${s['address']}', textAlign: TextAlign.right),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: MetallicSilverText('خطأ: $e')),
    );
  }
}

class _CarsTab extends ConsumerWidget {
  const _CarsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(adminCarsProvider);
    return items.when(
      data: (list) => ListView.builder(
        itemCount: list.length,
        itemBuilder: (_, i) {
          final c = list[i];
          return ListTile(
            title: MetallicSilverText('${c['display_title'] ?? c['name']}', textAlign: TextAlign.right),
            subtitle: MetallicSilverText('\$${c['price']}', textAlign: TextAlign.right),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: MetallicSilverText('خطأ: $e')),
    );
  }
}

class _SubscriptionsTab extends ConsumerWidget {
  const _SubscriptionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(adminSubscriptionsProvider);
    return items.when(
      data: (list) => ListView.builder(
        itemCount: list.length,
        itemBuilder: (_, i) {
          final s = list[i];
          return ListTile(
            title: MetallicSilverText('${s['plan'] ?? 'subscription'}', textAlign: TextAlign.right),
            subtitle: MetallicSilverText('${s['status']} • \$${s['amount']}', textAlign: TextAlign.right),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: MetallicSilverText('خطأ: $e')),
    );
  }
}

class _RevenueTab extends ConsumerWidget {
  const _RevenueTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenue = ref.watch(adminRevenueProvider);
    return revenue.when(
      data: (data) {
        final monthly = data['monthly_reports'] as List? ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MetallicSilverText('إجمالي الإيرادات: \$${data['total_revenue'] ?? 0}', headline: true),
            const SizedBox(height: 16),
            ...monthly.map(
              (m) => ListTile(
                title: MetallicSilverText('${m['month']}', textAlign: TextAlign.right),
                trailing: MetallicSilverText('\$${m['revenue']}'),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: MetallicSilverText('خطأ: $e')),
    );
  }
}
