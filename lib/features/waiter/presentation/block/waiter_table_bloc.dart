import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'waiter_table_event.dart';
import 'waiter_table_state.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/websocket/websocket_service.dart';

class WaiterTableBloc extends Bloc<WaiterTableEvent, WaiterTableState> {
  final ApiClient apiClient;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final WebSocketService wsService;
  StreamSubscription? _wsSubscription;

  WaiterTableBloc({required this.apiClient, required this.wsService}) : super(WaiterTableInitial()) {
    on<FetchMyTables>(_onFetchMyTables);
    on<ClaimTable>(_onClaimTable);
    on<UpdateFromWebSocket>(_onUpdateFromWebSocket);
    on<UpdateItemStatus>(_onUpdateItemStatus);
    _initWebSocketListener();
  }

  void _initWebSocketListener() {
    _wsSubscription?.cancel();
    _wsSubscription = wsService.stream.listen((data) {
      final String? type = data['notification_type'];
      print("📩 RAW WS DATA notification: $data");

      // 🌟 'NEW_TICKET' ko yahan add karna MUST hai
      const signals = [
        'STATUS_UPDATE',
        'KDS_REFRESH',
        'NEW_ITEM_ADDED',
        'ITEM_READY',
        'PAYMENT_CONFIRMED',
        'NEW_TICKET' // 👈 Ye missing tha!
      ];

      if (signals.contains(type)) {
        print("🚀 Signal matched ($type)! Triggering UI Refresh...");
        add(UpdateFromWebSocket(data));
      } else {
        print("⚠️ Signal ignored: $type is not in the signals list.");
      }
    });
  }
  Future<void> _onFetchMyTables(FetchMyTables event, Emitter<WaiterTableState> emit) async {
    if (state is! WaiterTableLoaded) emit(WaiterTableLoading());

    try {
      final name = await storage.read(key: 'username') ?? 'Captain';
      final role = await storage.read(key: 'user_role') ?? 'Waiter';
      final userId = await storage.read(key: 'user_id') ?? '0';

      if (!wsService.isConnected.value) {
        wsService.initConnection(role.toLowerCase(), userId);
      }

      final response = await apiClient.get("/api/orders/my_tables/").timeout(const Duration(seconds: 8));

      emit(WaiterTableLoaded(
        response.data['data'],
        username: name,
        role: role,
        selectedTable: (state is WaiterTableLoaded) ? (state as WaiterTableLoaded).selectedTable : null,
      ));
    } catch (e) {
      emit(WaiterTableError("Connection Error: Check Server IP"));
    }
  }

  Future<void> _onClaimTable(ClaimTable event, Emitter<WaiterTableState> emit) async {
    try {
      final response = await apiClient.post("/api/table/claim/${event.identifier}/");

      if (response.statusCode == 200) {
        final data = response.data;
        final id = (data['order_id'] ?? data['table_id'] ?? "").toString();
        emit(ClaimTableSuccess(id, data['message'], mode: data['mode']));
        add(FetchMyTables());
      }
    } catch (e) {
      emit(WaiterTableError("Claim Failed: Table might be occupied."));
    }
  }

  void _onUpdateFromWebSocket(UpdateFromWebSocket event, Emitter<WaiterTableState> emit) async {
    try {
      String name = "Captain";
      String role = "Waiter";
      dynamic selected;

      if (state is WaiterTableLoaded) {
        final current = state as WaiterTableLoaded;
        name = current.username;
        role = current.role;
        selected = current.selectedTable;
      }

      final response = await apiClient.get("/api/orders/my_tables/");
      if (response.statusCode == 200) {
        emit(WaiterTableLoaded(
          response.data['data'],
          username: name,
          role: role,
          selectedTable: selected,
        ));
      }
    } catch (e) {
      debugPrint("Silent Refresh Failed");
    }
  }

  Future<void> _onUpdateItemStatus(UpdateItemStatus event, Emitter<WaiterTableState> emit) async {
    try {
      final response = await apiClient.patch(
          "/api/orders/update-item-status/",
          data: {"item_ids": event.itemIds, "status": event.status}
      );

      if (response.statusCode == 200) {
        add(FetchMyTables());
      }
    } catch (e) {
      debugPrint("Status Update Failed: $e");
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}