import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/websocket/websocket_service.dart';
import 'kds_event.dart';
import 'kds_state.dart';


class KdsBloc extends Bloc<KdsEvent, KdsState> {
  final ApiClient apiClient;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final WebSocketService _wsService = GetIt.I<WebSocketService>();
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _wsSubscription;

  KdsBloc({required this.apiClient}) : super(KdsInitial()) {
    on<LoadKdsInitialData>(_onLoadInitialData);
    on<RefreshTasks>(_onRefreshTasks);
    on<UpdateItemStatus>(_onUpdateStatus);
    on<WebSocketMessageReceived>((event, emit) => add(RefreshTasks()));
  }

  Future<void> _onLoadInitialData(LoadKdsInitialData event, Emitter<KdsState> emit) async {
    emit(KdsLoading());
    final role = await storage.read(key: 'user_role') ?? 'chef';
    final userId = await storage.read(key: 'user_id') ?? '0';
    _wsService.initConnection(role.toLowerCase(), userId);
    _startWsListening();
    add(RefreshTasks());
  }


  Future<void> _playAlertSound() async {
    try { await _audioPlayer.play(AssetSource('sound/order_alert.mp3')); } catch (_) {}
  }

  void _startWsListening() {
    _wsSubscription?.cancel();
    _wsSubscription = _wsService.stream.listen((data) {
      debugPrint("🎯 WS DATA RECEIVED: $data"); // 🪵 Log 1

      final String type = data['notification_type'] ?? '';

      // 🌟 FIX: Added STATUS_UPDATE because your Master Router sends this
      if (type == 'NEW_TICKET' ||
          type == 'KDS_REFRESH' ||
          type == 'ITEMS_UPDATED' ||
          type == 'STATUS_UPDATE') {

        debugPrint("🔄 MATCH FOUND! Type: $type. Triggering Refresh..."); // 🪵 Log 2

        if (type == 'NEW_TICKET') _playAlertSound();
        add(RefreshTasks());
      } else {
        debugPrint("⚠️ NO MATCH for type: $type"); // 🪵 Log 3
      }
    });
  }

  Future<void> _onRefreshTasks(RefreshTasks event, Emitter<KdsState> emit) async {
    try {
      final response = await apiClient.get("/api/orders/kds/");
      final List<dynamic> rawData = response.data['data'] ?? [];

      final String? currentUserId = await storage.read(key: 'user_id');
      final String? userRole = await storage.read(key: 'user_role');

      final String myId = (currentUserId ?? "").trim();
      final String myStation = (userRole?.toLowerCase() == 'barman') ? 'bar' : 'kitchen';

      Map<String, Map<String, dynamic>> grouped = {};

      for (var order in rawData) {
        for (var item in order['items']) {
          // 🌟 SAFE PARSING: Kisi bhi type ko string/int mein convert karne ka pakka tarika
          final String status = (item['status'] ?? 'confirmed').toString().trim();
          final String itemStation = (item['station'] ?? 'kitchen').toString().trim();
          final String assignedId = (item['assigned_chef_id'] ?? "").toString().trim();

          // 🌟 QUANTITY FIX: Web par 'double' ya 'String' bhi aa sakta hai
          final int qty = (item['quantity'] is num)
              ? (item['quantity'] as num).toInt()
              : (int.tryParse(item['quantity'].toString()) ?? 0);

          // Station Filter
          if (itemStation != myStation) continue;

          // Hide Logic
          if (status == 'cooking' && assignedId.isNotEmpty && assignedId != myId) {
            continue;
          }

          if (status == 'ready' || status == 'served') continue;

          String key = "${item['menu_item_name']}_$status";
          if (!grouped.containsKey(key)) {
            grouped[key] = {
              'name': item['menu_item_name'],
              'status': status,
              'total_qty': 0,
              'assigned_chef_id': assignedId,
              'chef_name': item['chef_name'] ?? 'Staff',
              'earliest_time': item['created_at'],
              'order_details': [],
            };
          }

          grouped[key]!['total_qty'] += qty;
          grouped[key]!['order_details'].add({
            // 🌟 ID FIX: Humesha string mein convert karke parse karein
            'item_id': int.tryParse(item['id'].toString()) ?? 0,
            'table': order['table_no'] ?? '?',
            'invoice': order['invoice_no'] ?? 'N/A',
            'order_id': order['id'],
            'qty': qty,
          });
        }
      }

      emit(KdsLoaded(
        tickets: grouped.values.toList(),
        username: (await storage.read(key: 'username')) ?? "STAFF",
        userRole: userRole ?? "CHEF",
        currentUserId: myId,
        isBarman: myStation == 'bar',
      ));
    } catch (e) {
      debugPrint("❌ REFRESH ERROR: $e");
      emit(KdsError("Sync Error: $e"));
    }
  }


  Future<void> _onUpdateStatus(UpdateItemStatus event, Emitter<KdsState> emit) async {
    try {
      final response = await apiClient.patch("/api/orders/update-item-status/", data: {
        "item_ids": event.itemIds,
        "status": event.status,
      });

      if (response.statusCode == 200) {
        add(RefreshTasks());
      }
    } catch (e) {
      debugPrint("❌ Update Status Error: $e");
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    _audioPlayer.dispose();
    return super.close();
  }
}