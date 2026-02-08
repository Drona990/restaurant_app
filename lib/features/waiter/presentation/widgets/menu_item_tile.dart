
import 'package:flutter/material.dart';

class MenuItemTile extends StatelessWidget {
  final dynamic item;
  final Color cyan;
  final VoidCallback onAdd;

  const MenuItemTile({super.key, required this.item, required this.cyan, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        title: Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text("₹${item['price']}", style: TextStyle(color: cyan, fontSize: 11)),
        // 🚀 DIRECT ADD: Koi Seat picker nahi khulega
        trailing: IconButton(
          icon: Icon(Icons.add_circle, color: cyan, size: 30),
          onPressed: onAdd,
        ),
      ),
    );
  }
}