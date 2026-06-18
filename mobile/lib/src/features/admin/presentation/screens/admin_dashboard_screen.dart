import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/auth/app_roles.dart';
import 'package:mobile/src/core/theme/app_theme.dart';
import 'package:mobile/src/core/theme/metallic_silver_text.dart';
import 'package:mobile/src/features/admin/presentation/providers/admin_providers.dart';
import 'package:mobile/src/features/auth/presentation/providers/auth_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).asData?.value;
    if (session == null || !AppRoles.isAdmin(session.role)) {
      return const Scaffold(
        body: Center(child: MetallicSilverText('غير مصرح — هذه الصفحة للأدمن فقط')),
      );
    }

    final dashboard = ref.watch(adminDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const MetallicSilverText(
          'لوحة تحكم الإدارة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: dashboard.when(
        data: (data) {
          final cards = data['cards'] as Map<String, dynamic>;
          final charts = data['charts'] as Map<String, dynamic>;
          final carsPerProvince = charts['cars_per_province'] as List<dynamic>;
          final exhibitionsPerProvince = charts['exhibitions_per_province'] as List<dynamic>;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _card('إجمالي المحافظات', '${cards['provinces']}'),
                  _card('إجمالي المعارض', '${cards['exhibitions']}'),
                  _card('إجمالي السيارات', '${cards['cars']}'),
                  _card('إجمالي المستخدمين', '${cards['users']}'),
                ],
              ),
              const SizedBox(height: 20),
              _chart(
                'السيارات لكل محافظة',
                carsPerProvince.map((e) => _ChartPoint(e['name'] as String, (e['total'] as num).toDouble())).toList(),
              ),
              const SizedBox(height: 20),
              _chart(
                'المعارض لكل محافظة',
                exhibitionsPerProvince.map((e) => _ChartPoint(e['name'] as String, (e['total'] as num).toDouble())).toList(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: MetallicSilverText('خطأ: $error')),
      ),
    );
  }

  Widget _card(String title, String value) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E4D90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            value,
            style: AppTheme.orangeTextStyle.copyWith(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(title, textAlign: TextAlign.right, style: AppTheme.orangeTextStyle),
        ],
      ),
    );
  }

  Widget _chart(String title, List<_ChartPoint> points) {
    final bars = points.take(8).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D48),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E4D90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            title,
            style: AppTheme.orangeTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  bars.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [BarChartRodData(toY: bars[i].value, color: const Color(0xFF2A62FF), width: 14)],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= bars.length) return const SizedBox.shrink();
                        return Text(
                          bars[i].name.length > 5 ? bars[i].name.substring(0, 5) : bars[i].name,
                          style: AppTheme.orangeTextStyle.copyWith(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPoint {
  _ChartPoint(this.name, this.value);
  final String name;
  final double value;
}
