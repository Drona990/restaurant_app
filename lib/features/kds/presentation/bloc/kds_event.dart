abstract class KdsEvent {}

class UpdateItemStatus extends KdsEvent {
  final List<int> itemIds; // 🌟 Changed from int to List<int>
  final String status;
  UpdateItemStatus(this.itemIds, this.status);
}

// Baki events...
class RefreshTasks extends KdsEvent {}
class LoadKdsInitialData extends KdsEvent {}
class WebSocketMessageReceived extends KdsEvent {
  final dynamic data;
  WebSocketMessageReceived(this.data);
}