abstract class WaiterTableState {}

class WaiterTableInitial extends WaiterTableState {}

class WaiterTableLoading extends WaiterTableState {}

class WaiterTableError extends WaiterTableState {
  final String message;
  WaiterTableError(this.message);
}

class ClaimTableSuccess extends WaiterTableState {
  final String id; // Order ID or Table ID
  final String message;
  final String mode; // JOINED or NEW_SESSION
  ClaimTableSuccess(this.id, this.message, {this.mode = ""});
}

class WaiterTableLoaded extends WaiterTableState {
  final List tables;
  final dynamic selectedTable;
  final String username; // 🌟 Profile data
  final String role;

  WaiterTableLoaded(this.tables, {
    this.selectedTable,
    required this.username,
    required this.role
  });
}