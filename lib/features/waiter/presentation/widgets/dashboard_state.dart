import 'package:flutter/material.dart';

class DashboardStats extends StatelessWidget {
  final List tables;
  final Color cyan;

  const DashboardStats({super.key, required this.tables, required this.cyan});

  @override
  Widget build(BuildContext context) {
    int ready = tables.where((t) => t['status'] == 'ready').length;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      color: const Color(0xFF121212),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(label: "MY TABLES", value: "${tables.length}", color: cyan),
          _StatItem(label: "READY TO SERVE", value: "$ready", color: Colors.greenAccent),
          _StatItem(label: "SHIFT TOTAL", value: "₹--", color: Colors.grey),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
    ]);
  }
}