
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/category_bloc.dart';
import '../../domain/entities/category_entity.dart';

class CategoryManagementView extends StatefulWidget {
  const CategoryManagementView({super.key});

  @override
  State<CategoryManagementView> createState() => _CategoryManagementViewState();
}

class _CategoryManagementViewState extends State<CategoryManagementView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(LoadCategories());
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CategoryBloc>();

    return Container(
      color: const Color(0xFFF4F7FA),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Category Management", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const Text("Manage your menu stations and item categories", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => bloc.add(LoadCategories(query: val)),
                  decoration: InputDecoration(
                      hintText: "Search categories...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(context, bloc),
                icon: const Icon(Icons.add),
                label: const Text("New Category"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1C24), // Professional Dark Theme
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoading) return const Center(child: CircularProgressIndicator());
                if (state is CategoryLoaded) return _buildTable(state.categories, bloc);
                if (state is CategoryError) return Center(child: Text(state.message));
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<CategoryEntity> list, CategoryBloc bloc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text("IMAGE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 2, child: Text("NAME & DESC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text("STATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 1, child: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _buildCategoryRow(list[index], bloc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(CategoryEntity cat, CategoryBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: CircleAvatar(
              radius: 24,
              backgroundImage: cat.image != null ? NetworkImage(cat.image!) : null,
              child: cat.image == null ? const Icon(Icons.fastfood) : null,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(cat.description, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1),
              ],
            ),
          ),
          // 🌟 STATION BADGE
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(6)),
              child: Text(cat.station.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
            ),
          ),
          Expanded(flex: 1, child: _buildStatusBadge(cat.isActive)),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.orange), onPressed: () => _showFormDialog(context, bloc, category: cat)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () => _confirmDelete(context, cat.id, bloc)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, CategoryBloc bloc, {CategoryEntity? category}) {
    final nameController = TextEditingController(text: category?.name);
    final descController = TextEditingController(text: category?.description);
    String selectedStation = category?.station ?? 'kitchen';
    File? imgFile;

    final List<Map<String, String>> stations = [
      {'value': 'kitchen', 'label': 'Main Kitchen'},
      {'value': 'bar', 'label': 'Bar / Drinks'},
      {'value': 'pantry', 'label': 'Pantry / Snacks'},
      {'value': 'tandoor', 'label': 'Tandoor / Grill'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category == null ? "New Category" : "Edit Category", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (file != null) setDialogState(() => imgFile = File(file.path));
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: imgFile != null ? FileImage(imgFile!) : (category?.image != null ? NetworkImage(category!.image!) : null) as ImageProvider?,
                      child: (imgFile == null && category?.image == null) ? const Icon(Icons.camera_alt) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildField(nameController, "Category Name"),
                const SizedBox(height: 16),
                _buildField(descController, "Description", maxLines: 2),
                const SizedBox(height: 16),

                // 🌟 STATION DROPDOWN
                const Text("Assign to Station", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedStation,
                      items: stations.map((s) => DropdownMenuItem(value: s['value'], child: Text(s['label']!))).toList(),
                      onChanged: (val) => setDialogState(() => selectedStation = val!),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel"))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), foregroundColor: Colors.white),
                        onPressed: () {
                          if (nameController.text.isNotEmpty) {
                            if (category == null) {
                              bloc.add(AddCategory(name: nameController.text, description: descController.text, station: selectedStation, image: imgFile));
                            } else {
                              bloc.add(EditCategory(id: category.id, name: nameController.text, description: descController.text, station: selectedStation, image: imgFile, isActive: category.isActive));
                            }
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text("Save Category"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
          hintText: hint, filled: true, fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: isActive ? Colors.green[50] : Colors.red[50], borderRadius: BorderRadius.circular(12)),
    child: Text(isActive ? "ACTIVE" : "INACTIVE", style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  void _confirmDelete(BuildContext context, int id, CategoryBloc bloc) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Delete Category?"),
      content: const Text("Linked menu items may be affected."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        TextButton(onPressed: () { bloc.add(DeleteCategory(id)); Navigator.pop(ctx); }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
      ],
    ));
  }
}