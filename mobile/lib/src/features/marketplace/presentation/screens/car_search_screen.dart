import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/exhibitions/presentation/providers/exhibition_providers.dart';
import 'package:mobile/src/features/marketplace/domain/entities/car_listing_entity.dart';
import 'package:mobile/src/features/marketplace/domain/entities/showroom_summary_entity.dart';
import 'package:mobile/src/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:mobile/src/features/marketplace/presentation/screens/car_detail_screen.dart';
import 'package:mobile/src/features/marketplace/presentation/widgets/car_studio_card.dart';

class CarSearchScreen extends ConsumerStatefulWidget {
  const CarSearchScreen({super.key, this.initialFilters});

  final CarSearchFilters? initialFilters;

  @override
  ConsumerState<CarSearchScreen> createState() => _CarSearchScreenState();
}

class _CarSearchScreenState extends ConsumerState<CarSearchScreen> {
  final _search = TextEditingController();
  final _carType = TextEditingController();
  final _model = TextEditingController();
  final _color = TextEditingController();
  final _yearMin = TextEditingController();
  final _yearMax = TextEditingController();
  final _priceMin = TextEditingController();
  final _priceMax = TextEditingController();
  int? _provinceId;
  int? _showroomId;
  CarSearchFilters? _filters;

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilters;
    if (f != null) {
      _search.text = f.search ?? '';
      _carType.text = f.brand ?? '';
      _model.text = f.model ?? '';
      _color.text = f.color ?? '';
      _provinceId = f.provinceId;
      _showroomId = f.showroomId;
      if (f.yearMin != null) _yearMin.text = '${f.yearMin}';
      if (f.yearMax != null) _yearMax.text = '${f.yearMax}';
      if (f.priceMin != null) _priceMin.text = '${f.priceMin!.toInt()}';
      if (f.priceMax != null) _priceMax.text = '${f.priceMax!.toInt()}';
      _filters = f;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _carType.dispose();
    _model.dispose();
    _color.dispose();
    _yearMin.dispose();
    _yearMax.dispose();
    _priceMin.dispose();
    _priceMax.dispose();
    super.dispose();
  }

  void _apply() {
    FocusManager.instance.primaryFocus?.unfocus();
    final next = CarSearchFilters(
      search: _search.text.trim().isEmpty ? null : _search.text.trim(),
      provinceId: _provinceId,
      showroomId: _showroomId,
      brand: _carType.text.trim().isEmpty ? null : _carType.text.trim(),
      model: _model.text.trim().isEmpty ? null : _model.text.trim(),
      color: _color.text.trim().isEmpty ? null : _color.text.trim(),
      yearMin: int.tryParse(_yearMin.text.trim()),
      yearMax: int.tryParse(_yearMax.text.trim()),
      priceMin: double.tryParse(_priceMin.text.trim()),
      priceMax: double.tryParse(_priceMax.text.trim()),
    );
    setState(() => _filters = next);
    ref.invalidate(carSearchProvider(next));
  }

  void _clear() {
    _search.clear();
    _carType.clear();
    _model.clear();
    _color.clear();
    _yearMin.clear();
    _yearMax.clear();
    _priceMin.clear();
    _priceMax.clear();
    setState(() {
      _provinceId = null;
      _showroomId = null;
      _filters = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provinces = ref.watch(provincesProvider);
    final showrooms = ref.watch(showroomsListProvider(ShowroomSearchFilters(provinceId: _provinceId)));
    final results = _filters == null ? null : ref.watch(carSearchProvider(_filters!));

    return Scaffold(
      appBar: AppBar(
        title: const MetallicSilverText('بحث وتصفية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(onPressed: _clear, child: const Text('مسح')),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: _filters == null ? 1 : 0,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _search,
                  textDirection: MetallicSilverText.inputDirection,
                  textAlign: MetallicSilverText.inputAlign,
                  style: MetallicSilverText.inputStyle,
                  decoration: MetallicSilverText.inputDecoration('بحث'),
                ),
                const SizedBox(height: 10),
                provinces.when(
                  data: (items) => DropdownButtonFormField<int>(
                    value: _provinceId,
                    style: AppTheme.orangeTextStyle,
                    decoration: MetallicSilverText.inputDecoration('المحافظة'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('الكل')),
                      ...items.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                    ],
                    onChanged: (v) => setState(() {
                      _provinceId = v;
                      _showroomId = null;
                    }),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 10),
                showrooms.when(
                  data: (items) => DropdownButtonFormField<int>(
                    value: _showroomId,
                    style: AppTheme.orangeTextStyle,
                    decoration: MetallicSilverText.inputDecoration('المعرض'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('الكل')),
                      ...items.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (v) => setState(() => _showroomId = v),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _carType,
                  textDirection: MetallicSilverText.inputDirection,
                  textAlign: MetallicSilverText.inputAlign,
                  style: MetallicSilverText.inputStyle,
                  decoration: MetallicSilverText.inputDecoration('نوع السيارة'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _model,
                  textDirection: MetallicSilverText.inputDirection,
                  textAlign: MetallicSilverText.inputAlign,
                  style: MetallicSilverText.inputStyle,
                  decoration: MetallicSilverText.inputDecoration('الموديل'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _color,
                  textDirection: MetallicSilverText.inputDirection,
                  textAlign: MetallicSilverText.inputAlign,
                  style: MetallicSilverText.inputStyle,
                  decoration: MetallicSilverText.inputDecoration('اللون'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _yearMin, keyboardType: TextInputType.number, style: MetallicSilverText.inputStyle, decoration: MetallicSilverText.inputDecoration('السنة من'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _yearMax, keyboardType: TextInputType.number, style: MetallicSilverText.inputStyle, decoration: MetallicSilverText.inputDecoration('السنة إلى'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _priceMin, keyboardType: TextInputType.number, style: MetallicSilverText.inputStyle, decoration: MetallicSilverText.inputDecoration('السعر من'))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: _priceMax, keyboardType: TextInputType.number, style: MetallicSilverText.inputStyle, decoration: MetallicSilverText.inputDecoration('السعر إلى'))),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton(onPressed: _apply, child: const Text('بحث')),
              ],
            ),
          ),
          if (_filters != null)
            Expanded(
              flex: 2,
              child: results!.when(
                data: (cars) => cars.isEmpty
                    ? const Center(child: MetallicSilverText('لا توجد نتائج'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(14),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: cars.length,
                        itemBuilder: (_, i) {
                          final car = cars[i];
                          return CarStudioCard(
                            car: car,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CarDetailScreen(carId: car.id)),
                            ),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: MetallicSilverText('خطأ: $e')),
              ),
            ),
        ],
      ),
    );
  }
}
