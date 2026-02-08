import 'package:flutter/material.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<dynamic> _historyOrders = [];
  bool _isLoading = true;
  String _range = 'today';
  String _paymentMode = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final res = await sl<ApiClient>().get('/api/orders/history/', query: {
        'range': _range, 'payment_mode': _paymentMode, 'search': _searchController.text,
      });
      setState(() { _historyOrders = res.data['data']; _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Order History", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildFilterPanel(),
            const SizedBox(height: 16),
            Expanded(child: _buildFullWidthTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _drop("Range", _range, ['today', 'yesterday'], (v) { _range = v!; _fetchHistory(); }),
          const SizedBox(width: 20),
          _drop("Payment", _paymentMode, ['all', 'cash', 'upi'], (v) { _paymentMode = v!; _fetchHistory(); }),
          const SizedBox(width: 20),
          Expanded(child: TextField(
            controller: _searchController,
            decoration: InputDecoration(hintText: "Search Invoice...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            onSubmitted: (_) => _fetchHistory(),
          )),
        ],
      ),
    );
  }

  Widget _buildFullWidthTable() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 20,
          horizontalMargin: 20,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F4F9)),
          columns: const [
            DataColumn(label: Expanded(child: Text("INVOICE", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Expanded(child: Text("DATE TIME", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Expanded(child: Text("TABLE", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Expanded(child: Text("CUSTOMER", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Expanded(child: Text("AMOUNT", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Expanded(child: Text("MODE", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Text("ACTION", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _historyOrders.map((o) => DataRow(cells: [
            DataCell(Text(o['invoice'])),
            DataCell(Text(o['datetime'])),
            DataCell(Text("T-${o['table']}")),
            DataCell(Text(o['customer'])),
            DataCell(Text("₹${o['amount']}", style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(_badge(o['payment'])),
            DataCell(IconButton(icon: const Icon(Icons.visibility, color: Colors.cyan), onPressed: () => _showBillDetails(o))),
          ])).toList(),
        ),
      ),
    );
  }

  void _showBillDetails(dynamic order) {
    // 🌟 Ensure items is never null
    final List<dynamic> itemsList = order['items'] ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Invoice: ${order['invoice']}"),
        content: SizedBox(
          width: 450, // Slightly wider for better look
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (itemsList.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text("No items found for this invoice."),
                )
              else
                ...itemsList.map((it) => ListTile(
                  dense: true,
                  title: Text(it['name'].toString()),
                  subtitle: Text("Qty: ${it['qty']}"),
                  trailing: Text("₹${(it['price'] * it['qty']).toStringAsFixed(2)}"),
                )),
              const Divider(thickness: 1.2),
              _detailRow("Total Amount", "₹${order['amount']}", isBold: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String l, String v, {bool isBold = false, Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(v, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
      ]),
    );
  }

  Widget _drop(String l, String v, List<String> items, Function(String?) onCh) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      DropdownButton<String>(value: v, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(), onChanged: onCh),
    ]);
  }

  Widget _badge(String m) {
    return Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: (m == 'UPI' ? Colors.blue : Colors.orange).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Text(m, style: TextStyle(color: m == 'UPI' ? Colors.blue : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)));
  }
}