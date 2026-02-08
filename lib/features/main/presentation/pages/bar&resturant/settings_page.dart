import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../main/presentation/bloc/category_bloc.dart';
import '../../../../main/presentation/widgets/offer_and_discount_management.dart';
import '../../../../../injection.dart';
import '../../bloc/menu_bloc.dart';
import '../../bloc/table_bloc.dart';
import '../../widgets/category_management_view.dart';
import '../../widgets/menu_management_view.dart';
import '../../widgets/table_management_view.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Theme Colors
  static const Color cyanPrimary = Color(0xFF00BCD4);
  static const Color darkGrey = Color(0xFF1A1C24);
  static const Color surfaceGrey = Color(0xFFF4F7F9);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Backoffice & Control",
                style: TextStyle(color: darkGrey, fontWeight: FontWeight.w900, fontSize: 24)),
            Text("Manage your restaurant's digital blueprint",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13, letterSpacing: 0.5)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 40),
          indicatorColor: cyanPrimary,
          indicatorWeight: 4,
          labelColor: cyanPrimary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(child: _TabLabel(Icons.category_outlined, "Categories")),
            Tab(child: _TabLabel(Icons.restaurant_menu_rounded, "Menu Items")),
            Tab(child: _TabLabel(Icons.table_restaurant_outlined, "Table Layout")),
            Tab(child: _TabLabel(Icons.discount, "Discount Layout")),

          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          BlocProvider(create: (context)=>sl<CategoryBloc>(),
          child: CategoryManagementView(),),

          MultiBlocProvider(
            providers: [
              BlocProvider<MenuBloc>(
                create: (context) => sl<MenuBloc>(),
              ),
              BlocProvider<CategoryBloc>(
                create: (context) => sl<CategoryBloc>(),
              ),
            ],
            child: const MenuManagementView(),
          ),

          BlocProvider(
            create: (context) => sl<TableBloc>(),
            child: const TableManagementView(),
          ),

          OfferManagementTab(),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TabLabel(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Text(text),
      ],
    );
  }
}