import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/inventory_item.dart';
import '../models/rental.dart';
import '../providers/inventory_provider.dart';
import '../providers/rental_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/responsive_layout.dart';
import '../services/api_service.dart';

class MixMatchTab extends StatefulWidget {
  final Function(int)? onNavigate;
  const MixMatchTab({Key? key, this.onNavigate}) : super(key: key);

  @override
  State<MixMatchTab> createState() => _MixMatchTabState();
}

class _MixMatchTabState extends State<MixMatchTab> {
  InventoryItem? _selectedTop;
  InventoryItem? _selectedBottom;
  DateTime? _filterDate;
  DateTime _focusedMonth = DateTime.now();
  String _searchTop = '';
  String _searchBottom = '';

  // Mobile view toggle: false = show Mannequin & Calendar, true = show Selection List Sheets
  bool _showCalendarMobile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchInventory();
      Provider.of<RentalProvider>(context, listen: false).fetchRentals();
    });
  }

  // Calculate days between two dates safely (DST-friendly)
  int _daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return (toDate.difference(fromDate).inHours / 24).round().abs();
  }

  // Determine if a specific item is blocked on a given date (dead zone based on locking period)
  bool _isItemBlockedOnDate(int itemId, DateTime date, List<Rental> rentals, int lockDays) {
    for (final rental in rentals) {
      if (rental.status == 'cancelled' || rental.status == 'void') continue;
      final diff = _daysBetween(rental.eventDate, date);
      if (diff <= lockDays) {
        for (final item in rental.items) {
          if (item.inventoryItemId == itemId) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // Helper: Get list of days in a focused month
  List<DateTime?> _getMonthDays(DateTime monthDate) {
    final year = monthDate.year;
    final month = monthDate.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final totalDays = DateTime(year, month + 1, 0).day;
    int startWeekday = firstDayOfMonth.weekday;
    int leadingBlanks = startWeekday - 1;

    final List<DateTime?> days = [];
    for (int i = 0; i < leadingBlanks; i++) {
      days.add(null);
    }
    for (int i = 1; i <= totalDays; i++) {
      days.add(DateTime(year, month, i));
    }
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

  String _formatRupiah(double value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final rentalProvider = Provider.of<RentalProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    final isOwner = authProvider.user?.isOwner ?? false;
    final isMobile = ResponsiveLayout.isMobile(context);
    
    final primaryColor = Colors.purple[900]!;
    final accentColor = const Color(0xFFD4AF37);

    // Filter list of tops and bottoms
    final List<InventoryItem> allTops = inventoryProvider.items
        .where((item) => item.type == 'top')
        .where((item) {
          final query = _searchTop.toLowerCase();
          return item.name.toLowerCase().contains(query) ||
              item.sku.toLowerCase().contains(query) ||
              item.color.toLowerCase().contains(query);
        }).toList();

    final List<InventoryItem> allBottoms = inventoryProvider.items
        .where((item) => item.type == 'bottom')
        .where((item) {
          final query = _searchBottom.toLowerCase();
          return item.name.toLowerCase().contains(query) ||
              item.sku.toLowerCase().contains(query) ||
              item.color.toLowerCase().contains(query);
        }).toList();

    // Combined price helper
    double totalRate = 0.0;
    if (_selectedTop != null && _selectedTop!.rentalRate != null) {
      totalRate += _selectedTop!.rentalRate!;
    }
    if (_selectedBottom != null && _selectedBottom!.rentalRate != null) {
      totalRate += _selectedBottom!.rentalRate!;
    }

    // Build single item card
    Widget buildItemCard(InventoryItem item, bool isSelected, VoidCallback onTap) {
      final isBlocked = _filterDate != null &&
          _isItemBlockedOnDate(item.id, _filterDate!, rentalProvider.rentals, rentalProvider.dateLockingPeriod);
      
      final api = ApiService();

      return Card(
        elevation: isSelected ? 4 : 1,
        color: isSelected ? Colors.purple[50] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? primaryColor : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Opacity(
          opacity: isBlocked ? 0.6 : 1.0,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Image thumbnail
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.imagePath != null && item.imagePath!.isNotEmpty
                        ? Image.network(
                            api.getMediaUrl(item.imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.girl_outlined, color: Colors.grey),
                          )
                        : const Icon(Icons.girl_outlined, color: Colors.grey),
                  ),
                  const SizedBox(width: 10),
                  // Text details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.sku,
                                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Ukuran ${item.size} • ${item.color}',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (isOwner && item.rentalRate != null)
                              Text(
                                _formatRupiah(item.rentalRate!),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              )
                            else
                              const Text('Tarif Tersembunyi', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            
                            // Availability badge
                            if (_filterDate != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isBlocked ? Colors.red[50] : Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isBlocked ? 'Dipesan' : 'Tersedia',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isBlocked ? Colors.red[800] : Colors.green[800],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Build the visual mannequin preview card
    Widget buildMannequinCard({double imageHeight = 640}) {
      final api = ApiService();

      // SizedBox gives the Card a concrete bounded height.
      // The Column fills it (mainAxisSize.max), so Expanded children
      // split the remaining space after the header/footer — no overflow.
      return SizedBox(
        height: imageHeight,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 12 : 16)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.max,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  color: Colors.grey[50],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'PRATINJAU PAKAIAN',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_selectedTop != null || _selectedBottom != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTop = null;
                              _selectedBottom = null;
                            });
                          },
                          child: const Text(
                            'RESET',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.redAccent),
                          ),
                        ),
                    ],
                  ),
                ),
                // Tops Half — Expanded is safe here: Column has bounded height from SizedBox
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.purple[50]!.withOpacity(0.3),
                      border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
                    ),
                    child: _selectedTop != null && _selectedTop!.imagePath != null && _selectedTop!.imagePath!.isNotEmpty
                        ? Image.network(
                            api.getMediaUrl(_selectedTop!.imagePath),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.style_outlined, color: primaryColor.withOpacity(0.3), size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  'Pilih Atasan',
                                  style: TextStyle(fontSize: 11, color: primaryColor.withOpacity(0.5), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                // Bottoms Half — Expanded splits remaining space equally with Tops
                Expanded(
                  child: Container(
                    color: Colors.green[50]!.withOpacity(0.2),
                    child: _selectedBottom != null && _selectedBottom!.imagePath != null && _selectedBottom!.imagePath!.isNotEmpty
                        ? Image.network(
                            api.getMediaUrl(_selectedBottom!.imagePath),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.layers_outlined, color: Colors.green[800]!.withOpacity(0.2), size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  'Pilih Bawahan',
                                  style: TextStyle(fontSize: 11, color: Colors.green[800]!.withOpacity(0.4), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                // Rates and Info Footer — intrinsic height, doesn't cause overflow
                if (_selectedTop != null || _selectedBottom != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_selectedTop != null)
                                    Text(
                                      'Atasan: ${_selectedTop!.name}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (_selectedBottom != null)
                                    Text(
                                      'Bawahan: ${_selectedBottom!.name}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            if (isOwner)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatRupiah(totalRate),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final rentalProvider = Provider.of<RentalProvider>(context, listen: false);
                              int addedCount = 0;
                              if (_selectedTop != null) {
                                rentalProvider.addToCart(_selectedTop!);
                                addedCount++;
                              }
                              if (_selectedBottom != null) {
                                rentalProvider.addToCart(_selectedBottom!);
                                addedCount++;
                              }
                              if (addedCount > 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$addedCount item dimasukkan ke keranjang'),
                                    backgroundColor: Colors.green,
                                    action: SnackBarAction(
                                      label: 'LIHAT',
                                      textColor: Colors.white,
                                      onPressed: () {
                                        widget.onNavigate?.call(2); // Go to checkout tab
                                      },
                                    ),
                                  ),
                                );
                                setState(() {
                                  _selectedTop = null;
                                  _selectedBottom = null;
                                });
                              }
                            },
                            icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: const Text('Masukkan ke Keranjang', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }


    // Build the monthly calendar grid view
    Widget buildCalendarSection() {
      final days = _getMonthDays(_focusedMonth);
      final weekDays = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Calendar Month Navigation Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _prevMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy', 'id').format(_focusedMonth),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Weekdays headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weekDays.map((d) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              // Days Grid Builder
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final day = days[index];
                  if (day == null) return const SizedBox.shrink();
 
                  final isToday = DateTime.now().year == day.year &&
                      DateTime.now().month == day.month &&
                      DateTime.now().day == day.day;

                  final isFiltered = _filterDate != null &&
                      _filterDate!.year == day.year &&
                      _filterDate!.month == day.month &&
                      _filterDate!.day == day.day;

                  // Evaluate if selected top or bottom is blocked
                  final topBlocked = _selectedTop != null &&
                      _isItemBlockedOnDate(_selectedTop!.id, day, rentalProvider.rentals, rentalProvider.dateLockingPeriod);
                  final bottomBlocked = _selectedBottom != null &&
                      _isItemBlockedOnDate(_selectedBottom!.id, day, rentalProvider.rentals, rentalProvider.dateLockingPeriod);

                  final isBlocked = topBlocked || bottomBlocked;

                  // Decorate cell based on status
                  BoxDecoration? cellDeco;
                  Color textColor = Colors.black87;

                  if (isFiltered) {
                    cellDeco = BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    );
                    textColor = Colors.white;
                  } else if (isBlocked) {
                    cellDeco = BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1),
                    );
                    textColor = Colors.red[900]!;
                  } else if (isToday) {
                    cellDeco = BoxDecoration(
                      border: Border.all(color: primaryColor, width: 1.5),
                      shape: BoxShape.circle,
                    );
                  }

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isFiltered) {
                          _filterDate = null; // Clear filter on double click
                        } else {
                          _filterDate = day;
                        }
                      });
                    },
                    child: Container(
                      decoration: cellDeco,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            day.day.toString(),
                            style: TextStyle(
                              fontWeight: (isFiltered || isBlocked || isToday) ? FontWeight.bold : FontWeight.normal,
                              color: textColor,
                              fontSize: 12,
                            ),
                          ),
                          // Small dots indicators for top/bottom blocking specific view
                          if (!isFiltered && isBlocked)
                            Positioned(
                              bottom: 2,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (topBlocked)
                                    Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      decoration: const BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  if (bottomBlocked)
                                    Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              // Calendar Legend
              Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.orange[400], shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('Atasan', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('Bawahan', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('Filter', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // --- RENDER REGIONS ---

    // 1. Header Filter Row
    Widget buildFilterHeader() {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(
                  _filterDate == null
                      ? 'Filter Berdasarkan Tanggal'
                      : 'Tanggal: ${DateFormat('EEEE, d MMM y', 'id').format(_filterDate!)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  foregroundColor: _filterDate != null ? accentColor : primaryColor,
                  side: BorderSide(
                    color: _filterDate != null ? accentColor : Colors.grey[300]!,
                  ),
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _filterDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) {
                    setState(() {
                      _filterDate = picked;
                      _focusedMonth = picked;
                    });
                  }
                },
              ),
            ),
            if (_filterDate != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.redAccent),
                tooltip: 'Hapus Filter Tanggal',
                onPressed: () => setState(() => _filterDate = null),
              ),
            ],
          ],
        ),
      );
    }

    // 2. Tops Pane
    Widget buildTopsPane() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.orange[50]!.withOpacity(0.5),
            child: Row(
              children: [
                Icon(Icons.girl_outlined, color: Colors.orange[800]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ATASAN (TOPS)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchTop = val),
              decoration: InputDecoration(
                hintText: 'Cari nama/SKU/warna atasan...',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
            ),
          ),
          Expanded(
            child: allTops.isEmpty
                ? const Center(child: Text('Atasan tidak ditemukan', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: allTops.length,
                    itemBuilder: (context, index) {
                      final top = allTops[index];
                      return buildItemCard(
                        top,
                        _selectedTop?.id == top.id,
                        () => setState(() => _selectedTop = top),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    // 3. Bottoms Pane
    Widget buildBottomsPane() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.green[50]!.withOpacity(0.3),
            child: Row(
              children: [
                Icon(Icons.layers_outlined, color: Colors.green[800]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'BAWAHAN (BOTTOMS)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchBottom = val),
              decoration: InputDecoration(
                hintText: 'Cari nama/SKU/warna bawahan...',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
            ),
          ),
          Expanded(
            child: allBottoms.isEmpty
                ? const Center(child: Text('Bawahan tidak ditemukan', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: allBottoms.length,
                    itemBuilder: (context, index) {
                      final bottom = allBottoms[index];
                      return buildItemCard(
                        bottom,
                        _selectedBottom?.id == bottom.id,
                        () => setState(() => _selectedBottom = bottom),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    // 4. Desktop/Tablet 3-Pane View Layout
    Widget buildDesktopLayout() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Pane (30%): Tops & Bottoms Tabs
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      indicatorColor: primaryColor,
                      labelColor: primaryColor,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'Atasan'),
                        Tab(text: 'Bawahan'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          buildTopsPane(),
                          buildBottomsPane(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Center Pane (30%): Filter & Calendar
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildFilterHeader(),
                    const SizedBox(height: 16),
                    buildCalendarSection(),
                  ],
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Right Pane (40%): Massive Mannequin Preview
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) => buildMannequinCard(
                  imageHeight: constraints.maxHeight,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 5. Mobile View Layout — Side-by-side split pane
    Widget buildMobileLayout() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT PANE: Full-height Preview (45% width)
          Expanded(
            flex: 45,
            child: Container(
              color: Colors.grey[50],
              child: Column(
                children: [
                  // Mini header with calendar toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PRATINJAU',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 1.0,
                            color: primaryColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showCalendarMobile = !_showCalendarMobile),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showCalendarMobile ? Icons.photo_outlined : Icons.calendar_month_outlined,
                                  size: 12,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _showCalendarMobile ? 'Pratinjau' : 'Kalender',
                                  style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Preview or Calendar fills the remaining height
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: _showCalendarMobile
                          ? SingleChildScrollView(child: buildCalendarSection())
                          : LayoutBuilder(
                              builder: (context, constraints) => buildMannequinCard(
                                imageHeight: constraints.maxHeight,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // RIGHT PANE: Tops & Bottoms tabs (55% width)
          Expanded(
            flex: 55,
            child: Container(
              color: Colors.white,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      indicatorColor: primaryColor,
                      labelColor: primaryColor,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'Atasan'),
                        Tab(text: 'Bawahan'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          buildTopsPane(),
                          buildBottomsPane(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          if (isMobile) buildFilterHeader(),
          if (isMobile) const Divider(height: 1, thickness: 1),
          Expanded(
            child: isMobile ? buildMobileLayout() : buildDesktopLayout(),
          ),
        ],
      ),
      floatingActionButton: rentalProvider.cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => widget.onNavigate?.call(2),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_cart),
              label: Text('Keranjang (${rentalProvider.cart.length})'),
            )
          : null,
    );
  }
}
