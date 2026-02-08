import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MainDashboard extends StatefulWidget {
  final Widget child;
  const MainDashboard({super.key, required this.child});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  static const Color cyanPrimary = Color(0xFF00BCD4);
  static const Color darkGrey = Color(0xFF1A1C24);
  final storage = const FlutterSecureStorage();

  String _userName = "Loading...";
  String _userRole = "Staff";
  String _initials = "U";
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initializeRole();
  }

  Future<void> _initializeRole() async {
    final role = await storage.read(key: 'user_role') ?? "staff";
    final name = await storage.read(key: 'name') ?? "User";

    setState(() {
      _userRole = role.toLowerCase(); // Lowercase for safe comparison
      _userName = name;
      _initials = name.isNotEmpty ? name[0].toUpperCase() : "U";
      _isReady = true;
    });
  }

  // ✅ Role-Based Filtered Items
  List<NavigationRailDestination> _getFilteredDestinations() {
    List<NavigationRailDestination> items = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard, color: cyanPrimary),
        label: Text('Dashboard'),
      ),
    ];

    // ✅ Yahan humne superuser, admin aur manager ko handle kiya hai
    if (_userRole == 'superuser' || _userRole == 'admin' || _userRole == 'manager') {
      items.addAll([
        const NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long, color: cyanPrimary),
          label: Text('Billing'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart, color: cyanPrimary),
          label: Text('Reports'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.history),
          selectedIcon: Icon(Icons.history, color: cyanPrimary),
          label: Text('Order History'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings, color: cyanPrimary),
          label: Text("Settings"),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.person_add_alt_1_rounded),
          selectedIcon: Icon(Icons.person_add_alt_1_rounded, color: cyanPrimary),
          label: Text("Manage Users"),
        ),
      ]);
    }

    return items;
  }

  // ✅ Corrected Index Finder
  int _getSelectedIndex(List<NavigationRailDestination> destinations) {
    final String location = GoRouterState.of(context).uri.path;

    // Check path logic instead of hardcoded numbers
    if (location.contains('billing')) return _findLabelIndex(destinations, 'Billing');
    if (location.contains('reports')) return _findLabelIndex(destinations, 'Reports');
    if (location.contains('settings')) return _findLabelIndex(destinations, 'Settings');
    if (location.contains('history')) return _findLabelIndex(destinations, 'Order History');
    if (location.contains('manage_user')) return _findLabelIndex(destinations, 'Manage Users');

    return 0; // Default to Dashboard
  }

  int _findLabelIndex(List<NavigationRailDestination> destinations, String label) {
    for (int i = 0; i < destinations.length; i++) {
      if ((destinations[i].label as Text).data == label) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: cyanPrimary)));
    }

    final destinations = _getFilteredDestinations();
    final int selectedIndex = _getSelectedIndex(destinations);
    final bool isExtended = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: _buildProfessionalAppBar(context),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Colors.white,
            indicatorColor: cyanPrimary.withOpacity(0.1),
            extended: isExtended,
            minExtendedWidth: 200,
            selectedIndex: selectedIndex >= destinations.length ? 0 : selectedIndex,
            onDestinationSelected: (int index) {
              _onItemTapped(index, context, destinations);
            },
            leading: _buildLeading(isExtended),
            trailing: _buildTrailing(isExtended, context),
            destinations: destinations,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFB),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index, BuildContext context, List<NavigationRailDestination> currentItems) {
    final String label = (currentItems[index].label as Text).data!;
    switch (label) {
      case 'Dashboard': context.go('/dashboard'); break;
      case 'Billing': context.go('/billing'); break;
      case 'Reports': context.go('/reports'); break;
      case 'Order History': context.go('/order_history'); break;
      case 'Settings': context.go('/settings'); break;
      case 'Manage Users': context.go('/manage_user'); break;
    }
  }

  Widget _buildLeading(bool isExtended) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.restaurant_menu, color: cyanPrimary, size: 36),
        if (isExtended) ...[
          const SizedBox(height: 10),
          const Text("SVENSKA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkGrey)),
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildTrailing(bool isExtended, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () => _logout(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isExtended ? 16 : 8, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
              if (isExtended) ...[
                const SizedBox(width: 12),
                const Text("Sign out", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.redAccent)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildProfessionalAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      toolbarHeight: 80,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SVENSKA RESTAURANT", style: TextStyle(color: darkGrey, fontWeight: FontWeight.w900, fontSize: 18)),
          Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
      actions: [_buildUserIdentity()],
    );
  }

  Widget _buildUserIdentity() {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_userName, style: const TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: cyanPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(_userRole.toUpperCase(), style: const TextStyle(color: cyanPrimary, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          CircleAvatar(radius: 22, backgroundColor: darkGrey, child: Text(_initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await storage.deleteAll();
    if (mounted) context.go('/login');
  }
}