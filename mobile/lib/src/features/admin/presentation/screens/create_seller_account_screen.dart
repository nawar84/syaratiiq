import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/admin/presentation/providers/seller_account_providers.dart';
import 'package:mobile/src/features/exhibitions/presentation/providers/exhibition_providers.dart';

class CreateSellerAccountScreen extends ConsumerStatefulWidget {
  const CreateSellerAccountScreen({super.key});

  @override
  ConsumerState<CreateSellerAccountScreen> createState() => _CreateSellerAccountScreenState();
}

class _CreateSellerAccountScreenState extends ConsumerState<CreateSellerAccountScreen> {
  final _form = GlobalKey<FormState>();
  final _showroomName = TextEditingController();
  final _ownerName = TextEditingController();
  final _phone = TextEditingController();
  int? _provinceId;
  String _subscriptionType = 'free_trial';
  DateTime _subscriptionEnd = DateTime.now().add(const Duration(days: 30));
  bool _loading = false;

  @override
  void dispose() {
    _showroomName.dispose();
    _ownerName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _subscriptionEnd,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _subscriptionEnd = picked);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate() || _provinceId == null) {
      if (_provinceId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اختر المحافظة')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ref.read(sellerAccountActionsProvider).create({
        'showroom_name': _showroomName.text.trim(),
        'owner_name': _ownerName.text.trim(),
        'phone': _phone.text.trim(),
        'province_id': _provinceId,
        'subscription_type': _subscriptionType,
        'subscription_end': _subscriptionEnd.toIso8601String().split('T').first,
      });

      if (!mounted) return;
      await _showCredentialsDialog(
        username: result['username'] as String,
        password: result['password'] as String,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCredentialsDialog({
    required String username,
    required String password,
  }) async {
    final credentials = 'اسم المستخدم:\n$username\n\nكلمة المرور:\n$password';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const MetallicSilverText('تم إنشاء حساب البائع', headline: true),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(),
            MetallicSilverText('اسم المستخدم:\n$username', textAlign: TextAlign.right),
            const SizedBox(height: 12),
            MetallicSilverText('كلمة المرور:\n$password', textAlign: TextAlign.right),
            const Divider(),
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
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provinces = ref.watch(provincesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const MetallicSilverText('إنشاء حساب بائع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_showroomName, 'اسم المعرض'),
            _field(_ownerName, 'اسم المالك'),
            _field(_phone, 'رقم الهاتف', keyboardType: TextInputType.phone),
            provinces.when(
              data: (list) => DropdownButtonFormField<int>(
                decoration: MetallicSilverText.inputDecoration('المحافظة'),
                initialValue: _provinceId,
                items: list
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _provinceId = value),
                validator: (value) => value == null ? 'اختر المحافظة' : null,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => MetallicSilverText('خطأ: $e'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: MetallicSilverText.inputDecoration('نوع الاشتراك'),
              initialValue: _subscriptionType,
              items: const [
                DropdownMenuItem(value: 'free_trial', child: Text('تجربة مجانية')),
                DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                DropdownMenuItem(value: 'premium', child: Text('مميز')),
              ],
              onChanged: (value) => setState(() => _subscriptionType = value ?? 'free_trial'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const MetallicSilverText('تاريخ انتهاء الاشتراك'),
              subtitle: MetallicSilverText(
                '${_subscriptionEnd.year}-${_subscriptionEnd.month.toString().padLeft(2, '0')}-${_subscriptionEnd.day.toString().padLeft(2, '0')}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickEndDate,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'جاري الإنشاء...' : 'إنشاء حساب البائع'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: MetallicSilverText.inputDecoration(label),
        validator: (v) => v == null || v.trim().isEmpty ? 'حقل مطلوب' : null,
      ),
    );
  }
}
