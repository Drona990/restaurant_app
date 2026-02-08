import 'package:flutter/material.dart';

class TableChips extends StatelessWidget {
  final List tables;
  final dynamic selectedTable;
  final Color cyan;
  final Function(dynamic) onSelected;

  const TableChips({super.key, required this.tables, required this.selectedTable, required this.cyan, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 65,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tables.length,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        itemBuilder: (context, index) {
          final table = tables[index];
          // 🌟 Unique Selection Check
          bool isSelected = selectedTable != null && selectedTable['id'] == table['id'];
          int orderCount = table['order_count'] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("T-${table['table_number']}"),
                  if (orderCount > 0) ...[
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: isSelected ? Colors.black : Colors.red,
                      child: Text("$orderCount", style: TextStyle(color: isSelected ? cyan : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: (val) => onSelected(table),
              selectedColor: cyan,
              backgroundColor: const Color(0xFF1A1A1A),
              labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white60, fontWeight: FontWeight.bold, fontSize: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              side: BorderSide(color: isSelected ? cyan : Colors.white10),
            ),
          );
        },
      ),
    );
  }
}