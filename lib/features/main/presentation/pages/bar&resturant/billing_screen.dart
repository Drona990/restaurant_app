
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';
import '../../../domain/entities/menu_item_entity.dart';
import '../../../domain/entities/table_entity.dart';
import '../../bloc/menu_bloc.dart';
import '../../bloc/table_bloc.dart';

// ==========================================================================
// 1. DATA & BLOC LAYER (Discount & State Management)
// ==========================================================================

class BillingDiscountResponse {
  final double discountAmount;
  final String appliedOfferName;
  final String code;

  BillingDiscountResponse({required this.discountAmount, required this.appliedOfferName, required this.code});

  factory BillingDiscountResponse.fromJson(Map<String, dynamic> json) => BillingDiscountResponse(
    discountAmount: double.parse(json['discount_amount'].toString()),
    appliedOfferName: json['applied_offer_name'] ?? "No Offer",
    code: json['code'] ?? "AUTO",
  );
}

abstract class BillingEvent {}
class CalculateDiscount extends BillingEvent {
  final double subtotal;
  final String? couponCode;
  CalculateDiscount(this.subtotal, {this.couponCode});
}

abstract class BillingState {}
class BillingInitial extends BillingState {}
class DiscountApplied extends BillingState {
  final BillingDiscountResponse response;
  DiscountApplied(this.response);
}

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  BillingBloc() : super(BillingInitial()) {
    on<CalculateDiscount>((event, emit) async {
      try {
        final res = await sl<ApiClient>().post('/api/discounts/apply_discount/', data: {
          "subtotal": event.subtotal,
          "coupon_code": event.couponCode,
        });
        if (res.statusCode == 200) {
          emit(DiscountApplied(BillingDiscountResponse.fromJson(res.data)));
        }
      } catch (e) { debugPrint("Discount Error: $e"); }
    });
  }
}

// ==========================================================================
// 2. MAIN BILLING VIEW
// ==========================================================================





class ProfessionalBillingScreen extends StatefulWidget {
  final List<MenuItemEntity> allItems;
  final List<TableEntity> activeTables;

  const ProfessionalBillingScreen({super.key, required this.allItems, required this.activeTables});

  @override
  State<ProfessionalBillingScreen> createState() => _ProfessionalBillingScreenState();
}

