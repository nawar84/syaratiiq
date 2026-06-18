import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/admin/presentation/providers/seller_account_providers.dart';
import 'package:mobile/src/features/admin/presentation/screens/create_seller_account_screen.dart';
import 'package:mobile/src/features/exhibitions/presentation/providers/exhibition_providers.dart';

class SellerAccountsTab extends ConsumerWidget {
  const SellerAccountsTab({super.key});

  Future<void> _showCredentialsDialog(BuildContext context, String username, String password) {
    final credentials = 'اسم المستخدم:\n$username\n\nكلمة المرور:\n$password';
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const MetallicSilverText('بيانات الدخول', headline: true),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MetallicSilverText('اسم المستخدم:\n$username', textAlign: TextAlign.right),
            const SizedBox(height: 12),
            MetallicSilverText('كلمة المرور:\n$password', textAlign: TextAlign.right),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: credentials));
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('تم نسخ بيانات الدخول')),
                );
              }
            },
            child: const Text('نسخ بيانات الدخول'),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('تم')),
        ],
      ),
    );
  }

  Future<void> _renewSubscription(BuildContext context, WidgetRef ref, int id) async {
    final endController = TextEditingController(
      text: DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T').first,
    );
    final type = ValueNotifier<String>('monthly');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const MetallicSilverText('تجديد الاشتراك'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: endController,
              decoration: const InputDecoration(labelText: 'تاريخ الانتهاء (YYYY-MM-DD)'),
            ),
            ValueListenableBuilder(
              valueListenable: type,
              builder: (_, value, __) => DropdownButtonFormField<String>(
                value: value,
                items: const [
                  DropdownMenuItem(value: 'free_trial', child: Text('تجربة مجانية')),
                  DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                  DropdownMenuItem(value: 'premium', child: Text('مميز')),
                ],
                onChanged: (v) => type.value = v ?? 'monthly',
                decoration: const InputDecoration(labelText: 'نوع الاشتراك'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تجديد')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(sellerAccountActionsProvider).renewSubscription(id, {
        'subscription_end': endController.text.trim(),
        'subscription_type': type.value,
      });
    }
    endController.dispose();
  }

  Future<void> _editAccount(BuildContext context, WidgetRef ref, Map<String, dynamic> account) async {
    final id = account['id'] as int;
    final showroomController = TextEditingController(text: account['showroom_name']?.toString() ?? '');
    final ownerController = TextEditingController(text: account['owner_name']?.toString() ?? '');
    final phoneController = TextEditingController(text: account['phone']?.toString() ?? '');
    int? provinceId = account['province_id'] as int?;
    final provinces = await ref.read(provincesProvider.future);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const MetallicSilverText('تعديل حساب البائع'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: showroomController, decoration: const InputDecoration(labelText: 'اسم المعرض')),
                TextField(controller: ownerController, decoration: const InputDecoration(labelText: 'اسم المالك')),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'الهاتف')),
                DropdownButtonFormField<int>(
                  value: provinceId,
                  items: provinces
                      .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                      .toList(),
                  onChanged: (v) => setLocal(() => provinceId = v),
                  decoration: const InputDecoration(labelText: 'المحافظة'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await ref.read(sellerAccountActionsProvider).update(id, {
        'showroom_name': showroomController.text.trim(),
        'owner_name': ownerController.text.trim(),
        'phone': phoneController.text.trim(),
        if (provinceId != null) 'province_id': provinceId,
      });
    }

    showroomController.dispose();
    ownerController.dispose();
    phoneController.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(adminSellerAccountsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateSellerAccountScreen()),
        ).then((_) => ref.invalidate(adminSellerAccountsProvider)),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('إنشاء حساب بائع'),
      ),
      body: accounts.when(
        data: (items) => items.isEmpty
            ? const Center(child: MetallicSilverText('لا توجد حسابات بائعين'))
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminSellerAccountsProvider);
                  await ref.read(adminSellerAccountsProvider.future);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final a = items[i];
                    final id = a['id'] as int;
                    final province = a['province'] as Map<String, dynamic>?;
                    final endDate = a['subscription_end']?.toString().split('T').first ?? '—';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        title: MetallicSilverText('${a['showroom_name'] ?? a['owner_name']}', textAlign: TextAlign.right),
                        subtitle: MetallicSilverText(
                          '${a['username']} • ${accountStatusLabel(a['account_status'] as String?)}',
                          textAlign: TextAlign.right,
                        ),
                        children: [
                          ListTile(
                            title: const MetallicSilverText('اسم المستخدم'),
                            trailing: MetallicSilverText('${a['username']}'),
                          ),
                          ListTile(
                            title: const MetallicSilverText('الهاتف'),
                            trailing: MetallicSilverText('${a['phone']}'),
                          ),
                          ListTile(
                            title: const MetallicSilverText('المحافظة'),
                            trailing: MetallicSilverText(province?['name']?.toString() ?? '—'),
                          ),
                          ListTile(
                            title: const MetallicSilverText('نوع الاشتراك'),
                            trailing: MetallicSilverText(subscriptionTypeLabel(a['subscription_type'] as String?)),
                          ),
                          ListTile(
                            title: const MetallicSilverText('تاريخ الانتهاء'),
                            trailing: MetallicSilverText(endDate),
                          ),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            children: [
                              TextButton(onPressed: () => _editAccount(context, ref, a), child: const Text('تعديل')),
                              TextButton(
                                onPressed: () async {
                                  final result = await ref.read(sellerAccountActionsProvider).resetPassword(id);
                                  if (context.mounted) {
                                    await _showCredentialsDialog(
                                      context,
                                      result['username'] as String,
                                      result['password'] as String,
                                    );
                                  }
                                },
                                child: const Text('إعادة كلمة المرور'),
                              ),
                              TextButton(
                                onPressed: () => _renewSubscription(context, ref, id),
                                child: const Text('تجديد'),
                              ),
                              if (a['account_status'] == 'suspended')
                                TextButton(
                                  onPressed: () => ref.read(sellerAccountActionsProvider).activate(id),
                                  child: const Text('تفعيل'),
                                )
                              else
                                TextButton(
                                  onPressed: () => ref.read(sellerAccountActionsProvider).suspend(id),
                                  child: const Text('تعليق'),
                                ),
                              TextButton(
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const MetallicSilverText('حذف الحساب؟'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    await ref.read(sellerAccountActionsProvider).delete(id);
                                  }
                                },
                                child: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: MetallicSilverText('خطأ: $e')),
      ),
    );
  }
}
