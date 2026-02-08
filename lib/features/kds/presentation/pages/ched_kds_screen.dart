
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/routes_name.dart';
import '../bloc/kds_bloc.dart';
import '../bloc/kds_event.dart';
import '../bloc/kds_state.dart';

class ChefKDSScreen extends StatelessWidget {
  const ChefKDSScreen({super.key});

  final Color cyan = const Color(0xFF00E5FF);
  final Color orange = const Color(0xFFFF9100);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KdsBloc(apiClient: GetIt.I<ApiClient>())..add(LoadKdsInitialData()),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildProfessionalAppBar(context),
        body: BlocBuilder<KdsBloc, KdsState>(
          builder: (context, state) {
            if (state is KdsLoading) return Center(child: CircularProgressIndicator(color: cyan));
            if (state is KdsLoaded) {
              if (state.tickets.isEmpty) return _buildEmptyState(state.isBarman);
              // --- Purana Code (Line 31-41) ---
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.tickets.length,
                itemBuilder: (context, index) {
                  // 🔴 PEHLE YE THA:
                  // return _buildTicket(state.tickets[index], state, context);

                  // ✅ AB YE LAGAIE (Line 34 approx):
                  final group = state.tickets[index];
                  final bool isCooking = group['status'] == 'cooking';
                  final String assignedId = group['assigned_chef_id']?.toString() ?? "";

                  // 🎯 HIDE LOGIC: Agar koi aur paka raha hai toh screen se hata do
                  if (isCooking && assignedId.isNotEmpty && assignedId != state.currentUserId) {
                    return const SizedBox.shrink();
                  }

                  return _buildTicket(group, state, context);
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  // --- 📱 APPBAR (FIXED) ---
  PreferredSizeWidget _buildProfessionalAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 4,
      shadowColor: cyan.withValues(alpha: 0.2),
      title: BlocBuilder<KdsBloc, KdsState>(
        builder: (context, state) {
          if (state is KdsLoaded) {
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: state.isBarman ? Colors.deepPurple : Colors.redAccent, borderRadius: BorderRadius.circular(6)),
                  child: Icon(state.isBarman ? Icons.local_bar : Icons.restaurant, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.username.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16,color: Colors.white)),
                    Text("${state.userRole.toUpperCase()} • ONLINE", style: TextStyle(color: cyan, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            );
          }
          return const Text("KDS LIVE");
        },
      ),
      actions: [
        Builder(builder: (c) => IconButton(icon: Icon(Icons.refresh, color: cyan), onPressed: () => c.read<KdsBloc>().add(RefreshTasks()))),
        IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: () async {
          await const FlutterSecureStorage().deleteAll();
          context.go(AppRoutes.login);
        }),
      ],
    );
  }

  // --- 🎟️ TICKET (NO BORDER LINES) ---
  Widget _buildTicket(dynamic group, KdsLoaded state, BuildContext context) {
    final bool isCooking = group['status'] == 'cooking';
    final String assignedId = group['assigned_chef_id']?.toString() ?? "";
    final bool isLocked = isCooking && assignedId.isNotEmpty && assignedId != state.currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCooking ? orange : Colors.white10, width: 2),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent), // 👈 Lines removed
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _buildBadge(group['total_qty'], isCooking),
          title: Text(group['name'].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(isCooking ? "🔥 PREPARING" : "PENDING", style: TextStyle(color: isCooking ? orange : Colors.white24, fontSize: 10)),
          children: [
            Container(height: 1, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 16)),
            ... (group['order_details'] as List).map((d) => _buildOrderRow(d)),
            _buildActionButton(group, isCooking, context),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRow(dynamic d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("TABLE ${d['table']} | ${d['invoice']}", style: TextStyle(color: cyan, fontWeight: FontWeight.bold, fontSize: 13)),
                Text("ORDER #${d['order_id']} | ${d['guest']}", style: const TextStyle(color: Colors.white38, fontSize: 11),), // 👈 Fixed
              ],
            ),
          ),
          _buildRowTimer(d['created_at'].toString()),
          const SizedBox(width: 12),
          Text("x${d['qty']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),),
        ],
      ),
    );
  }

  Widget _buildRowTimer(String time) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)).asBroadcastStream(),
      builder: (context, _) {
        try {
          final startTime = DateTime.parse(time);
          final diff = DateTime.now().difference(startTime);

          // Formatting HH:MM:SS
          String twoDigits(int n) => n.toString().padLeft(2, "0");
          final hours = twoDigits(diff.inHours);
          final minutes = twoDigits(diff.inMinutes.remainder(60));
          final seconds = twoDigits(diff.inSeconds.remainder(60));

          // 🎯 COLOR LOGIC: 20 min se zyada toh Red, warna Green
          final bool isLate = diff.inMinutes >= 20;
          final Color timerColor = isLate ? Colors.redAccent : Colors.greenAccent;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              // Background bhi thoda change hoga late hone par
              color: timerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: timerColor.withOpacity(0.3), width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chota dot indicator
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: timerColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  "$hours:$minutes:$seconds",
                  style: TextStyle(
                    color: timerColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          );
        } catch (e) {
          return const Text("00:00:00", style: TextStyle(color: Colors.white24, fontSize: 11));
        }
      },
    );
  }

  Widget _buildActionButton(dynamic group, bool isCooking, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: isCooking ? Colors.green : orange, minimumSize: const Size(double.infinity, 54)),
        onPressed: () {
          List<int> ids = (group['order_details'] as List).map((e) => int.parse(e['item_id'].toString())).toList();
          context.read<KdsBloc>().add(UpdateItemStatus(ids, isCooking ? 'ready' : 'cooking'));
        },
        child: Text(isCooking ? "COMPLETE" : "START COOKING", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBadge(dynamic qty, bool active) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(color: active ? orange : Colors.white60, borderRadius: BorderRadius.circular(8)),
    child: Center(child: Text(qty.toString(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold,fontSize: 18))),
  );

  Widget _buildEmptyState(bool isBar) => Center(child: Text(isBar ? "NO DRINKS" : "KITCHEN CLEAR", style: const TextStyle(color: Colors.white24),),);
}