class _ProfessionalBillingScreenState extends State<ProfessionalBillingScreen> {
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: "1");
  final TextEditingController _couponController = TextEditingController();

  List<BillingItem> _cartItems = [];
  TableEntity? _selectedTable;
  MenuItemEntity? _selectedMenuItem;
  bool _isProcessing = false;
  String _currentTime = "";
  double _appliedDiscountAmount = 0.0;
  String _appliedOfferName = "No Offer";

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (t) => _updateClock());
  }

  void _updateClock() {
    if (mounted) setState(() => _currentTime = DateFormat('dd MMM yyyy | hh:mm a').format(DateTime.now()));
  }

  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get _gst => (_subtotal - _appliedDiscountAmount) * 0.18;
  double get _grandTotal => (_subtotal - _appliedDiscountAmount) + _gst;

  void _addToCart() {
    if (_selectedMenuItem == null) return;
    int qty = int.tryParse(_qtyController.text) ?? 1;

    setState(() {
      final idx = _cartItems.indexWhere((i) => i.menuId == _selectedMenuItem!.id);
      if (idx != -1) {
        _cartItems[idx].quantity += qty;
      } else {
        _cartItems.add(BillingItem(
          menuId: _selectedMenuItem!.id,
          name: _selectedMenuItem!.name,
          price: _selectedMenuItem!.price,
          quantity: qty,
        ));
      }
      _selectedMenuItem = null;
      _qtyController.text = "1";
    });
    _applyDiscountLogic();
  }

  void _applyDiscountLogic({String? manualCode}) {
    if (_subtotal > 0) {
      context.read<BillingBloc>().add(CalculateDiscount(_subtotal, couponCode: manualCode));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BillingBloc, BillingState>(
      listener: (context, state) {
        if (state is DiscountApplied) {
          setState(() {
            _appliedDiscountAmount = state.response.discountAmount;
            _appliedOfferName = state.response.appliedOfferName;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F3F6),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    Expanded(flex: 3, child: _buildBillingForm()),
                    const SizedBox(width: 20),
                    Expanded(flex: 1, child: _buildSummaryPane()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("POS TERMINAL #01", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        Text(_currentTime, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ],
    );
  }

  Widget _buildBillingForm() {
    return Column(
      children: [
        // Table & Customer Select
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(child: TextField(controller: _customerController, decoration: const InputDecoration(labelText: "Customer Name", prefixIcon: Icon(Icons.person)))),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<TableEntity>(
                  value: _selectedTable,
                  hint: const Text("Assign Table"),
                  items: widget.activeTables.map((t) => DropdownMenuItem(value: t, child: Text("Table ${t.tableNumber}"))).toList(),
                  onChanged: (v) => setState(() => _selectedTable = v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Item Selector
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<MenuItemEntity>(
                  value: _selectedMenuItem,
                  hint: const Text("Select Item"),
                  items: widget.allItems.where((i)=>i.isAvailable).map((i) => DropdownMenuItem(value: i, child: Text(i.name))).toList(),
                  onChanged: (v) => setState(() => _selectedMenuItem = v),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 80, child: TextField(controller: _qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Qty"))),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: _addToCart, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1C24), foregroundColor: Colors.white), child: const Text("ADD TO CART")),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Cart Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: _cartItems.isEmpty
                ? const Center(child: Text("Cart is empty", style: TextStyle(color: Colors.grey)))
                : ListView.separated(
              itemCount: _cartItems.length,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (c, i) {
                final item = _cartItems[i];
                return ListTile(
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("₹${item.price} x ${item.quantity}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("₹${(item.price * item.quantity).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => _cartItems.removeAt(i))),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryPane() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text("BILL SUMMARY", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          const Divider(height: 32),
          _row("Subtotal", "₹${_subtotal.toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          TextField(
            controller: _couponController,
            decoration: InputDecoration(
              hintText: "Coupon Code",
              suffixIcon: IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _applyDiscountLogic(manualCode: _couponController.text)),
            ),
          ),
          if (_appliedDiscountAmount > 0) _row(_appliedOfferName, "- ₹${_appliedDiscountAmount.toStringAsFixed(2)}", color: Colors.green),
          _row("GST (18%)", "₹${_gst.toStringAsFixed(2)}"),
          const Spacer(),
          _row("GRAND TOTAL", "₹${_grandTotal.toStringAsFixed(2)}", isBold: true, color: const Color(0xFF00BCD4)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isProcessing ? null : _submitOrder,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1C24), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 60)),
            child: _isProcessing ? const CircularProgressIndicator() : const Text("CONFIRM & PRINT"),
          )
        ],
      ),
    );
  }

  Widget _row(String l, String v, {bool isBold = false, Color color = Colors.black}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      Text(v, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isBold ? 20 : 14, color: color)),
    ]);
  }

  // ==========================================================================
  // 3. LOGIC: ORDER SUBMISSION & PRINTING
  // ==========================================================================

  Future<void> _submitOrder() async {
    if (_cartItems.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      final payload = {
        // 🌟 Agar table select nahi hai toh null jayega (Counter Order)
        "table": _selectedTable?.id,
        "customer_name": _customerController.text.isEmpty ? "Walk-in" : _customerController.text,
        "discount_amount": _appliedDiscountAmount,
        "payment_method": "cash",
        "order_type": _selectedTable == null ? "prepaid" : "postpaid",
        "group_tag": _selectedTable == null ? "Counter" : "Group A",
        "is_waiter": false,
        "items": _cartItems.map((e) => {
          "menu_item": e.menuId,
          "quantity": e.quantity,
          "ordered_by_name": _customerController.text,
        }).toList(),
      };

      final res = await sl<ApiClient>().post('/api/orders/place/', data: payload);

      if (res.statusCode == 201 || res.statusCode == 200) {
        await _printReceipt(); // Parchi print karein
        _clearAll(); // Screen reset karein
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint("Order Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Server Error. Check Backend."), backgroundColor: Colors.red));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _clearAll() {
    _cartItems.clear();
    _customerController.clear();
    _couponController.clear();
    _selectedTable = null;
    _appliedDiscountAmount = 0;
    context.read<TableBloc>().add(LoadTables()); // Refresh Dashboard Tables
  }

  Future<void> _printReceipt() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(child: pw.Text("SVENSKA RESTAURANT", style: pw.TextStyle(font: boldFont, fontSize: 14))),
          pw.Divider(),
          pw.Text("Table: ${_selectedTable?.tableNumber}"),
          pw.Text("Cust: ${_customerController.text}"),
          pw.Divider(),
          ..._cartItems.map((e) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text("${e.quantity} x ${e.name}", style: pw.TextStyle(font: font, fontSize: 9)),
            pw.Text((e.price * e.quantity).toStringAsFixed(2), style: pw.TextStyle(font: font, fontSize: 9)),
          ])),
          pw.Divider(),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text("TOTAL", style: pw.TextStyle(font: boldFont)),
            pw.Text("Rs.${_grandTotal.toStringAsFixed(2)}", style: pw.TextStyle(font: boldFont)),
          ]),
        ],
      ),
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}

class BillingItem {
  final int menuId;
  final String name;
  final double price;
  int quantity;
  BillingItem({required this.menuId, required this.name, required this.price, required this.quantity});
}



class BillingPageWrapper extends StatelessWidget {
  const BillingPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Data fetch trigger karein
    context.read<MenuBloc>().add(LoadMenu());
    context.read<TableBloc>().add(LoadTables());

    // 2. BillingBloc ko yahan provide karein taaki poori screen ise use kar sake
    return BlocProvider(
      create: (context) => BillingBloc(),
      child: BlocBuilder<MenuBloc, MenuState>(
        builder: (context, menuState) {
          return BlocBuilder<TableBloc, TableState>(
            builder: (context, tableState) {

              final items = (menuState is MenuLoaded) ? menuState.items : <MenuItemEntity>[];
              final tables = (tableState is TableLoaded) ? tableState.tables : <TableEntity>[];

              // 3. Loading check
              if ((menuState is MenuLoading && items.isEmpty) || (tableState is TableLoading && tables.isEmpty)) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator(color: Colors.cyan))
                );
              }

              // 4. Data pass karein (Sirf Active items aur tables)
              return ProfessionalBillingScreen(
                allItems: items,
                activeTables: tables.where((t) => t.isActive).toList(),
              );
            },
          );
        },
      ),
    );
  }
}