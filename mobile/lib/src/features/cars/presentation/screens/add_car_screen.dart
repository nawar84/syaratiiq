import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/src/core/network/api_error.dart';
import 'package:mobile/src/core/widgets/app_network_image.dart';
import 'package:mobile/src/core/utils/local_file_image.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/cars/domain/entities/car_management_entities.dart';
import 'package:mobile/src/features/cars/presentation/providers/car_management_providers.dart';
import 'package:mobile/src/features/home/presentation/providers/home_providers.dart';
import 'package:mobile/src/features/marketplace/presentation/providers/marketplace_providers.dart';

class AddCarScreen extends ConsumerStatefulWidget {
  const AddCarScreen({super.key, this.car});

  final OwnerCar? car;

  @override
  ConsumerState<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends ConsumerState<AddCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brand = TextEditingController();
  final _name = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _price = TextEditingController();
  final _color = TextEditingController();
  final _mileage = TextEditingController();
  final _description = TextEditingController();
  final _damageNotes = TextEditingController();
  final _brandFocus = FocusNode();
  final _picker = ImagePicker();
  final _pickedImages = <XFile>[];
  final _keptExistingImages = <String>[];

  OwnerExhibition? _exhibition;
  String? _fuelType;
  String? _transmission;
  bool _saving = false;

  bool get _isEdit => widget.car != null;

  @override
  void initState() {
    super.initState();
    final car = widget.car;
    if (car != null) {
      _brand.text = car.brandName;
      _name.text = car.name;
      _model.text = car.model;
      _year.text = car.year.toString();
      _price.text = car.price.toStringAsFixed(0);
      _color.text = car.color;
      _mileage.text = car.mileage > 0 ? car.mileage.toString() : '';
      _description.text = car.description;
      _damageNotes.text = car.damageNotes;
      _fuelType = car.fuelType.isNotEmpty ? car.fuelType : null;
      _transmission = car.transmission.isNotEmpty ? car.transmission : null;
      _keptExistingImages.addAll(car.images);
    }
  }

  @override
  void dispose() {
    _brand.dispose();
    _name.dispose();
    _model.dispose();
    _year.dispose();
    _price.dispose();
    _color.dispose();
    _mileage.dispose();
    _description.dispose();
    _damageNotes.dispose();
    _brandFocus.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final files = await _picker.pickMultiImage();
    if (files.isNotEmpty) {
      setState(() => _pickedImages.addAll(files));
    }
  }

