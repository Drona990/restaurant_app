class MenuItemEntity {
  final int id;
  final int category;
  final String categoryName;
  final String station;
  final String name;
  final String description;
  final double price;
  final String? image;
  final bool isReadyToServe;
  final int prepTime;
  final int stockQuantity;
  final bool isAvailable;

  MenuItemEntity({
    required this.id,
    required this.category,
    required this.categoryName,
    required this.station,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    required this.isReadyToServe,
    required this.prepTime,
    required this.stockQuantity,
    required this.isAvailable,
  });
}