import 'package:flutter/material.dart';

class GuestSelectorSheet extends StatefulWidget {
  final Color cyan;
  final Function(String name) onConfirm;

  const GuestSelectorSheet({super.key, required this.cyan, required this.onConfirm});

  @override
  State<GuestSelectorSheet> createState() => _GuestSelectorSheetState();
}

class _GuestSelectorSheetState extends State<GuestSelectorSheet> {
  final TextEditingController _nameCtrl = TextEditingController();
  String selectedQuickSeat = "";

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 15,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 20),
          const Text("GUEST IDENTITY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const Text("Identify new group for invoice generation", style: TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 20),

          // Quick Select Seats (G1, G2, G3...)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ["G1", "G2", "G3", "G4", "G5"].map((seat) {
                bool isSelected = selectedQuickSeat == seat;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(seat),
                    selected: isSelected,
                    selectedColor: widget.cyan,
                    labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                    backgroundColor: Colors.white10,
                    onSelected: (val) => setState(() {
                      selectedQuickSeat = seat;
                      _nameCtrl.text = seat;
                    }),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 15),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter Guest Name (Optional)",
              hintStyle: const TextStyle(color: Colors.white10),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              prefixIcon: const Icon(Icons.person_outline, color: Colors.white38),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.cyan,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () => widget.onConfirm(_nameCtrl.text.isEmpty ? "New Guest" : _nameCtrl.text),
            child: const Text("START ORDERING", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}