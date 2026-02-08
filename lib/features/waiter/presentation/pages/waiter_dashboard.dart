/*
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:svenska/core/utils/routes_name.dart';
import '../../../../injection.dart';
import '../block/waiter_table_bloc.dart';
import '../block/waiter_table_event.dart';
import '../block/waiter_table_state.dart';
import '../widgets/dashboard_empty_state.dart';
import '../widgets/dashboard_state.dart';
import '../widgets/guest_selector_sheet.dart';
import '../widgets/order_tracker_view.dart';
import '../widgets/table_chip_list.dart';

class WaiterDashboard extends StatefulWidget {
  const WaiterDashboard({super.key});
  @override
  State<WaiterDashboard> createState() => _WaiterDashboardState();
}

class _WaiterDashboardState extends State<WaiterDashboard> {
  final Color cyan = const Color(0xFF00FFFF);
  dynamic selectedTable;
  bool _isScannerOpen = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
      WaiterTableBloc(apiClient: sl(), wsService: sl())
        ..add(FetchMyTables()),
      child: BlocListener<WaiterTableBloc, WaiterTableState>(
        listener: _blocListener,
        child: Builder(
          builder: (newContext) {
            return Scaffold(
              backgroundColor: const Color(0xFF0A0A0A),
              appBar: AppBar(
                title: Text(
                  "SVENSKA CAPTAIN",
                  style: TextStyle(
                    color: cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                backgroundColor: const Color(0xFF121212),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.grey),
                    onPressed: () => _showLogoutDialog(newContext),
                  ),
                ],
              ),
              body: BlocBuilder<WaiterTableBloc, WaiterTableState>(
                builder: (context, state) {
                  List tables = (state is WaiterTableLoaded)
                      ? state.tables
                      : [];

                  // 🌟 Logic: Build ke waqt selected table ko update karo agar list change hui ho
                  _syncSelectedTable(tables);

                  if (state is WaiterTableLoading && tables.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(color: cyan),
                    );
                  }

                  return Column(
                    children: [
                      DashboardStats(tables: tables, cyan: cyan),
                      TableChips(
                        tables: tables,
                        selectedTable: selectedTable,
                        cyan: cyan,
                        onSelected: (t) {
                          setState(() => selectedTable = t);
                        },
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      Expanded(
                        child: tables.isEmpty
                            ? const DashboardEmptyState()
                            : OrderTracker(
                          table: selectedTable,
                          cyan: cyan,
                          onNewManualOrder: () =>
                              _showGuestSheet(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
              floatingActionButton: FloatingActionButton(
                backgroundColor: cyan,
                onPressed: () => _openScanner(newContext),
                child: const Icon(Icons.qr_code_scanner, color: Colors.black),
              ),
            );
          },
        ),
      ),
    );
  }

  void _updateSelectedTable(List tables) {
    if (tables.isEmpty) {
      selectedTable = null;
    } else if (selectedTable == null) {
      selectedTable = tables.first;
    } else {
      selectedTable = tables.firstWhere(
            (t) => t['table_id'] == selectedTable['table_id'],
        orElse: () => tables.first,
      );
    }
  }

  void _openScanner(BuildContext context) {
    if (_isScannerOpen) return;
    _isScannerOpen = true;
    final waiterBloc = context.read<WaiterTableBloc>();
    bool hasDetected = false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (scannerContext) => Scaffold(
          appBar: AppBar(
            title: const Text("Scan Table QR"),
            backgroundColor: Colors.black,
          ),
          body: MobileScanner(
            onDetect: (capture) {
              if (hasDetected) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                hasDetected = true;
                Navigator.pop(scannerContext);
                waiterBloc.add(ClaimTable(barcodes.first.rawValue ?? ""));
              }
            },
          ),
        ),
      ),
    ).then((_) => _isScannerOpen = false);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("LOGOUT", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cyan),
            onPressed: () async {
              await sl<FlutterSecureStorage>().deleteAll();
              if (mounted) context.go('/login');
            },
            child: const Text("LOGOUT", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _syncSelectedTable(List tables) {
    if (tables.isEmpty) {
      selectedTable = null;
    } else if (selectedTable == null) {
      selectedTable = tables.first;
    } else {
      // Refresh ke baad bhi wahi table pakad ke rakhe jo pehle thi
      try {
        selectedTable = tables.firstWhere(
              (t) => t['id'] == selectedTable['id'],
          orElse: () => tables.first,
        );
      } catch (e) {
        selectedTable = tables.first;
      }
    }
  }

  void _blocListener(BuildContext context, WaiterTableState state) {
    if (state is ClaimTableSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.green),
      );
      // Scan ke baad turant dashboard refresh karo
      context.read<WaiterTableBloc>().add(FetchMyTables());
    }

    if (state is WaiterTableLoaded) {
      // Jab data load ho jaye, state refresh karo taaki UI update ho
      setState(() {
        _syncSelectedTable(state.tables);
      });
    }

    if (state is WaiterTableError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
    }
  }

  void _showGuestSheet(BuildContext context) {
    if (selectedTable == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GuestSelectorSheet(
        cyan: cyan,
        onConfirm: (name) {
          Navigator.pop(ctx);
          context.push(
            AppRoutes.menuSelectionScreen,
            extra: {
              'order_id': null,
              'table_id':
              selectedTable['id'], // 'table_id' ki jagah sirf 'id' serialzer wala
              'table_number': selectedTable['table_number'],
              'guest_name': name,
            },
          );
        },
      ),
    );
  }
}*/


