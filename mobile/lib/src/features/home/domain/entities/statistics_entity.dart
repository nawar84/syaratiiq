class StatisticsEntity {
  const StatisticsEntity({
    required this.provinces,
    required this.exhibitions,
    required this.cars,
  });

  final int provinces;
  final int exhibitions;
  final int cars;

  factory StatisticsEntity.fromJson(Map<String, dynamic> json) {
    return StatisticsEntity(
      provinces: (json['provinces'] ?? 18) as int,
      exhibitions: (json['exhibitions'] ?? 0) as int,
      cars: (json['cars'] ?? 0) as int,
    );
  }
}
