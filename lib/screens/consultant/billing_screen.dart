import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/database_models.dart';
import '../../services/database_service.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({Key? key}) : super(key: key);

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Invoice> _allInvoices = [];
  List<Invoice> _filteredInvoices = [];
  List<Client> _clients = [];
  List<Project> _projects = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  late TabController _tabController;

  final List<String> _filters = ['All', 'Draft', 'Sent', 'Paid', 'Overdue'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadData();
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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load clients first
      final clients = await _databaseService.getClients();
      _clients = clients;

      // Load projects
      final projects = await _databaseService.getProjects();
      _projects = projects;

      // Load all invoices for all clients
      List<Invoice> allInvoices = [];
      for (var client in clients) {
        final invoices = await _databaseService.getClientInvoices(client.id!);
        allInvoices.addAll(invoices);
      }

      setState(() {
        _allInvoices = allInvoices;
        _filterInvoices();
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterInvoices() {
    if (_selectedFilter == 'All') {
      _filteredInvoices = _allInvoices;
    } else {
      _filteredInvoices = _allInvoices.where((invoice) {
        return invoice.status.toLowerCase() == _selectedFilter.toLowerCase();
      }).toList();
    }
  }

  // Get client name from client ID
  String _getClientName(int clientId) {
    final client = _clients.firstWhere(
      (client) => client.id == clientId,
      orElse: () => Client(name: 'Unknown', email: '', phone: '', company: ''),
    );
    return client.name;
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

  Future<void> _changeInvoiceStatus(Invoice invoice, String newStatus) async {
    try {
      final updatedInvoice = Invoice(
        id: invoice.id,
        clientId: invoice.clientId,
        projectId: invoice.projectId,
        invoiceNumber: invoice.invoiceNumber,
        issueDate: invoice.issueDate,
        dueDate: invoice.dueDate,
        status: newStatus,
        amount: invoice.amount,
        taxRate: invoice.taxRate,
        notes: invoice.notes,
      );

      await _databaseService.updateInvoice(updatedInvoice);
      _loadData();
      _showSnackBar('Invoice status updated successfully');
    } catch (e) {
      _showSnackBar('Error updating invoice status');
    }
  }

  Future<void> _deleteInvoice(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Are you sure you want to delete invoice #${invoice.invoiceNumber}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _databaseService.deleteInvoice(invoice.id!);
      _loadData();
      _showSnackBar('Invoice deleted successfully');
    }
  }

  Future<void> _createInvoicePdf(Invoice invoice) async {
    final pdf = pw.Document();
    final clientName = _getClientName(invoice.clientId);
    final projectTitle = _getProjectTitle(invoice.projectId);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    // Find client information
    final client = _clients.firstWhere(
      (client) => client.id == invoice.clientId,
      orElse: () => Client(name: 'Unknown', email: '', phone: '', company: ''),
    );

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
                        pw.Text(client.name),
                        pw.Text(client.company),
                        pw.Text(client.email),
                        pw.Text(client.phone),
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
        title: const Text('Billing Management'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditInvoiceDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInvoiceList() {
    if (_filteredInvoices.isEmpty) {
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _showAddEditInvoiceDialog();
              },
              child: const Text('Create Invoice'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _filteredInvoices.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final invoice = _filteredInvoices[index];
          return _buildInvoiceCard(invoice);
        },
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
    final clientName = _getClientName(invoice.clientId);
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
                        'Client',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        clientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  label: 'View',
                  icon: Icons.visibility,
                  color: Colors.blue,
                  onPressed: () => _createInvoicePdf(invoice),
                ),
                if (invoice.status.toLowerCase() != 'paid')
                  _buildActionButton(
                    label: 'Mark Paid',
                    icon: Icons.check_circle,
                    color: Colors.green,
                    onPressed: () => _changeInvoiceStatus(invoice, 'paid'),
                  ),
                if (invoice.status.toLowerCase() == 'draft')
                  _buildActionButton(
                    label: 'Send',
                    icon: Icons.send,
                    color: Colors.orange,
                    onPressed: () => _changeInvoiceStatus(invoice, 'sent'),
                  ),
                _buildActionButton(
                  label: 'Delete',
                  icon: Icons.delete,
                  color: Colors.red,
                  onPressed: () => _deleteInvoice(invoice),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Future<void> _showAddEditInvoiceDialog({Invoice? invoice}) async {
    final isEditing = invoice != null;
    
    // Controllers
    final invoiceNumberController = TextEditingController(
        text: invoice?.invoiceNumber ?? 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}');
    final amountController = TextEditingController(text: invoice?.amount.toString() ?? '');
    final taxRateController = TextEditingController(text: invoice?.taxRate.toString() ?? '0');
    final notesController = TextEditingController(text: invoice?.notes ?? '');

    // Selected values
    int? selectedClientId = invoice?.clientId;
    int? selectedProjectId = invoice?.projectId;
    DateTime issueDate = invoice?.issueDate ?? DateTime.now();
    DateTime dueDate = invoice?.dueDate ?? DateTime.now().add(const Duration(days: 30));
    String status = invoice?.status ?? 'draft';

    // Client and project lists
    List<DropdownMenuItem<int>> clientItems = _clients.map((client) {
      return DropdownMenuItem<int>(
        value: client.id,
        child: Text(client.name),
      );
    }).toList();

    // Initially empty project list
    List<DropdownMenuItem<int>> projectItems = [];
    
    // Function to update project list based on selected client
    void updateProjectList(int? clientId) {
      if (clientId != null) {
        projectItems = _projects
            .where((project) => project.clientId == clientId)
            .map((project) {
          return DropdownMenuItem<int>(
            value: project.id,
            child: Text(project.title),
          );
        }).toList();
      } else {
        projectItems = [];
      }
    }

    // Initialize project list if client is already selected
    if (selectedClientId != null) {
      updateProjectList(selectedClientId);
    }

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Invoice' : 'Create New Invoice'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: invoiceNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Number',
                          prefixIcon: Icon(Icons.receipt),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an invoice number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Client',
                          prefixIcon: Icon(Icons.person),
                        ),
                        value: selectedClientId,
                        items: clientItems,
                        onChanged: (value) {
                          setState(() {
                            selectedClientId = value;
                            selectedProjectId = null; // Reset project when client changes
                            updateProjectList(value);
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a client';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Project',
                          prefixIcon: Icon(Icons.work),
                        ),
                        value: selectedProjectId,
                        items: projectItems,
                        onChanged: (value) {
                          setState(() {
                            selectedProjectId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a project';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('Issue Date'),
                              subtitle: Text(DateFormat('MMM dd, yyyy').format(issueDate)),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: issueDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() {
                                    issueDate = date;
                                  });
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: const Text('Due Date'),
                              subtitle: Text(DateFormat('MMM dd, yyyy').format(dueDate)),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: dueDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() {
                                    dueDate = date;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: '\$',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: taxRateController,
                        decoration: const InputDecoration(
                          labelText: 'Tax Rate (%)',
                          prefixIcon: Icon(Icons.percent),
                          suffixText: '%',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a tax rate';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.flag),
                        ),
                        value: status,
                        items: const [
                          DropdownMenuItem(value: 'draft', child: Text('Draft')),
                          DropdownMenuItem(value: 'sent', child: Text('Sent')),
                          DropdownMenuItem(value: 'paid', child: Text('Paid')),
                          DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            status = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          prefixIcon: Icon(Icons.note),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate() &&
                        selectedClientId != null &&
                        selectedProjectId != null) {
                      final newInvoice = Invoice(
                        id: invoice?.id,
                        clientId: selectedClientId!,
                        projectId: selectedProjectId!,
                        invoiceNumber: invoiceNumberController.text.trim(),
                        issueDate: issueDate,
                        dueDate: dueDate,
                        status: status,
                        amount: double.parse(amountController.text.trim()),
                        taxRate: double.parse(taxRateController.text.trim()),
                        notes: notesController.text.trim(),
                      );

                      if (isEditing) {
                        await _databaseService.updateInvoice(newInvoice);
                      } else {
                        await _databaseService.insertInvoice(newInvoice);
                      }

                      Navigator.pop(context);
                      _loadData();
                      _showSnackBar(
                        isEditing ? 'Invoice updated successfully' : 'Invoice created successfully',
                      );
                    }
                  },
                  child: Text(isEditing ? 'Update' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}