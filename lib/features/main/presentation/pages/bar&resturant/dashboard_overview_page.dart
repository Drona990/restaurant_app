
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/services/bill_printing_service.dart';
import '../../../../../core/utils/websocket/websocket_service.dart';
import '../../../../../injection.dart';



// ==========================================
// 1. MODELS
// ==========================================
class BillingDiscountResponse {
  final double discountAmount;
  final String offerName;
  final String code;

  BillingDiscountResponse({
    required this.discountAmount,
    required this.offerName,
    required this.code
  });

  factory BillingDiscountResponse.fromJson(Map<String, dynamic> json) {
    return BillingDiscountResponse(
      discountAmount: double.parse(json['discount_amount'].toString()),
      offerName: json['applied_offer_name'] ?? "No Offer",
      code: json['code'] ?? "AUTO",
    );
  }
}

// ==========================================
// 2. EVENTS
// ==========================================
abstract class DashboardEvent {}

class LoadDashboardData extends DashboardEvent {}

class UpdateFromWebSocket extends DashboardEvent {
  final dynamic data;
  UpdateFromWebSocket(this.data);
}

class CalculateDiscount extends DashboardEvent {
  final double subtotal;
  final String? couponCode;
  CalculateDiscount(this.subtotal, {this.couponCode});
}

class ClearDiscount extends DashboardEvent {}

class SettleOrderEvent extends DashboardEvent {
  final int orderId;
  final String method;
  final String? couponCode;
  SettleOrderEvent(this.orderId, this.method, this.couponCode);
}

// ==========================================
// 3. STATES
// ==========================================
abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<dynamic> tables;
  final Map<String, dynamic> stats;
  DashboardLoaded(this.tables, this.stats);
}

class PaymentSuccessState extends DashboardState {}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}

// Discount Specific States (For UI Feedback in Dialog)
class DiscountLoading extends DashboardState {}

class DiscountApplied extends DashboardState {
  final BillingDiscountResponse response;
  DiscountApplied(this.response);
}

class DiscountError extends DashboardState {
  final String message;
  DiscountError(this.message);
}

// ==========================================
// 4. BLOC IMPLEMENTATION
// ==========================================
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final dynamic api; // Use your ApiClient type here

  DashboardBloc(this.api) : super(DashboardInitial()) {

    // --- Floor Map Loader ---
    on<LoadDashboardData>((event, emit) async {
      if (state is! DashboardLoaded) emit(DashboardLoading());
      try {
        final response = await api.get('/api/admin/floor-map/');

        print("floor map data $response");
        emit(DashboardLoaded(
            response.data['tables'] ?? [],
            response.data['stats'] ?? {}
        ));
      } catch (e) {
        emit(DashboardError("API Error: $e"));
      }
    });

    // --- WebSocket Sync ---
    on<UpdateFromWebSocket>((event, emit) => add(LoadDashboardData()));

    // --- 🔍 Discount Validation Logic ---
    on<CalculateDiscount>((event, emit) async {
      final previousState = state;
      emit(DiscountLoading());
      try {
        final res = await api.post('/api/discounts/apply_discount/', data: {
          "subtotal": event.subtotal,
          "coupon_code": event.couponCode,
        });

        if (res.statusCode == 200) {
          emit(DiscountApplied(BillingDiscountResponse.fromJson(res.data)));
        } else {
          emit(DiscountError(res.data['message'] ?? "Invalid Coupon"));
        }
      } catch (e) {
        emit(DiscountError("Coupon check failed"));
      }
    });

    // --- 🧹 Reset State ---
    on<ClearDiscount>((event, emit) => add(LoadDashboardData()));

    // --- 💰 Final Settle & Print Logic ---
    on<SettleOrderEvent>((event, emit) async {
      try {
        final response = await api.post(
          '/api/orders/generate-bill/',
          data: {
            "order_id": event.orderId,
            "payment_method": event.method,
            "coupon_code": event.couponCode ?? "",
          },
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          final billData = response.data['data'];

          // Debugging
          debugPrint("📄 Bill Parcha Received: $billData");

           await BillPrintingService().showBillPreview(billData);

          // 2. Success Sequence
          emit(PaymentSuccessState());
          add(LoadDashboardData());

        } else {
          emit(DashboardError(response.data['error'] ?? "Settlement Failed"));
        }
      } catch (e) {
        debugPrint("❌ SETTLE ERROR: $e");
        emit(DashboardError("Connection Error: $e"));
      }
    });
  }
}


