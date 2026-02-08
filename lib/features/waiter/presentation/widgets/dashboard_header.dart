import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final List tables;
  final Color cyan;

  const DashboardHeader({super.key, required this.tables, required this.cyan});

  @override
  Widget build(BuildContext context) {
    int ready = tables.where((t) => t['status'] == 'ready').length;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      color: const Color(0xFF121212),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statItem("MY TABLES", "${tables.length}", cyan),
          _statItem("READY TO SERVE", "$ready", Colors.greenAccent),
          _statItem("SHIFT TOTAL", "₹--", Colors.grey),
        ],
      ),
    );
  }

  Widget _statItem(String label, String val, Color col) {
    return Column(children: [
      Text(val, style: TextStyle(color: col, fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
    ]);
  }
}