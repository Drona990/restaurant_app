
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';

// --- 1. EVENTS ---
abstract class ReportEvent {}

class FetchAnalytics extends ReportEvent {
  final String filter;
  FetchAnalytics(this.filter); // Named parameter ki jagah positional for cleaner calls
}

// --- 2. STATES ---
abstract class ReportState {}

class ReportInitial extends ReportState {}
class ReportLoading extends ReportState {}
class ReportLoaded extends ReportState {
  final double totalRevenue;
  final double totalGst;
  final int totalInvoices;

  ReportLoaded({
    required this.totalRevenue,
    required this.totalGst,
    required this.totalInvoices,
  });
}
class ReportError extends ReportState {
  final String message;
  ReportError(this.message);
}

// --- 3. BLOC LOGIC ---
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ApiClient apiClient;

  ReportBloc(this.apiClient) : super(ReportInitial()) {
    on<FetchAnalytics>((event, emit) async {
      emit(ReportLoading());
      try {
        // Industry Standard: Filter logic mapping
        final String range = event.filter.contains("Today") ? "today" : "monthly";

        final response = await apiClient.get('/api/reports/analytics/?range=$range');

        if (response.statusCode == 200) {
          final data = response.data['data'];
          emit(ReportLoaded(
            totalRevenue: double.parse(data['total_revenue'].toString()),
            totalGst: double.parse(data['total_gst'].toString()),
            totalInvoices: int.parse(data['total_invoices'].toString()),
          ));
        } else {
          emit(ReportError("Server Error: ${response.statusCode}"));
        }
      } catch (e) {
        emit(ReportError("Connection Failed: $e"));
      }
    });
  }
}

// --- 4. REPORTS SCREEN ---
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReportBloc(sl<ApiClient>())..add(FetchAnalytics("Today's Report")),
      child: const ReportsView(),
    );
  }
}

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  static const Color cyanPrimary = Color(0xFF00BCD4);
  static const Color darkGrey = Color(0xFF1A1C24);
  static const Color surfaceGrey = Color(0xFFF8F9FA);

  String _selectedFilter = "Today's Report";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceGrey,
      body: BlocBuilder<ReportBloc, ReportState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                if (state is ReportLoading)
                  const Center(child: LinearProgressIndicator(color: cyanPrimary))
                else if (state is ReportLoaded)
                  _buildMainDashboard(state)
                else if (state is ReportError)
                    _buildErrorState(state.message)
                  else
                    const Center(child: Text("Initializing Business Intelligence...")),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Analytical Report", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: darkGrey)),
            Text("Real-time Business Intelligence",
                style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.1)),
          ],
        ),
        const Spacer(),
        _buildFilterDropdown(context),
        const SizedBox(width: 15),
        const CircleAvatar(backgroundColor: darkGrey, child: Icon(Icons.analytics, color: cyanPrimary, size: 20)),
      ],
    );
  }

  Widget _buildFilterDropdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: _selectedFilter,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down, color: cyanPrimary),
        items: ["Today's Report", "Monthly Report"].map((e) =>
            DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))
        ).toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() => _selectedFilter = v);
            context.read<ReportBloc>().add(FetchAnalytics(v));
          }
        },
      ),
    );
  }

  Widget _buildMainDashboard(ReportLoaded state) {
    return Column(
      children: [
        Row(
          children: [
            _statCard("INVOICES", state.totalInvoices.toString(), Icons.receipt_long, cyanPrimary),
            const SizedBox(width: 20),
            _statCard("NET REVENUE", "₹ ${state.totalRevenue.toStringAsFixed(2)}", Icons.account_balance_wallet, Colors.green),
            const SizedBox(width: 20),
            _statCard("TAX (GST)", "₹ ${state.totalGst.toStringAsFixed(2)}", Icons.gavel, Colors.orange),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildChartPlaceholder()),
            const SizedBox(width: 24),
            Expanded(flex: 1, child: _buildQuickActions()),
          ],
        )
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 18),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: darkGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder() {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Revenue Stream", style: TextStyle(fontWeight: FontWeight.bold)),
          Spacer(),
          Center(child: Icon(Icons.bar_chart_rounded, size: 100, color: surfaceGrey)),
          Center(child: Text("Live visualization synced with Django", style: TextStyle(color: Colors.grey))),
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        _actionButton("Print Daily Summary", Icons.print, darkGrey, () => _printDailySummary()),
        const SizedBox(height: 12),
        _actionButton("Export to Excel", Icons.file_download, cyanPrimary, () {}),
        const SizedBox(height: 12),
        _actionButton("Sync Server Data", Icons.sync, Colors.blueGrey, () {}),
      ],
    );
  }

  Widget _actionButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(msg, style: const TextStyle(color: Colors.red)),
          TextButton(onPressed: () => context.read<ReportBloc>().add(FetchAnalytics(_selectedFilter)), child: const Text("Retry")),
        ],
      ),
    );
  }

  Future<void> _printDailySummary() async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.notoSansBold();
    pdf.addPage(pw.Page(build: (context) => pw.Center(child: pw.Text("DAILY SALES REPORT SUMMARY", style: pw.TextStyle(font: font, fontSize: 20)))));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}