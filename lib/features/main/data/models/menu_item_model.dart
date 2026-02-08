
import '../../domain/entities/menu_item_entity.dart';

class MenuItemModel extends MenuItemEntity {
  MenuItemModel({
    required super.id,
    required super.category,
    required super.categoryName,
    required super.station,
    required super.name,
    required super.description,
    required super.price,
    super.image,
    required super.isReadyToServe,
    required super.prepTime,
    required super.stockQuantity,
    required super.isAvailable,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] ?? 0,
      category: json['category'] ?? 0,
      categoryName: json['category_name'] ?? '',
      station: json['station'] ?? 'kitchen',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      image: json['image'],
      isReadyToServe: json['is_ready_to_serve'] ?? false,
      prepTime: json['prep_time'] ?? 15,
      stockQuantity: json['stock_quantity'] ?? -1,
      isAvailable: json['is_available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'name': name,
    'description': description,
    'price': price,
    'is_ready_to_serve': isReadyToServe,
    'prep_time': prepTime,
    'stock_quantity': stockQuantity,
    'is_available': isAvailable,
  };
}