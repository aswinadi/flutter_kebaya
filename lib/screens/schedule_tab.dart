import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/rental.dart';
import '../models/job_order.dart';
import '../providers/rental_provider.dart';
import '../providers/job_order_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/responsive_layout.dart';

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({Key? key}) : super(key: key);

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RentalProvider>(context, listen: false).fetchRentals();
      Provider.of<JobOrderProvider>(context, listen: false).fetchJobOrders();
    });
  }

  // Helper: Get list of rentals whose event_date matches a specific day
  List<Rental> _getRentalsForDay(DateTime day, List<Rental> rentals) {
    return rentals.where((rental) {
      if (rental.status == 'cancelled') return false;
      return rental.eventDate.year == day.year &&
          rental.eventDate.month == day.month &&
          rental.eventDate.day == day.day;
    }).toList();
  }

  // Helper: Calculate standard number of days between two DateTimes safely (DST-friendly)
  int _daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return (toDate.difference(fromDate).inHours / 24).round().abs();
  }

  // Helper: Get list of rentals whose block period covers a specific day
  List<Rental> _getBlockRentalsForDay(DateTime day, List<Rental> rentals, int lockDays) {
    return rentals.where((rental) {
      if (rental.status == 'cancelled') return false;
      final diff = _daysBetween(rental.eventDate, day);
      return diff > 0 && diff <= lockDays;
    }).toList();
  }

  // Helper: Assign a premium distinct color to each rental transaction based on its ID
  Color _getRentalColor(Rental rental) {
    final List<Color> colors = [
      Colors.teal[600]!, // Teal
      Colors.amber[800]!, // Amber
      Colors.pink[600]!, // Pink
      Colors.blue[600]!, // Blue
      Colors.orange[800]!, // Orange
      Colors.indigo[600]!, // Indigo
      Colors.green[600]!, // Green
      Colors.red[600]!, // Red
      Colors.cyan[700]!, // Cyan
      Colors.purple[400]!, // Light Purple
    ];
    return colors[rental.id % colors.length];
  }

  // Helper: Get all days in the currently focused month
  List<DateTime?> _getMonthDays(DateTime monthDate) {
    final year = monthDate.year;
    final month = monthDate.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final totalDays = DateTime(year, month + 1, 0).day;
    
    // Day of the week (1 = Monday, 7 = Sunday)
    int startWeekday = firstDayOfMonth.weekday;
    
    // We adjust startWeekday to be 0-indexed where 0 = Monday, 6 = Sunday
    int leadingBlanks = startWeekday - 1;

    final List<DateTime?> days = [];
    for (int i = 0; i < leadingBlanks; i++) {
      days.add(null);
    }

    for (int i = 1; i <= totalDays; i++) {
      days.add(DateTime(year, month, i));
    }

    // Pad at the end to make it a full week grid multiple of 7
    while (days.length % 7 != 0) {
      days.add(null);
    }

    return days;
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _showEditRentalModal(Rental rental) {
    final nameCtrl = TextEditingController(text: rental.customerName);
    final phoneCtrl = TextEditingController(text: rental.customerPhone ?? '');
    final notesCtrl = TextEditingController(text: rental.notes ?? '');
    String selectedStatus = rental.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Kelola Penyewaan: ${rental.invoiceNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Pelanggan', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Telepon Pelanggan', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Catatan Staf', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'booked', child: Text('Dipesan')),
                        DropdownMenuItem(value: 'picked_up', child: Text('Diambil (Picked Up)')),
                        DropdownMenuItem(value: 'returned', child: Text('Dikembalikan (Returned)')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Dibatalkan (Cancelled)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedStatus = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Perbarui Penyewaan'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () async {
                        final prov = Provider.of<RentalProvider>(context, listen: false);
                        final success = await prov.updateRentalDetails(
                          rental.id,
                          customerName: nameCtrl.text,
                          customerPhone: phoneCtrl.text,
                          notes: notesCtrl.text,
                          status: selectedStatus,
                        );
                        if (success && mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penyewaan berhasil diperbarui')));
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${prov.error}')));
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    if (Provider.of<AuthProvider>(context, listen: false).user?.isOwner == true)
                      TextButton.icon(
                        icon: const Icon(Icons.archive, color: Colors.red),
                        label: const Text('Setel sebagai Tidak Aktif', style: TextStyle(color: Colors.red)),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Nonaktifkan Penyewaan'),
                              content: const Text('Apakah Anda yakin ingin menonaktifkan penyewaan ini? Ini akan disembunyikan dari tampilan biasa.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Nonaktifkan', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true && mounted) {
                            final prov = Provider.of<RentalProvider>(context, listen: false);
                            final success = await prov.deactivateRental(rental.id);
                            if (success && mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penyewaan dinonaktifkan')));
                            }
                          }
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rentalProvider = Provider.of<RentalProvider>(context);
    final jobOrderProvider = Provider.of<JobOrderProvider>(context);
    final jobOrders = jobOrderProvider.jobs;
    final isMobile = ResponsiveLayout.isMobile(context);
    final primaryColor = Colors.purple[900]!;

    Widget buildCalendarGrid() {
      final days = _getMonthDays(_focusedMonth);
      final weekDays = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

      return Column(
        children: [
          // Month Header controller
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _prevMonth,
              ),
              Text(
                DateFormat('MMMM yyyy', 'id').format(_focusedMonth),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 16),
          // Weekdays row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: isMobile ? 6 : 12),
          // Month Grid list
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: isMobile ? 4 : 8,
              crossAxisSpacing: isMobile ? 4 : 8,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              if (day == null) return const SizedBox.shrink();

              final isSelected = _selectedDay != null &&
                  _selectedDay!.year == day.year &&
                  _selectedDay!.month == day.month &&
                  _selectedDay!.day == day.day;

              final isToday = DateTime.now().year == day.year &&
                  DateTime.now().month == day.month &&
                  DateTime.now().day == day.day;

              final dayRentals = _getRentalsForDay(day, rentalProvider.rentals);
              final blockRentals = _getBlockRentalsForDay(day, rentalProvider.rentals, rentalProvider.dateLockingPeriod);

              final List<Widget> cellIndicators = [];
              for (final rental in dayRentals) {
                cellIndicators.add(
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _getRentalColor(rental),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 0.5,
                      ),
                    ),
                  ),
                );
              }
              for (final rental in blockRentals) {
                cellIndicators.add(
                  Container(
                    width: 7,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: _getRentalColor(rental),
                      borderRadius: BorderRadius.circular(1.2),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 0.5,
                      ),
                    ),
                  ),
                );
              }

              final displayedIndicators = cellIndicators.take(4).toList();

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : (isToday ? Colors.purple[50] : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : (isToday ? Colors.purple[200]! : Colors.grey[200]!),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isToday ? primaryColor : Colors.black87),
                        ),
                      ),
                      if (displayedIndicators.isNotEmpty)
                        Positioned(
                          bottom: 4,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: displayedIndicators.map((widget) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1),
                                child: widget,
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    Widget buildRentalCard(Rental rental, bool isOwner, Color primaryColor, {required bool isBlockPeriod}) {
      final rentalColor = _getRentalColor(rental);
      final List<JobOrder> rentalJobs = jobOrders.where((job) => job.rentalId == rental.id).toList();

      return GestureDetector(
        onTap: () => _showEditRentalModal(rental),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  color: rentalColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                rental.customerName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isBlockPeriod)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'BLOKIR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: rental.status == 'picked_up'
                                      ? Colors.orange[50]
                                      : (rental.status == 'returned' ? Colors.green[50] : Colors.blue[50]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  rental.status == 'picked_up'
                                      ? 'DIAMBIL'
                                      : (rental.status == 'returned' ? 'DIKEMBALIKAN' : 'DIPESAN'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: rental.status == 'picked_up'
                                        ? Colors.orange[800]
                                        : (rental.status == 'returned' ? Colors.green[800] : Colors.blue[800]),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (isBlockPeriod) ...[
                          Text(
                            'Tanggal Acara: ${DateFormat('EEEE, d MMMM y • HH:mm', 'id').format(rental.eventDate)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: rentalColor, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                        ] else ...[
                          Text(
                            'Tanggal Pengambilan: ${DateFormat('EEEE, d MMMM y • HH:mm', 'id').format(rental.eventDate)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          'Faktur: ${rental.invoiceNumber}',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.grey[700]),
                        ),
                        if (rental.customerPhone != null)
                          Text(
                            'Telepon: ${rental.customerPhone}',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        if (rental.groupOrderName != null)
                          Text(
                            'Grup: ${rental.groupOrderName}',
                            style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey[800]),
                          ),
                        if (rental.notes != null && rental.notes!.isNotEmpty)
                          Text(
                            'Catatan: ${rental.notes}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                          ),
                        const Divider(height: 24),
                        const Text(
                          'Item yang Disewa:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        ...rental.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: item.type == 'top' ? Colors.orange[50] : Colors.blue[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item.type == 'top' ? Icons.checkroom : Icons.accessibility_new,
                                    size: 14,
                                    color: item.type == 'top' ? Colors.orange[800] : Colors.blue[800],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${item.name} (${item.sku} • Ukuran: ${item.size})',
                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isOwner && item.rentalPrice != null)
                                  Text(
                                    'Rp ${NumberFormat('#,###').format(item.rentalPrice)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                              ],
                            ),
                          );
                        }),
                        if (rentalJobs.isNotEmpty) ...[
                          const Divider(height: 24),
                          const Text(
                            'Perintah Pekerjaan Permak:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          ...rentalJobs.map((job) {
                            Color statusColor;
                            String statusText;
                            switch (job.status) {
                              case 'completed':
                                statusColor = Colors.green;
                                statusText = 'SELESAI';
                                break;
                              case 'in_progress':
                                statusColor = Colors.blue;
                                statusText = 'SEDANG DIKERJAKAN';
                                break;
                              default:
                                statusColor = Colors.amber[800]!;
                                statusText = 'TERTUNDA';
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.purple[50]!.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.purple[100]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${job.itemName} (${job.itemSku})',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            statusText,
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (job.instructions != null && job.instructions!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Instruksi: ${job.instructions}',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[800], fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Tenggat: ${DateFormat('d MMM y • HH:mm', 'id').format(job.dueDate)}',
                                            style: TextStyle(fontSize: 10, color: Colors.red[800], fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Tenaga: ${job.totalManDays.toStringAsFixed(2)} MD',
                                            style: TextStyle(fontSize: 10, color: Colors.purple[800], fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.end,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                        if (isOwner && rental.totalAmount != null) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Jumlah Total:',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Rp ${NumberFormat('#,###').format(rental.totalAmount)}',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    }

    Widget buildDetailsPanel() {
      if (_selectedDay == null) {
        return const Center(child: Text('Pilih hari untuk melihat reservasi'));
      }

      final dayRentals = _getRentalsForDay(_selectedDay!, rentalProvider.rentals);
      final blockRentals = _getBlockRentalsForDay(_selectedDay!, rentalProvider.rentals, rentalProvider.dateLockingPeriod);
      final isOwner = Provider.of<AuthProvider>(context, listen: false).user?.isOwner ?? false;

      final bool hasAnyData = dayRentals.isNotEmpty || blockRentals.isNotEmpty;

      final List<Widget> detailItems = [];

      if (dayRentals.isNotEmpty) {
        detailItems.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Icon(Icons.event, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Pemesanan Aktif (${dayRentals.length})',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
          ),
        );

        for (final rental in dayRentals) {
          detailItems.add(buildRentalCard(rental, isOwner, primaryColor, isBlockPeriod: false));
        }
      }

      if (blockRentals.isNotEmpty) {
        if (dayRentals.isNotEmpty) {
          detailItems.add(const SizedBox(height: 16));
        }
        detailItems.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Icon(Icons.block, size: 18, color: Colors.red[800]),
                const SizedBox(width: 8),
                Text(
                  'Periode Blokir / Penyangga (${blockRentals.length})',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red[800]),
                ),
              ],
            ),
          ),
        );

        for (final rental in blockRentals) {
          detailItems.add(buildRentalCard(rental, isOwner, primaryColor, isBlockPeriod: true));
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reservasi untuk ${DateFormat('EEEE, d MMMM y', 'id').format(_selectedDay!)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: !hasAnyData
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        const Text(
                          'Tidak ada reservasi atau periode blokir pada tanggal ini',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: detailItems,
                  ),
          ),
        ],
      );
    }

    if (isMobile) {
      return Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 4,
              child: Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: buildCalendarGrid(),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: buildDetailsPanel(),
              ),
            ),
          ],
        ),
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Calendar Panel
          Expanded(
            flex: 5,
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: buildCalendarGrid(),
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Right details panel
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: buildDetailsPanel(),
            ),
          ),
        ],
      );
    }
  }
}
