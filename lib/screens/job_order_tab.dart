import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/job_order.dart';
import '../providers/auth_provider.dart';
import '../providers/job_order_provider.dart';
import '../widgets/responsive_layout.dart';

class JobOrderTab extends StatefulWidget {
  const JobOrderTab({Key? key}) : super(key: key);

  @override
  State<JobOrderTab> createState() => _JobOrderTabState();
}

class _JobOrderTabState extends State<JobOrderTab> {
  JobOrder? _selectedJob; // Side-by-side mode only

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JobOrderProvider>(context, listen: false).fetchJobOrders();
      Provider.of<JobOrderProvider>(context, listen: false).fetchWorkers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<JobOrderProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    // Group and sort jobs chronologically
    final jobsList = List<JobOrder>.from(provider.jobs);
    jobsList.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Left pane - list of job orders grouped chronologically
    Widget buildJobListPanel() {
      if (provider.isLoading && provider.jobs.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (jobsList.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.checklist_rtl_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'No Job Orders Found',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'All alteration jobs will appear here chronologically.',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        );
      }

      DateTime? lastDate;

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: jobsList.length,
        itemBuilder: (context, index) {
          final job = jobsList[index];
          final showHeader = lastDate == null ||
              lastDate!.year != job.dueDate.year ||
              lastDate!.month != job.dueDate.month ||
              lastDate!.day != job.dueDate.day;
          
          lastDate = job.dueDate;

          Color badgeColor;
          switch (job.status) {
            case 'completed':
              badgeColor = Colors.green;
              break;
            case 'in_progress':
              badgeColor = Colors.blue;
              break;
            default:
              badgeColor = Colors.amber;
          }

          final cardWidget = Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: _selectedJob?.id == job.id ? 2 : 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _selectedJob?.id == job.id ? Colors.purple[900]! : Colors.grey[200]!,
                width: _selectedJob?.id == job.id ? 1.5 : 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      job.customerName ?? 'Walk-In Customer',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      job.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${job.itemName} (${job.itemSku})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Deadline: ${DateFormat('d MMM y • HH:mm').format(job.dueDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${job.totalManDays.toStringAsFixed(2)} MD',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              onTap: () {
                if (isMobile) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: const Text('Alteration Details'),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 0.5,
                        ),
                        body: JobOrderDetailsPane(
                          jobId: job.id,
                          isOwner: auth.user?.isOwner ?? false,
                        ),
                      ),
                    ),
                  ).then((_) {
                    provider.fetchJobOrders();
                  });
                } else {
                  setState(() {
                    _selectedJob = job;
                  });
                }
              },
            ),
          );

          if (showHeader) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 16.0, bottom: 8.0),
                  child: Text(
                    DateFormat('EEEE, MMMM d, y').format(job.dueDate),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                cardWidget,
              ],
            );
          }

          return cardWidget;
        },
      );
    }

    if (isMobile) {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: provider.fetchJobOrders,
          child: buildJobListPanel(),
        ),
      );
    } else {
      // Split layout for Tablet/Desktop
      final currentSelectedJob = _selectedJob != null
          ? jobsList.firstWhere((j) => j.id == _selectedJob!.id, orElse: () => _selectedJob!)
          : null;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: RefreshIndicator(
                onRefresh: provider.fetchJobOrders,
                child: buildJobListPanel(),
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            flex: 6,
            child: currentSelectedJob != null
                ? JobOrderDetailsPane(
                    key: ValueKey(currentSelectedJob.id),
                    jobId: currentSelectedJob.id,
                    isOwner: auth.user?.isOwner ?? false,
                  )
                : Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.construction,
                              size: 72,
                              color: Colors.purple[100],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Alteration Job Details',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select a job order from the list on the left to review alteration instructions, log employee labor, and track fitting status.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      );
    }
  }
}

// Inner pane widget for job details and labor logging
class JobOrderDetailsPane extends StatefulWidget {
  final int jobId;
  final bool isOwner;

  const JobOrderDetailsPane({
    Key? key,
    required this.jobId,
    required this.isOwner,
  }) : super(key: key);

  @override
  State<JobOrderDetailsPane> createState() => _JobOrderDetailsPaneState();
}

