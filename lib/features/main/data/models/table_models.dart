import '../../domain/entities/table_entity.dart';

class TableModel extends TableEntity {
  TableModel({
    required super.id,
    required super.tableNumber,
    required super.qrId,
    super.qrCodeImage,
    required super.isActive,
    required super.isOccupied,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      tableNumber: json['table_number'].toString(),
      qrId: json['qr_id'],
      qrCodeImage: json['qr_code_image'],
      isActive: json['is_active'] ?? true,
      isOccupied: json['is_occupied'] ?? false,
    );
  }
}