/*

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:svenska/core/utils/routes_name.dart';
import '../../../../core/utils/websocket/websocket_service.dart';
import '../../../../injection.dart';
import '../block/waiter_table_bloc.dart';
import '../block/waiter_table_event.dart';
import '../block/waiter_table_state.dart';
import '../widgets/dashboard_empty_state.dart';
import '../widgets/dashboard_state.dart';
import '../widgets/guest_selector_sheet.dart';
import '../widgets/order_tracker_view.dart';
import '../widgets/table_chip_list.dart';

class WaiterDashboard extends StatefulWidget {
  const WaiterDashboard({super.key});
  @override
  State<WaiterDashboard> createState() => _WaiterDashboardState();
}

class _WaiterDashboardState extends State<WaiterDashboard> {
  final Color cyan = const Color(0xFF00FFFF);
  dynamic selectedTable;
  bool _isScannerOpen = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WaiterTableBloc(apiClient: sl(), wsService: sl())..add(FetchMyTables()),
      child: BlocListener<WaiterTableBloc, WaiterTableState>(
        listener: _blocListener,
        child: Builder(builder: (newContext) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0A0A),
            appBar: AppBar(
              title: Text("SVENSKA CAPTAIN",
                  style: TextStyle(color: cyan, fontWeight: FontWeight.bold, fontSize: 16)),
              backgroundColor: const Color(0xFF121212),
              actions: [
                ValueListenableBuilder<bool>(
                  valueListenable: GetIt.I<WebSocketService>().isConnected,
                  builder: (context, connected, child) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: connected ? Colors.greenAccent : Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            connected ? "LIVE" : "OFFLINE",
                            style: TextStyle(
                                color: connected ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                IconButton(
                    icon: const Icon(Icons.logout, color: Colors.grey),
                    onPressed: () => _showLogoutDialog(newContext))
              ],
            ),
            body: BlocBuilder<WaiterTableBloc, WaiterTableState>(
              builder: (context, state) {
                List tables = (state is WaiterTableLoaded) ? state.tables : [];

                // 🌟 Logic: Build ke waqt selected table ko data ke saath sync rakho
                _syncSelectedTable(tables);

                if (state is WaiterTableLoading && tables.isEmpty) {
                  return Center(child: CircularProgressIndicator(color: cyan));
                }

                return Column(
                  children: [
                    DashboardStats(tables: tables, cyan: cyan),
                    // 🌟 TableChips Widget (Fix: unique selection + order count)
                    TableChips(
                      tables: tables,
                      selectedTable: selectedTable,
                      cyan: cyan,
                      onSelected: (t) => setState(() => selectedTable = t),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    Expanded(
                      child: tables.isEmpty
                          ? const DashboardEmptyState()
                          : OrderTracker(
                        table: selectedTable,
                        cyan: cyan,
                        onNewManualOrder: () => _showGuestSheet(context),
                      ),
                    ),
                  ],
                );
              },
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: cyan,
              onPressed: () => _openScanner(newContext),
              child: const Icon(Icons.qr_code_scanner, color: Colors.black),
            ),
          );
        }),
      ),
    );
  }


  void _syncSelectedTable(List tables) {
    if (tables.isEmpty) {
      selectedTable = null;
    } else {
      if (selectedTable == null) {
        selectedTable = tables.first;
      } else {
        // 🌟 FIND AND REPLACE: Purane object ko naye API data wale object se badal do
        final updatedTable = tables.firstWhere(
              (t) => t['id'] == selectedTable['id'],
          orElse: () => tables.first,
        );

        // Agar data change hua hai toh setState trigger hoga BlocListener se
        selectedTable = updatedTable;
      }
    }
  }

  void _blocListener(BuildContext context, WaiterTableState state) {
    if (state is ClaimTableSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.green),
      );
      context.read<WaiterTableBloc>().add(FetchMyTables());
    }
    if (state is WaiterTableLoaded) {
      setState(() {
        _syncSelectedTable(state.tables);
      });
    }
    if (state is WaiterTableError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
    }
  }

  void _openScanner(BuildContext context) {
    if (_isScannerOpen) return;
    _isScannerOpen = true;
    final waiterBloc = context.read<WaiterTableBloc>();
    bool hasDetected = false;

    Navigator.push(context, MaterialPageRoute(
      builder: (scannerContext) => Scaffold(
        appBar: AppBar(title: const Text("Scan Table QR"), backgroundColor: Colors.cyan),
        body: MobileScanner(onDetect: (capture) {
          if (hasDetected) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            hasDetected = true;
            Navigator.pop(scannerContext);
            waiterBloc.add(ClaimTable(barcodes.first.rawValue ?? ""));
          }
        }),
      ),
    )).then((_) => _isScannerOpen = false);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text("LOGOUT", style: TextStyle(color: Colors.white)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
        ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cyan),
            onPressed: () async {
              await sl<FlutterSecureStorage>().deleteAll();
              if (mounted) context.go('/login');
            },
            child: const Text("LOGOUT", style: TextStyle(color: Colors.black))),
      ],
    ));
  }

  // WaiterDashboard.dart ke andar

  void _showGuestSheet(BuildContext context) {
    if (selectedTable == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GuestSelectorSheet(
        cyan: cyan,
        onConfirm: (name) {
          Navigator.pop(ctx);

          // 🌟 FIX: context.push ke baad .then() lagao
          context.push(
            AppRoutes.menuSelectionScreen,
            extra: {
              'order_id': null,
              'table_id': selectedTable['id'],
              'table_number': selectedTable['table_number'],
              'guest_name': name,
            },
          ).then((_) {
            // ✅ Yeh line tab chalegi jab aap Menu se wapas Dashboard par aaoge
            if (context.mounted) {
              context.read<WaiterTableBloc>().add(FetchMyTables());
            }
          });
        },
      ),
    );
  }

}*/


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/utils/routes_name.dart';
import '../../../../core/utils/websocket/websocket_service.dart';
import '../../../../injection.dart';
import '../block/waiter_table_bloc.dart';
import '../block/waiter_table_event.dart';
import '../block/waiter_table_state.dart';
import '../widgets/dashboard_empty_state.dart';
import '../widgets/dashboard_state.dart';
import '../widgets/guest_selector_sheet.dart';
import '../widgets/order_tracker_view.dart';
import '../widgets/table_chip_list.dart';

