import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/features/home/presentation/providers/home_providers.dart';

final adminSellerAccountsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await ref.read(apiClientProvider).dio.get('/admin/seller-accounts');
  final payload = response.data as Map<String, dynamic>;
  return List<Map<String, dynamic>>.from(payload['data'] as List? ?? []);
});

final adminSellerAccountProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, id) async {
  final response = await ref.read(apiClientProvider).dio.get('/admin/seller-accounts/$id');
  return response.data as Map<String, dynamic>;
});

class SellerAccountActions {
  SellerAccountActions(this.ref);

  final Ref ref;

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await ref.read(apiClientProvider).dio.post('/admin/seller-accounts', data: data);
    ref.invalidate(adminSellerAccountsProvider);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final response = await ref.read(apiClientProvider).dio.put('/admin/seller-accounts/$id', data: data);
    ref.invalidate(adminSellerAccountsProvider);
    ref.invalidate(adminSellerAccountProvider(id));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resetPassword(int id) async {
    final response = await ref.read(apiClientProvider).dio.post('/admin/seller-accounts/$id/reset-password');
    ref.invalidate(adminSellerAccountsProvider);
    return response.data as Map<String, dynamic>;
  }

  Future<void> renewSubscription(int id, Map<String, dynamic> data) async {
    await ref.read(apiClientProvider).dio.post('/admin/seller-accounts/$id/renew-subscription', data: data);
    ref.invalidate(adminSellerAccountsProvider);
    ref.invalidate(adminSellerAccountProvider(id));
  }

  Future<void> suspend(int id) async {
    await ref.read(apiClientProvider).dio.post('/admin/seller-accounts/$id/suspend');
    ref.invalidate(adminSellerAccountsProvider);
    ref.invalidate(adminSellerAccountProvider(id));
  }

  Future<void> activate(int id) async {
    await ref.read(apiClientProvider).dio.post('/admin/seller-accounts/$id/activate');
    ref.invalidate(adminSellerAccountsProvider);
    ref.invalidate(adminSellerAccountProvider(id));
  }

  Future<void> delete(int id) async {
    await ref.read(apiClientProvider).dio.delete('/admin/seller-accounts/$id');
    ref.invalidate(adminSellerAccountsProvider);
  }
}

final sellerAccountActionsProvider = Provider<SellerAccountActions>((ref) => SellerAccountActions(ref));

String subscriptionTypeLabel(String? type) {
  return switch (type) {
    'free_trial' => 'تجربة مجانية',
    'monthly' => 'شهري',
    'premium' => 'مميز',
    _ => type ?? '—',
  };
}

String accountStatusLabel(String? status) {
  return switch (status) {
    'active' => 'نشط',
    'expired' => 'منتهي',
    'suspended' => 'معلّق',
    _ => status ?? '—',
  };
}
