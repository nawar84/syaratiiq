import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/exhibitions/presentation/providers/exhibition_providers.dart';
import 'package:mobile/src/features/marketplace/domain/entities/car_listing_entity.dart';
import 'package:mobile/src/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:mobile/src/features/marketplace/presentation/screens/car_detail_screen.dart';
import 'package:mobile/src/features/marketplace/presentation/widgets/car_studio_card.dart';

class CarsBrowseScreen extends ConsumerStatefulWidget {
  const CarsBrowseScreen({super.key});

  @override
  ConsumerState<CarsBrowseScreen> createState() => _CarsBrowseScreenState();
}

class _CarsBrowseScreenState extends ConsumerState<CarsBrowseScreen> {
  final _search = TextEditingController();
  final _carType = TextEditingController();
  final _model = TextEditingController();
  final _color = TextEditingController();
  int? _provinceId;
  CarSearchFilters? _filters;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    _carType.dispose();
    _model.dispose();
    _color.dispose();
    super.dispose();
  }

  CarSearchFilters _buildFilters() {
    return CarSearchFilters(
      search: _search.text.trim().isEmpty ? null : _search.text.trim(),
      provinceId: _provinceId,
      brand: _carType.text.trim().isEmpty ? null : _carType.text.trim(),
      model: _model.text.trim().isEmpty ? null : _model.text.trim(),
      color: _color.text.trim().isEmpty ? null : _color.text.trim(),
    );
  }

  void _applyFilters({bool keepKeyboard = false}) {
    if (!keepKeyboard) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    final next = _buildFilters();
    setState(() => _filters = next);
    ref.invalidate(carSearchProvider(next));
  }

  void _onFilterChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _applyFilters(keepKeyboard: true),
    );
  }

  void _clearFilters() {
    _search.clear();
    _carType.clear();
    _model.clear();
    _color.clear();
    setState(() {
      _provinceId = null;
      _filters = null;
    });
    ref.invalidate(carSearchProvider(const CarSearchFilters()));
  }

  @override
  Widget build(BuildContext context) {
    final filters = _filters ?? const CarSearchFilters();
    final cars = ref.watch(carSearchProvider(filters));
    final provinces = ref.watch(provincesProvider);
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 430).clamp(0.9, 1.2);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF061338), Color(0xFF030B24)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(14 * scale, 14 * scale, 14 * scale, 0),
            child: MetallicSilverText(
              'السيارات',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22 * scale, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(height: 10 * scale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14 * scale),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  textDirection: MetallicSilverText.inputDirection,
                  textAlign: MetallicSilverText.inputAlign,
                  style: MetallicSilverText.inputStyle,
                  decoration: MetallicSilverText.inputDecoration('بحث — عربي / English'),
                  onChanged: _onFilterChanged,
                  onSubmitted: (_) => _applyFilters(),
                ),
                SizedBox(height: 10 * scale),
                Row(
                  children: [
                    Expanded(
                      child: provinces.when(
                        data: (items) => DropdownButtonFormField<int>(
                          value: _provinceId,
                          isExpanded: true,
                          style: AppTheme.orangeTextStyle,
                          decoration: MetallicSilverText.inputDecoration('المحافظة'),
                          selectedItemBuilder: (context) => [
                            const Text('الكل'),
                            ...items.map((p) => Text(p.name)),
                          ],
                          items: [
                            const DropdownMenuItem(value: null, child: Text('الكل')),
                            ...items.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                          ],
                          onChanged: (v) => setState(() => _provinceId = v),
                        ),
                        loading: () => const SizedBox(height: 56, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: TextField(
                        controller: _carType,
                        textDirection: MetallicSilverText.inputDirection,
                        textAlign: MetallicSilverText.inputAlign,
                        style: MetallicSilverText.inputStyle,
                        decoration: MetallicSilverText.inputDecoration('الماركة — Kia أو كيا'),
                        onChanged: _onFilterChanged,
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10 * scale),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _model,
                        textDirection: MetallicSilverText.inputDirection,
                        textAlign: MetallicSilverText.inputAlign,
                        style: MetallicSilverText.inputStyle,
                        decoration: MetallicSilverText.inputDecoration('الموديل'),
                        onChanged: _onFilterChanged,
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: TextField(
                        controller: _color,
                        textDirection: MetallicSilverText.inputDirection,
                        textAlign: MetallicSilverText.inputAlign,
                        style: MetallicSilverText.inputStyle,
                        decoration: MetallicSilverText.inputDecoration('اللون'),
                        onChanged: _onFilterChanged,
                        onSubmitted: (_) => _applyFilters(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10 * scale),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearFilters,
                        child: const Text('مسح'),
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _applyFilters,
                        child: const Text('تطبيق الفلتر'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10 * scale),
          Expanded(
            child: cars.when(
              data: (items) => items.isEmpty
                  ? const Center(child: MetallicSilverText('لا توجد سيارات مطابقة'))
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(carSearchProvider(filters)),
                      child: GridView.builder(
                        padding: EdgeInsets.all(14 * scale),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12 * scale,
                          mainAxisSpacing: 12 * scale,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final car = items[i];
                          return CarStudioCard(
                            car: car,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CarDetailScreen(carId: car.id)),
                            ),
                          );
                        },
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: MetallicSilverText('فشل تحميل السيارات: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
