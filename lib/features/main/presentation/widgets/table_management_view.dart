/*
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/table_bloc.dart';
import '../../domain/entities/table_entity.dart';

class TableManagementView extends StatefulWidget {
  const TableManagementView({super.key});

  @override
  State<TableManagementView> createState() => _TableManagementViewState();
}

class _TableManagementViewState extends State<TableManagementView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ✅ Initial data load
    context.read<TableBloc>().add(LoadTables());
  }

  @override
  Widget build(BuildContext context) {
    final tableBloc = context.read<TableBloc>();

    return Container(
      color: const Color(0xFFF4F7FA),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Table Management",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3243))),
          const Text("Manage restaurant tables and QR codes",
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),

          // --- Action Bar ---
          _buildActionBar(context, tableBloc),

          const SizedBox(height: 24),

          // --- Table List Section ---
          Expanded(
            child: BlocBuilder<TableBloc, TableState>(
              // ✅ No white screen on error/update
              buildWhen: (previous, current) => current is! TableError,
              builder: (context, state) {
                if (state is TableLoading) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
                }

                if (state is TableLoaded) {
                  if (state.tables.isEmpty) return _buildEmptyState();
                  return _buildProfessionalTable(state.tables, tableBloc);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Professional Header & Search ---
  Widget _buildActionBar(BuildContext context, TableBloc bloc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => bloc.add(SearchTables(value)),
              decoration: const InputDecoration(
                hintText: "Search tables by ID or Number...",
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddTableDialog(context, bloc),
            icon: const Icon(Icons.add_rounded),
            label: const Text("ADD NEW TABLE"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1C24),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Main Table Design (No Horizontal Scroll) ---
  Widget _buildProfessionalTable(List<TableEntity> tables, TableBloc bloc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text("QR CODE", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("TABLE DETAILS", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold,))),
              ],
            ),
          ),
          // Scrollable List
          Expanded(
            child: ListView.separated(
              itemCount: tables.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final table = tables[index];
                return _buildTableRow(table, bloc);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(TableEntity table, TableBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // 🖼️ QR Image with Professional Preview
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => _showImagePreview(context, table.qrCodeImage, "Table ${table.tableNumber} QR"),
              child: Container(
                height: 55, width: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade100),
                  image: table.qrCodeImage != null
                      ? DecorationImage(image: NetworkImage(table.qrCodeImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: table.qrCodeImage == null ? const Icon(Icons.qr_code_scanner, color: Colors.grey) : null,
              ),
            ),
          ),
          // 📝 Info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Table No: ${table.tableNumber}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("UUID: ${table.qrId.substring(0, 8)}...", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          // 🟢 Status
          Expanded(
            flex: 1,
            child: _buildStatusBadge(table.isActive),
          ),
          // ⚙️ Actions
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.orange),
                  onPressed: () => _showEditTableDialog(context, table, bloc),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(context, table.id, bloc),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Image Preview Logic (No Rebuild) ---
  void _showImagePreview(BuildContext context, String? url, String title) {
    if (url == null) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "",
      barrierColor: Colors.black.withOpacity(0.85),
      pageBuilder: (ctx, anim1, anim2) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(title, style: const TextStyle(color: Colors.white)),
          leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
        ),
        body: Center(child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain))),
      ),
    );
  }

  // --- Professional Status Badge ---
  Widget _buildStatusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? "ACTIVE" : "INACTIVE",
        textAlign: TextAlign.center,
        style: TextStyle(color: active ? Colors.green : Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- Dialogs (Add, Edit, Delete) ---
  void _showAddTableDialog(BuildContext context, TableBloc bloc) {
    final controller = TextEditingController();
    _showModernDialog(
        context,
        "Register New Table",
        TextField(controller: controller, decoration: const InputDecoration(labelText: "Table Number", prefixIcon: Icon(Icons.tag))),
            () {
          if (controller.text.trim().isNotEmpty) {
            bloc.add(AddTable(controller.text.trim()));
            Navigator.pop(context);
          }
        }
    );
  }

  void _showEditTableDialog(BuildContext context, TableEntity table, TableBloc bloc) {
    final controller = TextEditingController(text: table.tableNumber);
    bool isActive = table.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Update Table Settings"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, decoration: const InputDecoration(labelText: "Table Number")),
              const SizedBox(height: 12),
              SwitchListTile(
                  title: const Text("Availability Status"),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val)
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () {
                bloc.add(UpdateTable(id: table.id, tableNumber: controller.text.trim(), isActive: isActive));
                Navigator.pop(ctx);
              },
              child: const Text("SAVE CHANGES"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, TableBloc bloc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Table?"),
        content: const Text("This will permanently remove the table and its QR code."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("KEEP")),
          TextButton(
              onPressed: () { bloc.add(DeleteTable(id)); Navigator.pop(ctx); },
              child: const Text("DELETE", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showModernDialog(BuildContext context, String title, Widget content, VoidCallback onSave) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: content,
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(onPressed: onSave, child: const Text("CONFIRM")),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => const Center(child: Text("No tables found. Add your first table!"));
}*/

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/table_bloc.dart';
import '../../domain/entities/table_entity.dart';