  Future<void> _pickFromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() => _pickedImages.add(file));
    }
  }

  Future<void> _showImageSourcePicker() async {
    if (_saving) return;

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
              title: const Text('اختيار من المعرض', style: AppTheme.orangeTextStyle),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (!mounted || source == null) return;

    if (source == ImageSource.camera) {
      await _pickFromCamera();
    } else {
      await _pickFromGallery();
    }
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  int? _resolveBrandId(List<CarBrand> brands, String text) {
    final trimmed = text.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    for (final brand in brands) {
      if (brand.name.toLowerCase() == trimmed) {
        return brand.id;
      }
    }
    return null;
  }

  String? _resolveBrandName(List<CarBrand> brands, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (_resolveBrandId(brands, trimmed) != null) return null;
    return trimmed;
  }

  Future<void> _save(List<CarBrand> brands) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final ds = ref.read(carRemoteDataSourceProvider);
      final brandText = _brand.text.trim();
      final brandId = _resolveBrandId(brands, brandText);
      final brandName = _resolveBrandName(brands, brandText);
      final name = _optionalText(_name.text);
      final model = _optionalText(_model.text);
      final year = int.parse(_year.text.trim());
      final price = double.parse(_price.text.trim());
      final mileage = int.tryParse(_mileage.text.trim());

      if (_isEdit) {
        final car = widget.car!;
        await ds.updateCar(
          id: car.id,
          brandId: brandId ?? (brandName == null ? car.brandId : null),
          brandName: brandName,
          name: name ?? car.name,
          model: model ?? car.model,
          year: year,
          price: price,
          description: _description.text.trim(),
          newImages: _pickedImages,
          keepImages: List<String>.from(_keptExistingImages),
          updateImages: true,
          color: _optionalText(_color.text),
          mileage: mileage,
          fuelType: _fuelType,
          transmission: _transmission,
          damageNotes: _optionalText(_damageNotes.text),
        );
      } else {
        await ds.createCar(
          exhibitionId: _exhibition?.id,
          brandId: brandId,
          brandName: brandName,
          name: name,
          model: model,
          year: year,
          price: price,
          description: _optionalText(_description.text),
          images: _pickedImages,
          color: _optionalText(_color.text),
          mileage: mileage,
          fuelType: _fuelType,
          transmission: _transmission,
          damageNotes: _optionalText(_damageNotes.text),
        );
      }

      ref.invalidate(myCarsProvider);
      ref.invalidate(statisticsProvider);
      ref.invalidate(latestCarsProvider);
      if (_isEdit) {
        ref.invalidate(carDetailProvider(widget.car!.id));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'تم تحديث السيارة بنجاح' : 'تم حفظ السيارة بنجاح'),
        ),
      );
      Navigator.pop(context, true);
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
    final brands = ref.watch(carBrandsProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: MetallicSilverText(
          _isEdit ? 'تعديل سيارة' : 'إضافة سيارة',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: brands.when(
          data: (brandItems) => Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(16, 16, 16, 120 + bottomInset + bottomPadding),
              children: [
                if (_saving) const LinearProgressIndicator(),
                if (_saving) const SizedBox(height: 12),
                if (!_isEdit)
                  exhibitions.when(
                    data: (items) {
                      return DropdownButtonFormField<OwnerExhibition>(
                        value: _exhibition,
                        style: AppTheme.orangeTextStyle,
                        decoration: MetallicSilverText.inputDecoration('المعرض'),
                        hint: const Text('اختياري', style: AppTheme.orangeTextStyle),
                        items: items
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                            .toList(),
                        onChanged: _saving ? null : (v) => setState(() => _exhibition = v),
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => MetallicSilverText('خطأ: $e'),
                  ),
                if (!_isEdit) const SizedBox(height: 12),
                _brandAutocomplete(brandItems),
                const SizedBox(height: 12),
                _field(_name, 'العنوان / الاسم', required: true),
                _field(_model, 'الموديل', required: true),
                _field(
                  _year,
                  'السنة',
                  keyboard: TextInputType.number,
                  required: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'السنة مطلوبة';
                    final year = int.tryParse(value.trim());
                    if (year == null || year < 1950 || year > 2100) {
                      return 'أدخل سنة صحيحة';
                    }
                    return null;
                  },
                ),
                _field(
                  _price,
                  'السعر',
                  keyboard: TextInputType.number,
                  required: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'السعر مطلوب';
                    if (double.tryParse(value.trim()) == null) return 'أدخل سعراً صحيحاً';
                    return null;
                  },
                ),
                _field(_color, 'اللون'),
                _field(_mileage, 'العداد (كم)', keyboard: TextInputType.number),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _fuelType,
                  style: AppTheme.orangeTextStyle,
                  decoration: MetallicSilverText.inputDecoration('نوع الوقود'),
                  hint: const Text('اختياري', style: AppTheme.orangeTextStyle),
                  items: const [
                    DropdownMenuItem(value: 'بنزين', child: Text('بنزين')),
                    DropdownMenuItem(value: 'ديزل', child: Text('ديزل')),
                    DropdownMenuItem(value: 'هجين', child: Text('هجين')),
                    DropdownMenuItem(value: 'كهرباء', child: Text('كهرباء')),
                  ],
                  onChanged: _saving ? null : (v) => setState(() => _fuelType = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _transmission,
                  style: AppTheme.orangeTextStyle,
                  decoration: MetallicSilverText.inputDecoration('ناقل الحركة'),
                  hint: const Text('اختياري', style: AppTheme.orangeTextStyle),
                  items: const [
                    DropdownMenuItem(value: 'أوتوماتيك', child: Text('أوتوماتيك')),
                    DropdownMenuItem(value: 'يدوي', child: Text('يدوي')),
                  ],
                  onChanged: _saving ? null : (v) => setState(() => _transmission = v),
                ),
                const SizedBox(height: 12),
                _field(_description, 'الوصف', maxLines: 4),
                _field(_damageNotes, 'ملاحظات الأضرار', maxLines: 3),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.tonal(
                      style: AppTheme.tonalButtonStyle,
                      onPressed: _saving ? null : _showImageSourcePicker,
                      child: const Text('إضافة صور'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickFromCamera,
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('كاميرا'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _pickFromGallery,
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text('معرض'),
                    ),
                    Text(
                      '${_pickedImages.length} صورة جديدة',
                      style: AppTheme.orangeTextStyle,
                    ),
                  ],
                ),
                if (_pickedImages.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _imagePreviewRow(
                    itemCount: _pickedImages.length,
                    builder: (index) => _localImagePreview(_pickedImages[index].path),
                    onRemove: (index) => setState(() => _pickedImages.removeAt(index)),
                  ),
                ],
                if (_isEdit && _keptExistingImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('الصور الحالية: ${_keptExistingImages.length}', style: AppTheme.orangeTextStyle),
                  const SizedBox(height: 8),
                  _imagePreviewRow(
                    itemCount: _keptExistingImages.length,
                    builder: (index) => _networkImagePreview(_keptExistingImages[index]),
                    onRemove: (index) => setState(() => _keptExistingImages.removeAt(index)),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : () => _save(brandItems),
                  child: Text(_saving ? 'جاري الحفظ...' : (_isEdit ? 'تحديث' : 'حفظ السيارة')),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: MetallicSilverText('خطأ: $e')),
        ),
      ),
    );
  }

  Widget _brandAutocomplete(List<CarBrand> brands) {
    return RawAutocomplete<CarBrand>(
      textEditingController: _brand,
      focusNode: _brandFocus,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) {
          return brands;
        }
        return brands.where((brand) => brand.name.toLowerCase().contains(query));
      },
      displayStringForOption: (option) => option.name,
      onSelected: (option) {
        _brand.text = option.name;
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: MetallicSilverText.inputStyle,
          textAlign: MetallicSilverText.inputAlign,
          textDirection: MetallicSilverText.inputDirection,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'الماركة مطلوبة';
            }
            return null;
          },
          decoration: MetallicSilverText.inputDecoration('الماركة'),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: const Color(0xFF0B1D48),
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, minWidth: 280),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option.name, style: AppTheme.orangeTextStyle),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _imagePreviewRow({
    required int itemCount,
    required Widget Function(int index) builder,
    required void Function(int index) onRemove,
  }) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) => Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: builder(index),
            ),
            if (!_saving)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  onPressed: () => onRemove(index),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _localImagePreview(String path) {
    return Container(
      width: 120,
      height: 120,
      color: const Color(0xFF152A55),
      alignment: Alignment.center,
      child: buildLocalFileImage(path, fit: BoxFit.contain),
    );
  }

  Widget _networkImagePreview(String url) {
    return Container(
      width: 120,
      height: 120,
      color: const Color(0xFF152A55),
      alignment: Alignment.center,
      child: AppNetworkImage(
        url: url,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    int maxLines = 1,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        enabled: !_saving,
        style: MetallicSilverText.inputStyle,
        textAlign: MetallicSilverText.inputAlign,
        textDirection: MetallicSilverText.inputDirection,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator ??
            (value) {
              if (!required) return null;
              if (value == null || value.trim().isEmpty) {
                return '$label مطلوب';
              }
              return null;
            },
        decoration: MetallicSilverText.inputDecoration(label),
      ),
    );
  }
}
