import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/network/api_error.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/src/features/auth/presentation/screens/forgot_password_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool isRegister = false;
  bool isSellerLogin = false;
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final notifier = ref.read(authSessionProvider.notifier);
    if (isRegister) {
      await notifier.register(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text.trim(),
        passwordConfirmation: _confirm.text.trim(),
      );
    } else if (isSellerLogin) {
      await notifier.loginWithUsername(
        username: _username.text.trim(),
        password: _password.text.trim(),
      );
    } else {
      await notifier.loginWithUsername(
        username: _username.text.trim(),
        password: _password.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authSessionProvider);
    final loading = authState.isLoading;
    final error = authState.hasError ? parseApiError(authState.error!) : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MetallicSilverText(
                      'سياراتي IQ',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    MetallicSilverText(
                      isRegister ? 'إنشاء حساب مشتري' : (isSellerLogin ? 'دخول البائع' : 'تسجيل الدخول'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            style: AppTheme.tonalButtonStyle,
                            onPressed: () => setState(() {
                              isRegister = false;
                              isSellerLogin = false;
                            }),
                            child: const Text('دخول'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonal(
                            style: AppTheme.tonalButtonStyle,
                            onPressed: () => setState(() {
                              isRegister = true;
                              isSellerLogin = false;
                            }),
                            child: const Text('تسجيل'),
                          ),
                        ),
                      ],
                    ),
                    if (!isRegister) ...[
                      const SizedBox(height: 10),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('مشتري')),
                          ButtonSegment(value: true, label: Text('بائع')),
                        ],
                        selected: {isSellerLogin},
                        onSelectionChanged: (value) => setState(() => isSellerLogin = value.first),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (isRegister)
                      _input(
                        controller: _name,
                        label: 'الاسم',
                      ),
                    if (isRegister)
                      _input(
                        controller: _phone,
                        label: 'رقم الهاتف',
                        keyboardType: TextInputType.phone,
                      ),
                    if (!isRegister)
                      _input(
                        controller: _username,
                        label: 'اسم المستخدم',
                      ),
                    _input(
                      controller: _password,
                      label: 'كلمة المرور',
                      obscureText: true,
                      validator: isRegister
                          ? (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'حقل مطلوب';
                              }
                              if (value.trim().length < 8) {
                                return '8 أحرف على الأقل';
                              }
                              return null;
                            }
                          : null,
                    ),
                    if (isRegister)
                      _input(
                        controller: _confirm,
                        label: 'تأكيد كلمة المرور',
                        obscureText: true,
                      ),
                    if (isRegister) ...[
                      const SizedBox(height: 4),
                      const MetallicSilverText(
                        'كلمة المرور 8 أحرف على الأقل',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                    if (!isRegister) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(isSeller: isSellerLogin),
                            ),
                          ),
                          child: const Text('نسيت كلمة المرور؟'),
                        ),
                      ),
                    ],
                    if (isRegister) ...[
                      const SizedBox(height: 8),
                      const MetallicSilverText(
                        'التسجيل متاح للمشترين فقط. حسابات البائعين تُنشأ من قبل الإدارة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      MetallicSilverText(
                        error,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: loading ? null : _submit,
                      child: Text(
                        loading ? 'يرجى الانتظار...' : (isRegister ? 'إنشاء الحساب' : 'دخول'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: MetallicSilverText.inputStyle,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator ??
            (value) => value == null || value.trim().isEmpty ? 'حقل مطلوب' : null,
        decoration: MetallicSilverText.inputDecoration(label),
      ),
    );
  }
}