class WaiterDashboard extends StatefulWidget {
  const WaiterDashboard({super.key});
  @override
  State<WaiterDashboard> createState() => _WaiterDashboardState();
}

class _WaiterDashboardState extends State<WaiterDashboard> {
  final Color cyan = const Color(0xFF00FFFF);
  dynamic selectedTable;
  bool _isScannerOpen = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WaiterTableBloc(apiClient: sl(), wsService: sl())..add(FetchMyTables()),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        // ✅ FIXED: AppBar Scaffold ke direct niche hai, ab kabhi gayab nahi hoga
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          elevation: 4,
          title: BlocBuilder<WaiterTableBloc, WaiterTableState>(
            builder: (context, state) {
              // 🌟 Default placeholders
              String waiterName = "WAITER";
              String displayRole = "CAPTAIN";

              // 🌟 Check: Agar state Loaded hai, toh direct state ke variables use karo
              if (state is WaiterTableLoaded) {
                waiterName = state.username; // Bloc se aaya hua username
                displayRole = state.role;    // Bloc se aaya hua role
              }

              return Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: cyan.withOpacity(0.1),
                    child: Icon(Icons.person, color: cyan, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "SVENSKA CAPTAIN",
                        style: TextStyle(
                          color: cyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        "${displayRole.toUpperCase()} || ${waiterName.toUpperCase()}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      // Waiter Name (Bold text)
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            _buildSocketIndicator(),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red, size: 20),
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: BlocListener<WaiterTableBloc, WaiterTableState>(
          listener: _blocListener,
          child: BlocBuilder<WaiterTableBloc, WaiterTableState>(
            builder: (context, state) {
              List tables = (state is WaiterTableLoaded) ? state.tables : [];

              _syncSelectedTable(tables);

              if (state is WaiterTableLoading && tables.isEmpty) {
                return Center(child: CircularProgressIndicator(color: cyan));
              }

              if (state is WaiterTableError && tables.isEmpty) {
                return _buildErrorState(context, state.message);
              }

              return Column(
                children: [
                  DashboardStats(tables: tables, cyan: cyan),
                  TableChips(
                    tables: tables,
                    selectedTable: selectedTable,
                    cyan: cyan,
                    onSelected: (t) => setState(() => selectedTable = t),
                  ),
                  const Divider(color: Colors.white10, height: 1),
                  Expanded(
                    child: tables.isEmpty
                        ? const DashboardEmptyState()
                        : OrderTracker(
                      table: selectedTable,
                      cyan: cyan,
                      onNewManualOrder: () => _showGuestSheet(context),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: Builder(builder: (c) {
          return FloatingActionButton(
            backgroundColor: cyan,
            onPressed: () => _openScanner(c),
            child: const Icon(Icons.qr_code_scanner, color: Colors.black),
          );
        }),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildSocketIndicator() {
    return ValueListenableBuilder<bool>(
      valueListenable: GetIt.I<WebSocketService>().isConnected,
      builder: (context, connected, child) {
        return Row(
          children: [
            Icon(Icons.circle, size: 8, color: connected ? Colors.greenAccent : Colors.redAccent),
            const SizedBox(width: 4),
            Text(connected ? "LIVE" : "OFF", style: TextStyle(color: connected ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: Colors.white24, size: 50),
          Padding(padding: const EdgeInsets.all(16), child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white24))),
          ElevatedButton(onPressed: () => context.read<WaiterTableBloc>().add(FetchMyTables()), child: const Text("RETRY")),
        ],
      ),
    );
  }

  // --- Helper Methods (Scan, Sync, Sheets) ---

  void _syncSelectedTable(List tables) {
    if (tables.isEmpty) {
      selectedTable = null;
    } else if (selectedTable == null) {
      selectedTable = tables.first;
    } else {
      try {
        selectedTable = tables.firstWhere((t) => t['id'] == selectedTable['id'], orElse: () => tables.first);
      } catch (_) {
        selectedTable = tables.first;
      }
    }
  }

  void _blocListener(BuildContext context, WaiterTableState state) {
    if (state is ClaimTableSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
      context.read<WaiterTableBloc>().add(FetchMyTables());
    }
    if (state is WaiterTableError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
    }
  }

  void _openScanner(BuildContext context) {
    if (_isScannerOpen) return;
    _isScannerOpen = true;
    final waiterBloc = context.read<WaiterTableBloc>();
    bool hasDetected = false;

    Navigator.push(context, MaterialPageRoute(
      builder: (scannerContext) => Scaffold(
        appBar: AppBar(title: const Text("Scan Table QR"), backgroundColor: Colors.black),
        body: MobileScanner(onDetect: (capture) {
          if (hasDetected) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            hasDetected = true;
            Navigator.pop(scannerContext);
            waiterBloc.add(ClaimTable(barcodes.first.rawValue ?? ""));
          }
        }),
      ),
    )).then((_) => _isScannerOpen = false);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text("LOGOUT", style: TextStyle(color: Colors.white)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: cyan), onPressed: () async {
          await GetIt.I<FlutterSecureStorage>().deleteAll();
          if (mounted) context.go('/login');
        }, child: const Text("LOGOUT", style: TextStyle(color: Colors.black))),
      ],
    ));
  }

  void _showGuestSheet(BuildContext context) {
    if (selectedTable == null) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => GuestSelectorSheet(cyan: cyan, onConfirm: (name) {
        Navigator.pop(ctx);
        context.push(AppRoutes.menuSelectionScreen, extra: {
          'order_id': null, 'table_id': selectedTable['id'], 'table_number': selectedTable['table_number'], 'guest_name': name,
        }).then((_) { if (context.mounted) context.read<WaiterTableBloc>().add(FetchMyTables()); });
      }),
    );
  }
}