// --- 2. UI IMPLEMENTATION ---

class DashboardOverviewPage extends StatefulWidget {
  const DashboardOverviewPage({super.key});

  @override
  State<DashboardOverviewPage> createState() => _DashboardOverviewPageState();
}

class _DashboardOverviewPageState extends State<DashboardOverviewPage> {
  late WebSocketService _wsService;
  StreamSubscription? _wsSubscription;
  Timer? _ticker;
  String _searchQuery = "";
  final _storage = const FlutterSecureStorage();

  late DashboardBloc _dashboardBloc;

  @override
  void initState() {
    super.initState();
    _dashboardBloc = DashboardBloc(sl<ApiClient>());
    _dashboardBloc.add(LoadDashboardData());

    _wsService = WebSocketService();
    _initializeSession();

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initializeSession() async {
    final String? role = await _storage.read(key: 'user_role');
    final String? userId = await _storage.read(key: 'user_id');
    if (role != null && userId != null) {
      _wsService.initConnection(role.toLowerCase(), userId);
      _setupWSListener();
    }
  }

  void _setupWSListener() {
    _wsSubscription?.cancel();
    _wsSubscription = _wsService.stream.listen((data) {
      debugPrint("👑 ADMIN WS RECEIVED: $data");

      // 🌟 Backend 'type' ya 'notification_type' kuch bhi bhej sakta hai
      final String? type = data['notification_type'] ?? data['type'];

      const refreshSignals = [
        'STATUS_UPDATE', 'ITEM_READY', 'PAYMENT_CONFIRMED',
        'NEW_ORDER', 'CONNECTION_ESTABLISHED', 'KDS_REFRESH','NEW_TICKET',
      ];

      if (refreshSignals.contains(type)) {
        debugPrint("🔄 Signal Match ($type)! Triggering Refresh...");
        _dashboardBloc.add(LoadDashboardData());
      }
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _ticker?.cancel();
    _wsService.dispose();
    _dashboardBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _dashboardBloc,
      child: BlocListener<DashboardBloc, DashboardState>(
        listener: (context, state) {
          if (state is PaymentSuccessState) {
            Navigator.of(context, rootNavigator: true).maybePop();
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("SETTLED"), backgroundColor: Colors.green)
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: BlocBuilder<DashboardBloc, DashboardState>(
            buildWhen: (prev, curr) => curr is! PaymentSuccessState,
            builder: (context, state) {
              if (state is DashboardLoading) return const Center(child: CircularProgressIndicator());
              if (state is DashboardLoaded) {
                return Column(
                  children: [
                    _buildHeader(state.stats),
                    Expanded(
                      child: Row(
                        children: [
                          _buildTableGrid(state.tables), // Floor View
                          Expanded(flex: 3, child: _buildMainTableSection(context, state)), // Session List
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const Center(child: Text("Connecting to Server..."));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTableGrid(List tables) {
    return Container(
      width: 280,
      margin: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.all(15), child: Text("FLOOR VIEW", style: TextStyle(fontWeight: FontWeight.bold))),
          const Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: tables.length,
              itemBuilder: (ctx, i) {
                final bool isBusy = (tables[i]['active_sessions'] ?? []).isNotEmpty;
                return Container(
                  decoration: BoxDecoration(
                    color: isBusy ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    border: Border.all(color: isBusy ? Colors.orange : Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text("${tables[i]['table_number']}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: isBusy ? Colors.orange : Colors.green))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTableSection(BuildContext context, DashboardLoaded state) {
    List allSessions = [];
    for (var t in state.tables) {
      for (var s in (t['active_sessions'] ?? [])) {
        s['table_no'] = t['table_number'];
        allSessions.add(s);
      }
    }
    final filtered = allSessions.where((s) => s['invoice_number'].toString().contains(_searchQuery)).toList();

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 15, bottom: 15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _tableHeader(),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (ctx, i) => _buildDataRow(context, filtered[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(BuildContext context, dynamic session) {
    final List items = session['items'] ?? [];

    // 🌟 BILL FIX: Backend 0.00 bhej raha hai, hum frontend calculate karenge
    double total = double.tryParse(session['total_amount']?.toString() ?? '0') ?? 0;
    if (total == 0) {
      for (var item in items) {
        total += double.tryParse(item['subtotal']?.toString() ?? '0') ?? 0;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text("#${session['table_no']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          Expanded(flex: 2, child: Text("${session['customer_name']}\n${session['invoice_number']}", style: const TextStyle(fontSize: 11))),
          Expanded(flex: 4, child: Wrap(spacing: 4, children: items.map<Widget>((it) => _tag(it)).toList())),
          Expanded(flex: 2, child: Text(_timer(session['created_at']), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.teal, fontSize: 18))),
          Expanded(flex: 2, child: ElevatedButton(
            onPressed: () => _showSettle(context, session, total),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.white),
            child: const Text("SETTLE"),
          )),
        ],
      ),
    );
  }

  Widget _tag(dynamic item) {
    // 🌟 STATUS COLOR FIX: Trim and lowercase for exact match
    String s = (item['status'] ?? '').toString().toLowerCase().trim();
    Color c = s == 'served' ? Colors.grey : (s == 'ready' ? Colors.green : (s == 'cooking' ? Colors.blue : Colors.orange));

    return Container(
      margin: const EdgeInsets.only(right: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(6), border: Border.all(color: c)),
      child: Text("${item['quantity']}x ${item['menu_item_name']}",
          style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHeader(Map stats) {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.white,
      child: Row(
        children: [
          const Text("COMMAND CENTER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
          const Spacer(),
          ValueListenableBuilder<bool>(
            valueListenable: _wsService.isConnected,
            builder: (context, connected, _) => Row(children: [
              Icon(Icons.circle, size: 8, color: connected ? Colors.green : Colors.red),
              const SizedBox(width: 5),
              Text(connected ? "LIVE" : "OFFLINE", style: const TextStyle(fontSize: 10)),
            ]),
          ),
          const SizedBox(width: 30),
          Text("REVENUE: ₹${stats['total_revenue'] ?? '0'}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(hintText: "Search Invoice...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.grey.shade50,
      child: const Row(children: [
        Expanded(flex: 1, child: Text("TBL", style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text("GUEST", style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 4, child: Text("ORDER", style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text("TIME", style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text("BILL", style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text("ACTION", style: TextStyle(fontWeight: FontWeight.bold))),
      ]),
    );
  }

  String _timer(String? iso) {
    if (iso == null) return "00:00:00";
    final diff = DateTime.now().difference(DateTime.parse(iso).toLocal());
    return "${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  void _showSettle(BuildContext context, dynamic session, double total) {
    final TextEditingController couponController = TextEditingController();
    final bloc = context.read<DashboardBloc>();

    bloc.add(ClearDiscount());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.white),
                const SizedBox(width: 10),
                Text("Invoice: ${session['invoice_number']}",
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 💰 Original Amount Card
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Bill Subtotal", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      Text("₹${total.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 🏷️ Coupon Input Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: couponController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: "Coupon Code",
                          prefixIcon: const Icon(Icons.local_offer_outlined, color: Colors.teal),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          if (couponController.text.isNotEmpty) {
                            bloc.add(CalculateDiscount(total, couponCode: couponController.text.trim()));
                          }
                        },
                        child: const Text("APPLY", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),

                // 🔄 Dynamic Feedback Block (Bloc Integration)
                BlocBuilder<DashboardBloc, DashboardState>(
                  builder: (context, state) {
                    if (state is DiscountLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: LinearProgressIndicator(color: Colors.teal, backgroundColor: Colors.tealAccent),
                      );
                    }

                    if (state is DiscountApplied) {
                      final discount = state.response.discountAmount;
                      final finalPayable = total - discount;

                      return Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 15),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Applied: ${state.response.offerName}\nSaved: ₹${discount.toStringAsFixed(2)}",
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Final Payable", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              Text("₹${finalPayable.toStringAsFixed(2)}",
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                            ],
                          ),
                        ],
                      );
                    }

                    if (state is DiscountError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 16),
                            const SizedBox(width: 5),
                            Text(state.message, style: const TextStyle(color: Colors.red, fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    return const SizedBox(height: 20);
                  },
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.all(15),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print_outlined, size: 20),
                    label: const Text("SETTLE CASH"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      bloc.add(SettleOrderEvent(
                          session['id'],
                          'cash',
                          couponController.text.trim()
                      ));
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


}