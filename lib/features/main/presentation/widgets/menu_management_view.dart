import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/category_bloc.dart';
import '../bloc/menu_bloc.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../../domain/entities/category_entity.dart';

class MenuManagementView extends StatefulWidget {
  const MenuManagementView({super.key});
  @override
  State<MenuManagementView> createState() => _MenuManagementViewState();
}

class _MenuManagementViewState extends State<MenuManagementView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MenuBloc>().add(LoadMenu());
    context.read<CategoryBloc>().add(LoadCategories());
  }

  @override
  Widget build(BuildContext context) {
    final menuBloc = context.read<MenuBloc>();
    final catBloc = context.read<CategoryBloc>();

    return Container(
      color: const Color(0xFFF4F7FA),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Menu Management", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A1C24))),
                  Text("Create and manage your food items and prep stations", style: TextStyle(color: Colors.grey)),
                ],
              ),
              _buildAddButton(context, menuBloc, catBloc),
            ],
          ),
          const SizedBox(height: 24),
          _buildSearchAndFilter(menuBloc),
          const SizedBox(height: 24),
          Expanded(
            child: BlocBuilder<MenuBloc, MenuState>(
              builder: (context, state) {
                if (state is MenuLoading) return const Center(child: CircularProgressIndicator());
                if (state is MenuLoaded) return _buildTable(state.items, menuBloc);
                if (state is MenuError) return Center(child: Text(state.msg));
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(MenuBloc bloc) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => bloc.add(LoadMenu(query: v)),
        decoration: InputDecoration(
          hintText: "Search by item name...",
          prefixIcon: const Icon(Icons.search, color: Color(0xFF00BCD4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, MenuBloc mBloc, CategoryBloc cBloc) {
    return ElevatedButton.icon(
      onPressed: () => _showAddDialog(context, mBloc, cBloc),
      icon: const Icon(Icons.add_rounded),
      label: const Text("New Product", style: TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1C24),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTable(List<MenuItemEntity> items, MenuBloc bloc) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text("ITEM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
                Expanded(flex: 2, child: Text("DETAILS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
                Expanded(flex: 1, child: Text("STATION/TYPE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
                Expanded(flex: 1, child: Text("PRICE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
                Expanded(flex: 1, child: Text("AVAILABILITY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
                Expanded(flex: 1, child: Text("ACTION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) => _buildItemRow(items[index], bloc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(MenuItemEntity item, MenuBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 1, child: CircleAvatar(radius: 26, backgroundImage: item.image != null ? NetworkImage(item.image!) : null, child: item.image == null ? const Icon(Icons.restaurant) : null)),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(item.categoryName, style: TextStyle(color: Colors.cyan.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // 🌟 STATION & TYPE LOGIC
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBadge(item.station.toUpperCase(), Colors.blueGrey),
                const SizedBox(height: 4),
                _buildBadge(item.isReadyToServe ? "INSTANT" : "${item.prepTime} MIN", item.isReadyToServe ? Colors.orange : Colors.deepPurple),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text("\$${item.price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
          Expanded(flex: 1, child: Switch(value: item.isAvailable, onChanged: (v) => bloc.add(ToggleMenuAvailability(item.id, item.isAvailable)), activeColor: Colors.green)),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.orange, size: 20), onPressed: () {}), // Edit logic
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _confirmDelete(context, item.id, bloc)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, MenuBloc mBloc, CategoryBloc cBloc) {
    final name = TextEditingController();
    final price = TextEditingController();
    final desc = TextEditingController();
    int? selectedCatId;
    bool isReadyToServe = false;
    int prepTime = 15;
    File? img;

    if (cBloc.state is! CategoryLoaded) {
      cBloc.add(LoadCategories());
      return;
    }
    final activeCats = (cBloc.state as CategoryLoaded).categories.where((c) => c.isActive).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 500, padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Create New Product", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final f = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (f != null) setState(() => img = File(f.path));
                      },
                      child: Container(
                        height: 120, width: 120,
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
                        child: img == null ? const Icon(Icons.add_a_photo_outlined, size: 30) : ClipRRect(borderRadius: BorderRadius.circular(19), child: Image.file(img!, fit: BoxFit.cover)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDropdown(activeCats, (v) => selectedCatId = v),
                  const SizedBox(height: 16),
                  _buildModernField(name, "Item Name", Icons.fastfood_outlined),
                  const SizedBox(height: 16),
                  _buildModernField(price, "Price (\$)", Icons.payments_outlined, isNum: true),
                  const SizedBox(height: 16),

                  // 🌟 OPERATIONAL LOGIC
                  const Divider(height: 32),
                  SwitchListTile(
                    title: const Text("Ready to Serve (Instant)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text("Item is pre-made (Coke, Sweets, etc.)", style: TextStyle(fontSize: 12)),
                    value: isReadyToServe,
                    activeColor: Colors.orange,
                    onChanged: (v) => setState(() => isReadyToServe = v),
                  ),
                  if (!isReadyToServe) ...[
                    const SizedBox(height: 8),
                    Text("Preparation Time: $prepTime mins", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Slider(
                      value: prepTime.toDouble(),
                      min: 5, max: 60, divisions: 11,
                      activeColor: Colors.deepPurple,
                      onChanged: (v) => setState(() => prepTime = v.toInt()),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel"))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedCatId != null && name.text.isNotEmpty) {
                              mBloc.add(AddMenuItem(
                                  name: name.text, desc: desc.text, price: double.parse(price.text),
                                  catId: selectedCatId!, isReadyToServe: isReadyToServe, prepTime: prepTime, img: img
                              ));
                              Navigator.pop(ctx);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), foregroundColor: Colors.white, padding: const EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text("Create Product"),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildBadge(String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)));

  Widget _buildModernField(TextEditingController ctrl, String hint, IconData icon, {bool isNum = false}) {
    return TextField(controller: ctrl, keyboardType: isNum ? TextInputType.number : TextInputType.text, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 20), filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));
  }

  Widget _buildDropdown(List<CategoryEntity> cats, Function(int?) onChange) {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(hintText: "Select Category", filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
      items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
      onChanged: onChange,
    );
  }

  void _confirmDelete(BuildContext context, int id, MenuBloc bloc) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Confirm Delete?"), content: const Text("This action cannot be undone."), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), TextButton(onPressed: () { bloc.add(DeleteMenuItem(id)); Navigator.pop(ctx); }, child: const Text("Delete", style: TextStyle(color: Colors.red)))]));
  }
}