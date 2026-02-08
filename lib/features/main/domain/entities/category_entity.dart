class CategoryEntity {
  final int id;
  final String name;
  final String description;
  final String? image;
  final String station;
  final bool isActive;

  CategoryEntity({
    required this.id,
    required this.name,
    required this.description,
    this.image,
    required this.station,
    required this.isActive,
  });
}