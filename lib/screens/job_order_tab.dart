import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/job_order.dart';
import '../providers/auth_provider.dart';
import '../providers/job_order_provider.dart';
import '../widgets/responsive_layout.dart';
import '../services/api_service.dart';

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
                  'Pekerjaan Permak Tidak Ditemukan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Semua pekerjaan permak akan muncul di sini secara kronologis.',
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
          String statusText;
          switch (job.status) {
            case 'completed':
              badgeColor = Colors.green;
              statusText = 'SELESAI';
              break;
            case 'in_progress':
              badgeColor = Colors.blue;
              statusText = 'SEDANG DIKERJAKAN';
              break;
            default:
              badgeColor = Colors.amber;
              statusText = 'TERTUNDA';
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
                      job.customerName ?? 'Pelanggan Walk-In',
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
                      statusText,
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
                      'Faktur: ${job.rentalInvoice ?? "-"}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.items.map((e) => e.name ?? '').join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tenggat: ${DateFormat('d MMM y • HH:mm', 'id').format(job.dueDate)}',
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
                          title: const Text('Detail Permak'),
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
                    DateFormat('EEEE, d MMMM y', 'id').format(job.dueDate),
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
                              'Detail Pekerjaan Permak',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pilih perintah pekerjaan dari daftar di sebelah kiri untuk meninjau instruksi permak, mencatat tenaga kerja karyawan, dan melacak status fitting.',
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
          content: Text('Akses Ditolak: Hanya Pemilik yang dapat memperbarui tenggat waktu.'),
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
          content: Text('Detail pekerjaan berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal memperbarui pekerjaan'),
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
        const SnackBar(content: Text('Daftar karyawan tidak tersedia. Mengambil...')),
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
              title: const Text('Catat Pekerjaan Penjahit / Karyawan'),
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
                        labelText: 'Pilih Penjahit / Karyawan',
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
                              labelText: 'Hari Kerja',
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
                              labelText: 'Jam Kerja',
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
                      'Tag Keahlian Khusus',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    ...{
                      'borci': 'Borci (Payet/Mote)',
                      'embroidery': 'Bordir Kompleks',
                      'fitting': 'Penyesuaian Fitting',
                      'alteration': 'Permak Standar',
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
                        labelText: 'Catatan Pekerjaan / Komentar',
                        hintText: 'misal: Memendekkan keliman rok sebanyak 5cm',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedWorkerId == null) return;
                    if (days == 0 && hours == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hari atau jam kerja yang dicatat harus lebih besar dari nol!')),
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
                          ? 'Pekerjaan permak' 
                          : descriptionController.text.trim(),
                    );

                    if (success) {
                      navigator.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Catatan pekerjaan ditambahkan!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.error ?? 'Gagal mencatat pekerjaan'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[900],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kirim Catatan'),
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
          title: const Text('Hapus Catatan Pekerjaan?'),
          content: const Text('Tindakan ini akan menghapus jam kerja yang dicatat dan menghitung ulang total man-days audit. Lanjutkan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
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
            content: Text('Catatan pekerjaan berhasil dihapus!'),
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
      return const Center(child: Text('Memuat detail...'));
    }

    final primaryColor = Colors.purple[900]!;
    final isMobile = ResponsiveLayout.isMobile(context);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Faktur: ${job.rentalInvoice ?? "-"}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pelanggan: ${job.customerName ?? "Pelanggan Walk-In"}',
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (job.items.isNotEmpty) ...[
                      const Divider(height: 24, thickness: 1),
                      Text(
                        'Daftar Pakaian (Items):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
                      ),
                      const SizedBox(height: 8),
                      ...job.items.map((item) {
                        final imageUrl = ApiService().getMediaUrl(item.imageUrl);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[100],
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.checkroom, color: Colors.grey, size: 24),
                                        )
                                      : const Icon(Icons.checkroom, color: Colors.grey, size: 24),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name ?? '',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'SKU: ${item.sku} • Ukuran: ${item.size} • Warna: ${item.color}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                    ),
                                    Text(
                                      'Jenis: ${item.type == "top" ? "Atasan" : "Bawahan"}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
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
                      'Kontrol Teknis & Tenggat Waktu',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor),
                    ),
                    const SizedBox(height: 16),
                    if (isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: InputDecoration(
                              labelText: 'Status Permak',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'pending', child: Text('Tertunda')),
                              DropdownMenuItem(value: 'in_progress', child: Text('Sedang Dikerjakan')),
                              DropdownMenuItem(value: 'completed', child: Text('Selesai')),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _status = val;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          InkWell(
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
                                    'Tenggat Waktu (Hanya Pemilik)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: widget.isOwner ? Colors.purple[800] : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _dueDate == null
                                        ? 'Atur Target Tenggat Waktu'
                                        : DateFormat('d MMM y • HH:mm', 'id').format(_dueDate!),
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
                        ],
                      )
                    else
                      Row(
                        children: [
                          // Status picker
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _status,
                              decoration: InputDecoration(
                                labelText: 'Status Permak',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'pending', child: Text('Tertunda')),
                                DropdownMenuItem(value: 'in_progress', child: Text('Sedang Dikerjakan')),
                                DropdownMenuItem(value: 'completed', child: Text('Selesai')),
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
                                      'Tenggat Waktu (Hanya Pemilik)',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: widget.isOwner ? Colors.purple[800] : Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _dueDate == null
                                          ? 'Atur Target Tenggat Waktu'
                                          : DateFormat('d MMM y • HH:mm', 'id').format(_dueDate!),
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
                        labelText: 'Catatan Teknis Permak',
                        hintText: 'Masukkan spesifikasi, perubahan panjang, ukuran...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Detail Permak'),
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
                    if (isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Audit Pekerjaan Penjahit / Karyawan',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total Master: ${job.totalManDays.toStringAsFixed(3)} Man-Days',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _showAddLaborDialog,
                            icon: const Icon(Icons.add_task),
                            label: const Text('Catat Pekerjaan', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Audit Pekerjaan Penjahit / Karyawan',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total Master: ${job.totalManDays.toStringAsFixed(3)} Man-Days',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddLaborDialog,
                            icon: const Icon(Icons.add_task),
                            label: const Text('Catat Pekerjaan', style: TextStyle(fontSize: 12)),
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
                                'Belum ada jam kerja yang dicatat.',
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
                                              log.workerName ?? 'Karyawan #${log.workerId}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            Text(
                                              '${log.manDays.toStringAsFixed(3)} MD (${log.days}h ${log.hours}j)',
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