class _JobOrderDetailsPaneState extends State<JobOrderDetailsPane> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  
  String? _status;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _initData();
  }

  void _initData() {
    final job = _getJob();
    if (job != null) {
      _notesController.text = job.instructions ?? '';
      _status = job.status;
      _dueDate = job.dueDate;
    }
  }

  JobOrder? _getJob() {
    try {
      return Provider.of<JobOrderProvider>(context, listen: false)
          .jobs
          .firstWhere((j) => j.id == widget.jobId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    if (!widget.isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only Caroline Lauda (Owner) can update deadlines.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.purple[900]!,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: _dueDate != null
            ? TimeOfDay.fromDateTime(_dueDate!)
            : const TimeOfDay(hour: 10, minute: 0),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.purple[900]!,
                onPrimary: Colors.white,
                onSurface: Colors.black87,
              ),
            ),
            child: child!,
          );
        },
      );

      final finalDateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        timePicked?.hour ?? 10,
        timePicked?.minute ?? 0,
      );

      setState(() {
        _dueDate = finalDateTime;
      });
    }
  }

  void _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = Provider.of<JobOrderProvider>(context, listen: false);

    final success = await provider.updateJob(
      widget.jobId,
      status: _status!,
      instructions: _notesController.text.trim(),
      dueDate: _dueDate,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job details updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to update job'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showAddLaborDialog() {
    final provider = Provider.of<JobOrderProvider>(context, listen: false);
    final workers = provider.workers;

    if (workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No workers list available. Fetching...')),
      );
      provider.fetchWorkers();
      return;
    }

    int? selectedWorkerId = workers.first['id'] as int?;
    int days = 0;
    int hours = 0;
    final List<String> selectedCrafts = [];
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Log Tailor / Worker Labor'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Worker select
                    DropdownButtonFormField<int>(
                      value: selectedWorkerId,
                      decoration: InputDecoration(
                        labelText: 'Select Tailor / Employee',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: workers.map((w) {
                        return DropdownMenuItem<int>(
                          value: w['id'] as int,
                          child: Text(w['name'] as String),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedWorkerId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Time inputs
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: '0',
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Days Worked',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (val) {
                              days = int.tryParse(val) ?? 0;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: '0',
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Hours Worked',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (val) {
                              hours = int.tryParse(val) ?? 0;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total: ${(days + hours / 8.0).toStringAsFixed(3)} Man-Days',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Specialties
                    const Text(
                      'Specialty Tagging',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    ...{
                      'borci': 'Borci (Beading/Sequins)',
                      'embroidery': 'Complex Embroidery',
                      'fitting': 'Fitting Adjustments',
                      'alteration': 'Standard Alteration',
                    }.entries.map((entry) {
                      return CheckboxListTile(
                        title: Text(entry.value, style: const TextStyle(fontSize: 13)),
                        value: selectedCrafts.contains(entry.key),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              selectedCrafts.add(entry.key);
                            } else {
                              selectedCrafts.remove(entry.key);
                            }
                          });
                        },
                      );
                    }).toList(),

                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Labor Notes / Comments',
                        hintText: 'e.g., Shortened skirt hem by 5cm',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedWorkerId == null) return;
                    if (days == 0 && hours == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Log days or hours must be greater than zero!')),
                      );
                      return;
                    }

                    final navigator = Navigator.of(context);
                    final success = await provider.logLabor(
                      widget.jobId,
                      workerId: selectedWorkerId!,
                      days: days,
                      hours: hours,
                      crafts: selectedCrafts,
                      description: descriptionController.text.trim().isEmpty 
                          ? 'Alteration works' 
                          : descriptionController.text.trim(),
                    );

                    if (success) {
                      navigator.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Labor log added!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.error ?? 'Failed to log labor'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[900],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Submit Log'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteLaborLog(int laborLogId) async {
    final showConfirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Labor Log?'),
          content: const Text('This will remove the logged hours and recalculate total audit man-days. Proceed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (showConfirm == true && mounted) {
      final provider = Provider.of<JobOrderProvider>(context, listen: false);
      final success = await provider.removeLaborLog(widget.jobId, laborLogId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Labor log deleted successfully!'),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _getJob();
    if (job == null) {
      return const Center(child: Text('Loading details...'));
    }

    final primaryColor = Colors.purple[900]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gown info banner
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.purple[100]!),
              ),
              color: Colors.purple[50]!.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.checkroom, color: primaryColor, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.itemName ?? 'Custom Kebaya',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SKU: ${job.itemSku} • Size: ${job.itemSize} • Color: ${job.itemColor}',
                            style: TextStyle(color: Colors.grey[700], fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Invoice: [${job.rentalInvoice}] • Customer: ${job.customerName}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Target target deadline & status forms
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Technical & Deadline Controls',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Status picker
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            decoration: InputDecoration(
                              labelText: 'Alteration Status',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'pending', child: Text('Pending')),
                              DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                              DropdownMenuItem(value: 'completed', child: Text('Completed')),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _status = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Due date select
                        Expanded(
                          child: InkWell(
                            onTap: widget.isOwner ? _selectDueDate : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: widget.isOwner ? Colors.purple[800]! : Colors.grey[400]!,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: widget.isOwner ? null : Colors.grey[100],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Due Date (Owner Only)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: widget.isOwner ? Colors.purple[800] : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dueDate == null
                                        ? 'Set Target Due Date'
                                        : DateFormat('d MMM y • HH:mm').format(_dueDate!),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: widget.isOwner ? Colors.black87 : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Technical Alteration Notes ("Permak")',
                        hintText: 'Enter specifications, length changes, sizes...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Alteration Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Labor logs tracking
            Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tailor / Worker Labor Auditing',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Master Total: ${job.totalManDays.toStringAsFixed(3)} Man-Days',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddLaborDialog,
                          icon: const Icon(Icons.add_task),
                          label: const Text('Log Labor', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (job.laborLogs.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Column(
                            children: [
                              Icon(Icons.more_time, size: 36, color: Colors.grey[300]),
                              const SizedBox(height: 8),
                              Text(
                                'No labor hours logged yet.',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: job.laborLogs.length,
                        itemBuilder: (context, index) {
                          final log = job.laborLogs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            color: Colors.grey[50],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              log.workerName ?? 'Employee #${log.workerId}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            Text(
                                              '${log.manDays.toStringAsFixed(3)} MD (${log.days}d ${log.hours}h)',
                                              style: TextStyle(
                                                color: primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          log.description,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: log.crafts.map((craft) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blueGrey[50],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                craft.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blueGrey[800],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                    onPressed: () => _deleteLaborLog(log.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
