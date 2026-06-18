import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/src/core/auth/app_permissions.dart';
import 'package:mobile/src/core/auth/app_roles.dart';
import 'package:mobile/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/src/features/cars/presentation/providers/car_management_providers.dart';
import 'package:mobile/src/core/network/api_error.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/features/exhibitions/domain/entities/province_entity.dart';
import 'package:mobile/src/features/exhibitions/presentation/providers/exhibition_providers.dart';
import 'package:mobile/src/features/home/presentation/providers/home_providers.dart';
import 'package:mobile/src/features/marketplace/presentation/screens/showroom_details_screen.dart';

/// High-contrast form styling — white text on dark blue, no shader effects.
class _FormStyles {
  static const fieldStyle = AppTheme.orangeTextStyle;

  static InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.contactOrange, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFF1A3058),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4A6FA5), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
      ),
    );
  }
}

class AddExhibitionScreen extends ConsumerStatefulWidget {
  const AddExhibitionScreen({super.key, this.embedded = false});

  /// When true, renders without [Scaffold] (used inside main app shell).
  final bool embedded;

  @override
  ConsumerState<AddExhibitionScreen> createState() => _AddExhibitionScreenState();
}

class _AddExhibitionScreenState extends ConsumerState<AddExhibitionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _logo = TextEditingController();
  final _description = TextEditingController();
  ProvinceEntity? _selectedProvince;
  XFile? _logoFile;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(authSessionProvider).asData?.value;
      if (session != null && session.name.isNotEmpty && _owner.text.isEmpty) {
        _owner.text = session.name;
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _owner.dispose();
    _phone.dispose();
    _address.dispose();
    _logo.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedProvince == null) {
      if (_selectedProvince == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار المحافظة')),
        );
      }
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(exhibitionRepositoryProvider).addExhibition(
            name: _name.text.trim(),
            ownerName: _owner.text.trim(),
            phone: _phone.text.trim(),
            provinceId: _selectedProvince!.id,
            address: _address.text.trim(),
            logoFile: _logoFile,
            logoUrl: _logo.text.trim().isEmpty ? null : _logo.text.trim(),
            description: _description.text.trim().isEmpty ? null : _description.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة المعرض بنجاح')),
        );
        _formKey.currentState!.reset();
        _name.clear();
        _owner.clear();
        _phone.clear();
        _address.clear();
        _logo.clear();
        _description.clear();
        setState(() {
          _selectedProvince = null;
          _logoFile = null;
        });
        if (!widget.embedded) Navigator.of(context).pop(true);
      }
      ref.invalidate(statisticsProvider);
      ref.invalidate(exhibitionsProvider);
      ref.invalidate(myExhibitionsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(parseApiError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).asData?.value;
    final role = session?.role ?? AppRoles.buyer;
    final myExhibitions = AppRoles.isSeller(role) ? ref.watch(myExhibitionsProvider) : null;

    if (AppRoles.isSeller(role)) {
      return myExhibitions!.when(
        loading: () => _wrap(const Center(child: CircularProgressIndicator())),
        error: (e, _) => _wrap(Center(child: Text('خطأ: $e', style: const TextStyle(color: Colors.white)))),
        data: (list) {
          if (!AppPermissions.canAddShowroom(role, list.length)) {
            final showroom = list.first;
            return _wrap(
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_outlined, size: 56, color: Color(0xFF8FA3D1)),
                      const SizedBox(height: 16),
                      const Text(
                        'لديك معرض مسجّل بالفعل',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'يمكن للبائع تسجيل معرض واحد فقط.\nرقم المعرض: ${showroom.phone}\n${showroom.name}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFADB5BD), fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ShowroomDetailsScreen(showroomId: showroom.id)),
                        ),
                        child: const Text('عرض معرضي'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return _buildForm(context);
        },
      );
    }

    return _buildForm(context);
  }

  Widget _wrap(Widget child) {
    if (widget.embedded) {
      return Material(color: const Color(0xFF040F2E), child: child);
    }
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF040F2E),
      appBar: AppBar(
        title: const Text('إضافة معرض', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: child,
    );
  }

  Widget _buildForm(BuildContext context) {
    final provinces = ref.watch(provincesProvider);
    final form = provinces.when(
      data: (items) => Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            if (widget.embedded)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'إضافة معرضك',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            _field(
              _name,
              'اسم المعرض *',
              hint: 'اكتب اسم المعرض بحرية',
            ),
            _field(_owner, 'اسم المالك *'),
            _field(_phone, 'رقم الهاتف *', keyboard: TextInputType.phone),
            DropdownButtonFormField<ProvinceEntity>(
              value: _selectedProvince,
              decoration: _FormStyles.decoration('المحافظة *'),
              dropdownColor: const Color(0xFF1A3058),
              style: _FormStyles.fieldStyle,
              items: items
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedProvince = value),
              validator: (value) => value == null ? 'اختر المحافظة' : null,
            ),
            const SizedBox(height: 12),
            _field(_address, 'العنوان *'),
            _field(_logo, 'رابط شعار المعرض (اختياري)', required: false),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.tonal(
                  style: AppTheme.tonalButtonStyle,
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (picked != null) setState(() => _logoFile = picked);
                  },
                  child: const Text('اختيار صورة الشعار'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _logoFile?.name ?? 'لم يتم اختيار صورة',
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.orangeTextStyle.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(_description, 'الوصف', maxLines: 4, required: false),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'جاري الحفظ...' : 'حفظ المعرض'),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('فشل تحميل المحافظات: $error', style: const TextStyle(color: Colors.white))),
    );

    if (widget.embedded) {
      return Material(
        color: const Color(0xFF040F2E),
        child: form,
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF040F2E),
      appBar: AppBar(
        title: const Text('إضافة معرض', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: form,
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool required = true,
    TextInputType? keyboard,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: _FormStyles.fieldStyle,
        cursorColor: Colors.white,
        enableInteractiveSelection: true,
        readOnly: false,
        enableSuggestions: false,
        autocorrect: false,
        decoration: _FormStyles.decoration(label).copyWith(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.contactOrange.withValues(alpha: 0.65)),
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty ? 'حقل مطلوب' : null
            : null,
      ),
    );
  }
}
