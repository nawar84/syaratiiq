import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/src/core/network/api_error.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/core/utils/local_file_image.dart';
import 'package:mobile/src/core/widgets/app_network_image.dart';
import 'package:mobile/src/features/cars/domain/entities/car_management_entities.dart';
import 'package:mobile/src/features/cars/presentation/providers/car_management_providers.dart';
import 'package:mobile/src/features/exhibitions/presentation/providers/exhibition_providers.dart';
import 'package:mobile/src/features/exhibitions/presentation/screens/add_exhibition_screen.dart';
import 'package:mobile/src/features/home/presentation/providers/home_providers.dart';

class SellerProfileScreen extends ConsumerStatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  ConsumerState<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends ConsumerState<SellerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _owner = TextEditingController();
  final _phone = TextEditingController();
  final _picker = ImagePicker();

  OwnerExhibition? _exhibition;
  XFile? _newLogoFile;
  bool _removeLogo = false;
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _owner.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _loadExhibition(OwnerExhibition exhibition) {
    if (_loaded && _exhibition?.id == exhibition.id) return;
    _exhibition = exhibition;
    _name.text = exhibition.name;
    _owner.text = exhibition.ownerName;
    _phone.text = exhibition.phone;
    _newLogoFile = null;
    _removeLogo = false;
    _loaded = true;
  }

  Future<void> _pickLogo(ImageSource source) async {
    if (_saving) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() {
        _newLogoFile = picked;
        _removeLogo = false;
      });
    }
  }

  Future<void> _showLogoSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF0B1D48),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFF7A00)),
              title: const Text('التقاط من الكاميرا', style: AppTheme.orangeTextStyle),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFFF7A00)),
              title: const Text('اختيار من الاستوديو', style: AppTheme.orangeTextStyle),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (!mounted || source == null) return;
    await _pickLogo(source);
  }

  void _clearLogo() {
    setState(() {
      _newLogoFile = null;
      _removeLogo = true;
    });
  }

  Future<void> _save() async {
    if (_exhibition == null || !_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(exhibitionRepositoryProvider).updateExhibition(
            id: _exhibition!.id,
            name: _name.text.trim(),
            ownerName: _owner.text.trim(),
            phone: _phone.text.trim(),
            logoFile: _newLogoFile,
            removeLogo: _removeLogo,
          );

      ref.invalidate(myExhibitionsProvider);
      ref.invalidate(exhibitionsProvider);
      ref.invalidate(statisticsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ بيانات المعرض')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(parseApiError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exhibitions = ref.watch(myExhibitionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF040F2E),
      appBar: AppBar(
        title: const Text('بروفايل المعرض', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: exhibitions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('خطأ: $e', style: const TextStyle(color: Colors.white)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_outlined, size: 56, color: Color(0xFF8FA3D1)),
                    const SizedBox(height: 16),
                    const Text(
                      'لا يوجد معرض مسجّل',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AddExhibitionScreen()),
                      ),
                      child: const Text('إضافة معرض'),
                    ),
                  ],
                ),
              ),
            );
          }

          _loadExhibition(list.first);

          final hasExistingLogo = !_removeLogo && _newLogoFile == null && (_exhibition?.logoUrl?.isNotEmpty ?? false);

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      GestureDetector(
                        onTap: _showLogoSourcePicker,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF8FA3D1), width: 2),
                            color: const Color(0xFF152A55),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _newLogoFile != null
                              ? buildLocalFileImage(_newLogoFile!.path, fit: BoxFit.cover)
                              : hasExistingLogo
                                  ? AppNetworkImage(url: _exhibition!.logoUrl!, fit: BoxFit.cover)
                                  : const Icon(Icons.storefront_outlined, size: 48, color: Color(0xFF8FA3D1)),
                        ),
                      ),
                      if (hasExistingLogo || _newLogoFile != null)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B6B),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(32, 32),
                            ),
                            iconSize: 18,
                            onPressed: _saving ? null : _clearLogo,
                            icon: const Icon(Icons.close),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _saving ? null : _showLogoSourcePicker,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('تغيير شعار المعرض'),
                  ),
                ),
                const SizedBox(height: 20),
                _field(_name, 'اسم المعرض'),
                _field(_owner, 'اسم صاحب المعرض'),
                _field(_phone, 'رقم المعرض', keyboard: TextInputType.phone),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'جاري الحفظ...' : 'حفظ التعديلات'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        style: AppTheme.orangeTextStyle,
        cursorColor: Colors.white,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.contactOrange, fontSize: 14),
          filled: true,
          fillColor: const Color(0xFF1A3058),
          suffixIcon: IconButton(
            tooltip: 'مسح',
            icon: const Icon(Icons.clear, color: Color(0xFFADB5BD)),
            onPressed: () => setState(() => controller.clear()),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF4A6FA5), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
        validator: (value) => value == null || value.trim().isEmpty ? 'حقل مطلوب' : null,
      ),
    );
  }
}
