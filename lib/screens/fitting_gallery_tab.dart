import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/rental_provider.dart';
import '../models/rental.dart';
import '../services/api_service.dart';
import '../widgets/responsive_layout.dart';

class FittingGalleryTab extends StatefulWidget {
  const FittingGalleryTab({Key? key}) : super(key: key);

  @override
  State<FittingGalleryTab> createState() => _FittingGalleryTabState();
}

class _FittingGalleryTabState extends State<FittingGalleryTab> {
  String _selectedMonthKey = 'all'; // Format: 'MM-yyyy' atau 'all'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RentalProvider>(context, listen: false).fetchRentals();
    });
  }

  // Helper to format month key into Indonesian string
  String _formatMonthLabel(String monthKey) {
    if (monthKey == 'all') return 'Semua Bulan';
    try {
      final parts = monthKey.split('-');
      final month = int.parse(parts[0]);
      final year = int.parse(parts[1]);
      final date = DateTime(year, month, 1);
      return DateFormat('MMMM yyyy', 'id').format(date);
    } catch (_) {
      return monthKey;
    }
  }

  void _showLargerImageDialog(BuildContext context, Rental rental, String imageUrl) {
    final primaryColor = Colors.purple[900]!;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Full Image with Close button overlay
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[100],
                            height: 300,
                            child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Details Section
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.label_important, color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rental.groupOrderName != null && rental.groupOrderName!.isNotEmpty
                                    ? rental.groupOrderName!
                                    : 'Event: Pelanggan ${rental.customerName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.receipt, 'Nomor Transaksi', rental.invoiceNumber),
                        _buildDetailRow(Icons.calendar_today, 'Tanggal Transaksi', DateFormat('dd MMMM yyyy', 'id').format(rental.eventDate)),
                        _buildDetailRow(Icons.person, 'Nama Pelanggan', rental.customerName),
                        const SizedBox(height: 16),
                        Text(
                          'Pakaian Tersewa (Laku):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
                        ),
                        const SizedBox(height: 8),
                        ...rental.items.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border.all(color: Colors.grey[200]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.checkroom, color: Colors.purple[300], size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${item.name} (${item.sku})',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.size ?? '-',
                                    style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[700])),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rentalProvider = Provider.of<RentalProvider>(context);
    final primaryColor = Colors.purple[900]!;
    final isMobile = ResponsiveLayout.isMobile(context);

    // Filter rentals that have a fitting photo (clientPicUrl is not null/empty)
    final galleryRentals = rentalProvider.rentals.where((r) {
      return r.clientPicUrl != null && r.clientPicUrl!.isNotEmpty;
    }).toList();

    // Extract unique months from events
    final Map<String, int> monthCounts = {};
    for (var r in galleryRentals) {
      final key = DateFormat('MM-yyyy').format(r.eventDate);
      monthCounts[key] = (monthCounts[key] ?? 0) + 1;
    }

    // Sort month keys descending (newest first)
    final sortedMonthKeys = monthCounts.keys.toList()
      ..sort((a, b) {
        final aParts = a.split('-');
        final bParts = b.split('-');
        final aDate = DateTime(int.parse(aParts[1]), int.parse(aParts[0]));
        final bDate = DateTime(int.parse(bParts[1]), int.parse(bParts[0]));
        return bDate.compareTo(aDate); // Newest month first
      });

    // Filter rentals by selected month
    final filteredRentals = _selectedMonthKey == 'all'
        ? galleryRentals
        : galleryRentals.where((r) => DateFormat('MM-yyyy').format(r.eventDate) == _selectedMonthKey).toList();

    // Sort filtered rentals by eventDate descending
    filteredRentals.sort((a, b) => b.eventDate.compareTo(a.eventDate));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Month Selector horizontal list
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 'Semua' option
                  ChoiceChip(
                    label: Text(
                      'Semua Bulan (${galleryRentals.length})',
                      style: TextStyle(
                        color: _selectedMonthKey == 'all' ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    selected: _selectedMonthKey == 'all',
                    selectedColor: primaryColor,
                    backgroundColor: Colors.grey[100],
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedMonthKey = 'all');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  // List of active months
                  ...sortedMonthKeys.map((key) {
                    final label = _formatMonthLabel(key);
                    final count = monthCounts[key];
                    final isSelected = _selectedMonthKey == key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          '$label ($count)',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        backgroundColor: Colors.grey[100],
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedMonthKey = key);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Main gallery grid
          Expanded(
            child: rentalProvider.isLoading && rentalProvider.rentals.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredRentals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum Ada Foto Fitting',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Foto fitting diunggah saat melakukan checkout sewa.',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => rentalProvider.fetchRentals(),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 2 : 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.58, // Tall aspect ratio to fit photo + info below
                          ),
                          itemCount: filteredRentals.length,
                          itemBuilder: (context, index) {
                            final rental = filteredRentals[index];
                            final imageUrl = ApiService().getMediaUrl(rental.clientPicUrl);

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _showLargerImageDialog(context, rental, imageUrl),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Image thumbnail
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                            ),
                                          ),
                                          // Event date badge overlay on image top-right
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                DateFormat('d MMM', 'id').format(rental.eventDate),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Info footer below image
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Invoice No
                                          Text(
                                            rental.invoiceNumber,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          
                                          // Event Name / Customer Name
                                          Text(
                                            rental.groupOrderName != null && rental.groupOrderName!.isNotEmpty
                                                ? rental.groupOrderName!
                                                : rental.customerName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          
                                          // Rented Items preview text/badges
                                          Text(
                                            rental.items.map((item) => item.name ?? '').join(', '),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey[600],
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
                      ),
          ),
        ],
      ),
    );
  }
}
