class TableEntity {
  final int id;
  final String tableNumber;
  final String qrId;
  final String? qrCodeImage;
  final bool isActive;
  final bool isOccupied; // 🌟 Logic: Backend determines this based on unpaid sessions

  TableEntity({
    required this.id,
    required this.tableNumber,
    required this.qrId,
    this.qrCodeImage,
    required this.isActive,
    required this.isOccupied,
  });
}