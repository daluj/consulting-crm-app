import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/database_models.dart';
import '../../services/database_service.dart';

class ClientBillingScreen extends StatefulWidget {
  const ClientBillingScreen({Key? key}) : super(key: key);

  @override
  State<ClientBillingScreen> createState() => _ClientBillingScreenState();
}

class _ClientBillingScreenState extends State<ClientBillingScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Invoice> _invoices = [];
  List<Project> _projects = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  late TabController _tabController;
  int _clientId = 1; // Default value, will be updated in initState

  final List<String> _filters = ['All', 'Pending', 'Paid', 'Overdue'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadClientId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedFilter = _filters[_tabController.index];
        _filterInvoices();
      });
    }
  }

  Future<void> _loadClientId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _clientId = prefs.getInt('client_id') ?? 1;
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load client's projects
      final projects = await _databaseService.getClientProjects(_clientId);
      _projects = projects;

      // Load client's invoices
      final invoices = await _databaseService.getClientInvoices(_clientId);

      setState(() {
        _invoices = invoices;
        _filterInvoices();
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      print('Error loading invoice data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterInvoices() {
    if (_selectedFilter == 'All') {
      // No filtering needed
      return;
    }
    
    setState(() {
      if (_selectedFilter == 'Pending') {
        _invoices = _invoices.where((invoice) => 
          invoice.status.toLowerCase() == 'draft' || 
          invoice.status.toLowerCase() == 'sent'
        ).toList();
      } else {
        _invoices = _invoices.where((invoice) => 
          invoice.status.toLowerCase() == _selectedFilter.toLowerCase()
        ).toList();
      }
    });
  }

  // Get project title from project ID
  String _getProjectTitle(int projectId) {
    final project = _projects.firstWhere(
      (project) => project.id == projectId,
      orElse: () => Project(
        clientId: 0,
        title: 'Unknown',
        description: '',
        startDate: DateTime.now(),
        status: '',
        budget: 0,
      ),
    );
    return project.title;
  }

  Future<void> _createInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();
    final projectTitle = _getProjectTitle(invoice.projectId);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('INVOICE', style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      pw.Text('Invoice #: ${invoice.invoiceNumber}'),
                      pw.Text('Date: ${DateFormat('MMM dd, yyyy').format(invoice.issueDate)}'),
                      pw.Text('Due Date: ${DateFormat('MMM dd, yyyy').format(invoice.dueDate)}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Consultant CRM', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      pw.Text('123 Business St.'),
                      pw.Text('Suite 101'),
                      pw.Text('Business City, ST 12345'),
                      pw.Text('Phone: (555) 555-5555'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text('Client #${invoice.clientId}')
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Project:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 5),
                        pw.Text(projectTitle),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Table(
                border: pw.TableBorder.all(width: 1, color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Consulting Services: $projectTitle'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(currencyFormat.format(invoice.amount)),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('Subtotal: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(currencyFormat.format(invoice.amount)),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('Tax (${invoice.taxRate}%): ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(currencyFormat.format(invoice.amount * invoice.taxRate / 100)),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Divider(),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('Total: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                        pw.Text(currencyFormat.format(invoice.totalAmount), style: pw.TextStyle(fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),
              if (invoice.notes.isNotEmpty) ...[  
                pw.Text('Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text(invoice.notes),
                pw.SizedBox(height: 20),
              ],
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('Thank you for your business!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: 'invoice_${invoice.invoiceNumber}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Invoices'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _filters.map((filter) => Tab(text: filter)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _filters.map((filter) {
                return _buildInvoiceList();
              }).toList(),
            ),
    );
  }

  Widget _buildInvoiceList() {
    if (_invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No $_selectedFilter invoices found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _invoices.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final invoice = _invoices[index];
          return _buildInvoiceCard(invoice);
        },
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final projectTitle = _getProjectTitle(invoice.projectId);
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    Color statusColor;
    IconData statusIcon;
    
    switch (invoice.status.toLowerCase()) {
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'overdue':
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
      case 'sent':
        statusColor = Colors.blue;
        statusIcon = Icons.send;
        break;
      case 'draft':
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.edit_document;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Invoice #${invoice.invoiceNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        invoice.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Project',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        projectTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Issue Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(DateFormat('MMM dd, yyyy').format(invoice.issueDate)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Due Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(invoice.dueDate),
                        style: TextStyle(
                          color: invoice.status.toLowerCase() == 'overdue' ? Colors.red : null,
                          fontWeight: invoice.status.toLowerCase() == 'overdue' ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amount:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  currencyFormat.format(invoice.totalAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  label: 'View Invoice',
                  icon: Icons.visibility,
                  color: Colors.blue,
                  onPressed: () => _createInvoicePdf(invoice),
                ),
                if (invoice.status.toLowerCase() == 'sent')
                  _buildActionButton(
                    label: 'Pay Now',
                    icon: Icons.payments,
                    color: Colors.green,
                    onPressed: () {
                      // In a real app, this would navigate to a payment gateway
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment functionality would be integrated with a payment gateway'),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: color,
        size: 18,
      ),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}