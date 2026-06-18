import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/auth/presentation/providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.isSeller = false,
  });

  final bool isSeller;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _username = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  int _step = 0;
  bool _loading = false;
  String? _error;
  String? _info;
  String? _debugCode;

  @override
  void dispose() {
    _phone.dispose();
    _username.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });

    try {
      final result = await ref.read(authRepositoryProvider).requestPasswordReset(
            phone: widget.isSeller ? null : _phone.text.trim(),
            username: widget.isSeller ? _username.text.trim() : null,
          );
      setState(() {
        _step = 1;
        _info = result['message'] as String? ?? 'تم إرسال رمز التحقق.';
        _debugCode = result['debug_code'] as String?;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).resetPassword(
            phone: widget.isSeller ? null : _phone.text.trim(),
            username: widget.isSeller ? _username.text.trim() : null,
            code: _code.text.trim(),
            password: _password.text.trim(),
            passwordConfirmation: _confirm.text.trim(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث كلمة المرور. يمكنك تسجيل الدخول الآن.')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MetallicSilverText(
          'نسيت كلمة المرور',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
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
                    MetallicSilverText(
                      _step == 0
                          ? 'أدخل ${widget.isSeller ? 'اسم المستخدم' : 'رقم الهاتف'} لإرسال رمز التحقق عبر SMS'
                          : 'أدخل رمز التحقق وكلمة المرور الجديدة',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (_step == 0) ...[
                      if (widget.isSeller)
                        _input(_username, 'اسم المستخدم')
                      else
                        _input(_phone, 'رقم الهاتف', keyboardType: TextInputType.phone),
                    ] else ...[
                      if (_info != null) ...[
                        MetallicSilverText(_info!, textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                      ],
                      if (_debugCode != null) ...[
                        MetallicSilverText(
                          'رمز التطوير: $_debugCode',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _input(_code, 'رمز التحقق (6 أرقام)', keyboardType: TextInputType.number),
                      _input(_password, 'كلمة المرور الجديدة', obscureText: true),
                      _input(_confirm, 'تأكيد كلمة المرور', obscureText: true),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      MetallicSilverText(_error!, style: const TextStyle(fontSize: 13)),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : (_step == 0 ? _requestCode : _resetPassword),
                      child: Text(_loading ? 'يرجى الانتظار...' : (_step == 0 ? 'إرسال الرمز' : 'تحديث كلمة المرور')),
                    ),
                    if (_step == 1) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() {
                                  _step = 0;
                                  _code.clear();
                                }),
                        child: const Text('تغيير رقم الهاتف / اسم المستخدم'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: MetallicSilverText.inputStyle,
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'حقل مطلوب' : null,
        decoration: MetallicSilverText.inputDecoration(label),
      ),
    );
  }
}