class TableManagementView extends StatefulWidget {
  const TableManagementView({super.key});

  @override
  State<TableManagementView> createState() => _TableManagementViewState();
}

class _TableManagementViewState extends State<TableManagementView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TableBloc>().add(LoadTables());
  }

  @override
  Widget build(BuildContext context) {
    final tableBloc = context.read<TableBloc>();

    return BlocListener<TableBloc, TableState>(
      listener: (context, state) {
        if (state is TableError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Container(
        color: const Color(0xFFF4F7FA),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Table Inventory",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3243))),
            const Text("Register new tables and manage QR code visibility",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),

            _buildActionBar(context, tableBloc),
            const SizedBox(height: 24),

            Expanded(
              child: BlocBuilder<TableBloc, TableState>(
                buildWhen: (previous, current) => current is! TableError,
                builder: (context, state) {
                  if (state is TableLoading) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
                  }

                  if (state is TableLoaded) {
                    if (state.tables.isEmpty) return _buildEmptyState();
                    return _buildProfessionalTable(state.tables, tableBloc);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Header Action Bar ---
  Widget _buildActionBar(BuildContext context, TableBloc bloc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => bloc.add(SearchTables(value)),
              decoration: const InputDecoration(
                hintText: "Search tables by ID or Number...",
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddTableDialog(context, bloc),
            icon: const Icon(Icons.add_rounded),
            label: const Text("REGISTER TABLE"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1C24),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Table List View ---
  Widget _buildProfessionalTable(List<TableEntity> tables, TableBloc bloc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
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
                Expanded(flex: 1, child: Text("QR PREVIEW", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text("TABLE NUMBER", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("ACTIVE STATUS", style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold,))),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: tables.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _buildTableRow(tables[index], bloc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(TableEntity table, TableBloc bloc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => _showImagePreview(context, table.qrCodeImage, "QR: Table ${table.tableNumber}"),
              child: Container(
                height: 50, width: 50,
                alignment: Alignment.centerLeft,
                child: table.qrCodeImage != null
                    ? Image.network(table.qrCodeImage!, width: 45)
                    : const Icon(Icons.qr_code_2, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text("Table No. ${table.tableNumber}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            flex: 1,
            child: _buildStatusBadge(table.isActive),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey), onPressed: () => _showEditTableDialog(context, table, bloc)),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDelete(context, table.id, bloc)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Shared Logic ---
  Widget _buildStatusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: active ? Colors.green[50] : Colors.grey[100], borderRadius: BorderRadius.circular(20)),
      child: Text(active ? "ACTIVE" : "DISABLED", style: TextStyle(color: active ? Colors.green : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _showImagePreview(BuildContext context, String? url, String title) {
    if (url == null) return;
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(title),
      content: Image.network(url),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))],
    ));
  }

  void _showAddTableDialog(BuildContext context, TableBloc bloc) {
    final controller = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Add New Table"),
      content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Enter Table Number")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
        ElevatedButton(onPressed: () { bloc.add(AddTable(controller.text)); Navigator.pop(ctx); }, child: const Text("SAVE")),
      ],
    ));
  }

  void _showEditTableDialog(BuildContext context, TableEntity table, TableBloc bloc) {
    final controller = TextEditingController(text: table.tableNumber);
    bool isActive = table.isActive;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setST) => AlertDialog(
      title: const Text("Edit Table"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: controller, decoration: const InputDecoration(labelText: "Table Number")),
        SwitchListTile(title: const Text("Is Active?"), value: isActive, onChanged: (v) => setST(() => isActive = v)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
        ElevatedButton(onPressed: () {
          bloc.add(UpdateTable(id: table.id, tableNumber: controller.text, isActive: isActive));
          Navigator.pop(ctx);
        }, child: const Text("UPDATE")),
      ],
    )));
  }

  void _confirmDelete(BuildContext context, int id, TableBloc bloc) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Delete Table?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("NO")),
        TextButton(onPressed: () { bloc.add(DeleteTable(id)); Navigator.pop(ctx); }, child: const Text("YES", style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  Widget _buildEmptyState() => const Center(child: Text("No tables found. Add your first table!"));
}