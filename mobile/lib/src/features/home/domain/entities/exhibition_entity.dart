class ExhibitionEntity {
  const ExhibitionEntity({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.address,
    this.logo,
  });

  final int id;
  final String name;
  final String ownerName;
  final String address;
  final String? logo;

  factory ExhibitionEntity.fromJson(Map<String, dynamic> json) {
    return ExhibitionEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      ownerName: json['owner_name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      logo: json['logo'] as String?,
    );
  }
}
