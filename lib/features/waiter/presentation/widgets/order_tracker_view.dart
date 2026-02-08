
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../block/waiter_table_bloc.dart';
import '../block/waiter_table_event.dart';


class OrderTracker extends StatelessWidget {
  final dynamic table;
  final Color cyan;
  final VoidCallback onNewManualOrder;

  const OrderTracker({
    super.key,
    required this.table,
    required this.cyan,
    required this.onNewManualOrder
  });

  @override
  Widget build(BuildContext context) {
    List orders = table['active_orders'] ?? [];

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20)
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: orders.isEmpty
                ? _buildEmptyOrdersView()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: orders.length,
              itemBuilder: (context, index) => _buildOrderCard(context, orders[index]),
            ),
          ),
          _buildBottomActionButtons(),
        ],
      ),
    );
  }

  // --- HEADER & EMPTY STATE ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("T${table['table_number']} STATUS",
              style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
          Text("₹${table['total_table_amount'] ?? '0'}",
              style: TextStyle(color: cyan, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersView() {
    return const Center(
      child: Text("No active orders.\nReady for new guests.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white24, fontSize: 13)),
    );
  }

  // --- ORDER CARD ---
  Widget _buildOrderCard(BuildContext context, dynamic order) {
    List items = order['items'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          iconColor: cyan,
          title: Text(
            "${order['customer_name']} (#${order['invoice_no']})",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text("${items.length} Items", style: const TextStyle(color: Colors.white38, fontSize: 11)),
          trailing: IconButton(
            icon: Icon(Icons.add_circle_outline, color: cyan, size: 26),
            onPressed: () => _navigateToAddItems(context, order),
          ),
          children: [
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildItemsList(context, items),
            ),
          ],
        ),
      ),
    );
  }

  // --- ITEMS LIST & ACTION BUTTONS ---

  Widget _buildItemsList(BuildContext context, List items) {
    return Column(
      children: items.map((item) {
        final String status = item['status'].toString().toLowerCase();

        Color statusColor;
        switch (status) {
          case 'ready': statusColor = Colors.greenAccent; break;
          case 'pending': statusColor = Colors.orangeAccent; break;
          case 'cooking': statusColor = Colors.blueAccent; break;
          case 'confirmed': statusColor = Colors.cyanAccent; break;
          default: statusColor = Colors.white38;
        }

        final bool isReady = status == 'ready';
        final bool isPending = status == 'pending';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            // Background Ready hone par halka green rahega
            color: isReady ? Colors.green.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            // 🌟 BORDER COLOR: Status ke hisab se badlega
            border: Border.all(
              color: statusColor.withOpacity(0.4),
              width: isReady ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              _buildStatusIndicator(status),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${item['quantity']} x ${item['menu_item_name']}",
                      style: TextStyle(
                        // 🌟 TEXT COLOR: Status ke hisab se badlega
                        color: statusColor.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: isReady ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(color: statusColor.withOpacity(0.5), fontSize: 9, letterSpacing: 1),
                    ),
                  ],
                ),
              ),

              // 🎯 ACTION BUTTONS
              if (isPending)
                _actionButton("ACCEPT", Colors.orange, () {
                  context.read<WaiterTableBloc>().add(UpdateItemStatus(
                      itemIds: [int.parse(item['id'].toString())],
                      status: 'confirmed'
                  ));
                })
              else if (isReady)
                _actionButton("SERVE", Colors.green, () {
                  context.read<WaiterTableBloc>().add(UpdateItemStatus(
                      itemIds: [int.parse(item['id'].toString())],
                      status: 'served'
                  ));
                }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusIndicator(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'ready': icon = Icons.notifications_active; color = Colors.green; break;
      case 'pending': icon = Icons.hourglass_top; color = Colors.orange; break;
      case 'cooking': icon = Icons.soup_kitchen; color = Colors.blueAccent; break;
      default: icon = Icons.check_circle_outline; color = Colors.white24;
    }
    return Icon(icon, size: 16, color: color);
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- NAVIGATION & FOOTER ---
  void _navigateToAddItems(BuildContext context, dynamic order) {
    context.push('/menu', extra: {
      'order_id': order['id'].toString(),
      'table_id': table['id'],
      'guest_name': order['customer_name'],
      'is_addon': true,
    }).then((_) => context.read<WaiterTableBloc>().add(FetchMyTables()));
  }

  Widget _buildBottomActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            backgroundColor: cyan,
            minimumSize: const Size(200, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        onPressed: onNewManualOrder,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.black),
        label: const Text("NEW GUEST ORDER",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}