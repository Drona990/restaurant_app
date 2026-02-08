abstract class WaiterTableEvent {}

class FetchMyTables extends WaiterTableEvent {}

class SelectTable extends WaiterTableEvent {
  final dynamic table;
  SelectTable(this.table);
}

class ClaimTable extends WaiterTableEvent {
  final String identifier; // 🌟 Named consistently as 'identifier'
  ClaimTable(this.identifier);
}

class UpdateFromWebSocket extends WaiterTableEvent {
  final dynamic data;
  UpdateFromWebSocket(this.data);
}

class UpdateItemStatus extends WaiterTableEvent {
  final List<int> itemIds;
  final String status;

  // 🌟 Named constructor for clarity in UI
  UpdateItemStatus({required this.itemIds, required this.status});
}