import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection.dart';
import '../block/menu_selector_bloc.dart';
import '../widgets/menu_item_tile.dart';

class MenuSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const MenuSelectionScreen({super.key, required this.data});

  @override
  State<MenuSelectionScreen> createState() => _MenuSelectionScreenState();
}

class _MenuSelectionScreenState extends State<MenuSelectionScreen> {
  final Color cyan = const Color(0xFF00FFFF);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MenuBloc(apiClient: sl())..add(LoadMenuData()),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.data['guest_name']?.toUpperCase() ?? "NEW ORDER",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyan),
              ),
              Text(
                "Table ${widget.data['table_number'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 14, color: Colors.white54),
              ),
            ],
          ),
          actions: [
            BlocBuilder<MenuBloc, MenuState>(
              builder: (context, state) {
                int count = (state is MenuLoaded) ? state.cart.length : 0;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                      onPressed: () => _showCartBottomSheet(context, state),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text("$count", style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
        ),
        body: BlocConsumer<MenuBloc, MenuState>(
          listener: (context, state) {
            if (state is MenuOrderSuccess) Navigator.pop(context);
          },
          builder: (context, state) {
            // 1. Loading State
            if (state is MenuLoading || state is MenuInitial) {
              return Center(child: CircularProgressIndicator(color: cyan));
            }

            // 2. Error State
            if (state is MenuError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 40),
                    const SizedBox(height: 10),
                    Text(state.message, style: const TextStyle(color: Colors.white70)),
                    TextButton(
                      onPressed: () => context.read<MenuBloc>().add(LoadMenuData()),
                      child: Text("Retry", style: TextStyle(color: cyan)),
                    )
                  ],
                ),
              );
            }

            // 3. Loaded State
            if (state is MenuLoaded) {
              return Column(
                children: [
                  _buildSearchBar(context),
                  _buildCategoryTabs(state, context),
                  Expanded(
                    child: state.filteredItems.isEmpty
                        ? const Center(child: Text("No items found", style: TextStyle(color: Colors.white24)))
                        : // MenuSelectionScreen ke ListView mein:

                    ListView.builder(
                      itemCount: state.filteredItems.length,
                      itemBuilder: (context, idx) {
                        final item = state.filteredItems[idx];
                        return MenuItemTile(
                          item: item,
                          cyan: cyan,
                          onAdd: () {
                            // 🚀 Dashboard se jo seat/name aaya tha, wahi use karo
                            context.read<MenuBloc>().add(AddToCart(
                              item: item,
                              seatName: widget.data['guest_name'] ?? "Guest",
                            ));
                          },
                        );
                      },
                    ),
                  ),
                  if (state.cart.isNotEmpty) _buildConfirmButton(context, state),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }


  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: TextField(
        onChanged: (v) => context.read<MenuBloc>().add(SearchMenu(v)),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: "Search dishes...",
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(MenuLoaded state, BuildContext context) {
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: state.categories.length,
        itemBuilder: (context, index) {
          final cat = state.categories[index];
          bool isSelected = state.activeCategory == cat['name'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(cat['name'], style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 12)),
              selected: isSelected,
              selectedColor: cyan,
              backgroundColor: const Color(0xFF1A1A1A),
              onSelected: (_) => context.read<MenuBloc>().add(FilterByCategory(cat['name'])),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context, MenuLoaded state) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyan,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          if (state.cart.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Pehle items add karein!")),
            );
            return;
          }

          // 🌟 SAFETY CHECK: Check karein ki variables null toh nahi hain
          final String? oId = widget.data['order_id']?.toString();
          final int? tId = widget.data['table_id'];
          final String gName = widget.data['guest_name'] ?? "Guest";

          print("DEBUG: Sending Order - ID: $oId, Table: $tId");

          context.read<MenuBloc>().add(ConfirmOrder(
            orderId: oId == "null" ? null : oId, // 👈 "null" string handle karein
            tableId: tId,
            guestName: gName,
            cartItems: state.cart,
          ));
        },
        child: Text(
          "CONFIRM ORDER (${state.cart.length})",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }


  void _showCartBottomSheet(BuildContext context, MenuState state) {
    if (state is! MenuLoaded || state.cart.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text("CURRENT SELECTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.cart.length,
              itemBuilder: (c, i) {
                final cartItem = state.cart[i];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.cyan, child: Text("${cartItem['seat']}", style: const TextStyle(color: Colors.black))),
                  title: Text(cartItem['item']['name'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                    onPressed: () {
                      context.read<MenuBloc>().add(RemoveFromCart(i));
                      Navigator.pop(ctx); // Close sheet after remove
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}