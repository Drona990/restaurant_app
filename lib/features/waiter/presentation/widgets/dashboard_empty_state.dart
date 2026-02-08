import 'package:flutter/material.dart';

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 60, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 15),
          const Text("NO ACTIVE TABLES",
              style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Scan a QR code to begin",
              style: TextStyle(color: Colors.white12, fontSize: 11)),
        ],
      ),
    );
  }
}