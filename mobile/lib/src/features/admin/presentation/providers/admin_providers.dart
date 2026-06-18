import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/features/home/presentation/providers/home_providers.dart';

final adminDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ref.read(apiClientProvider).dio.get('/admin/dashboard');
  return response.data as Map<String, dynamic>;
});
