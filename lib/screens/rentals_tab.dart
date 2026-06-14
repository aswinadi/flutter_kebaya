import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/rental.dart';
import '../models/inventory_item.dart';
import '../providers/auth_provider.dart';
import '../providers/rental_provider.dart';
import '../providers/inventory_provider.dart';

class RentalsTab extends StatefulWidget {
  const RentalsTab({Key? key}) : super(key: key);

  @override
  State<RentalsTab> createState() => _RentalsTabState();
}

class _RentalsTabState extends State<RentalsTab> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RentalProvider>(context, listen: false).fetchRentals();
    });
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'booked':
        return Colors.blue[700]!;
      case 'picked_up':
        return Colors.orange[800]!;
      case 'returned':
        return Colors.green[700]!;
      case 'cancelled':
        return Colors.grey[600]!;
      case 'void':
        return Colors.red[700]!;
      default:
        return Colors.black54;
    }
  }

  // Translate status to Indonesian
  String _translateStatus(String status) {
    switch (status) {
      case 'booked':
        return 'Dipesan';
      case 'picked_up':
        return 'Diambil';
      case 'returned':
        return 'Dikembalikan';
      case 'cancelled':
        return 'Dibatalkan';
      case 'void':
        return 'Void';
      default:
        return status;
    }
  }

  // Show dialog to choose an item to add to the rental
  Future<InventoryItem?> _showSelectItemDialog() async {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    await inventoryProvider.fetchInventory();
    final items = inventoryProvider.items;
    String search = '';
    
    return showDialog<InventoryItem>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSubState) {
            final filtered = items.where((item) {
              final query = search.toLowerCase();
              return item.name.toLowerCase().contains(query) ||
                  item.sku.toLowerCase().contains(query) ||
                  (item.color ?? '').toLowerCase().contains(query);
            }).toList();

            return AlertDialog(
              title: const Text('Pilih Pakaian'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Cari Pakaian...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setSubState(() => search = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('Pakaian tidak ditemukan'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return ListTile(
                                  leading: item.imageUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(
                                            item.imageUrl!,
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.image),
                                          ),
                                        )
                                      : const Icon(Icons.image),
                                  title: Text(item.name),
                                  subtitle: Text('${item.sku} - ${item.size} / ${item.color}'),
                                  onTap: () => Navigator.of(context).pop(item),
                                );
                              },
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
              ],
            );
          },
        );
      },
    );
  }

  // Show dialog to edit transaction details
  void _showEditRentalDialog(Rental rental) {
    final nameCtrl = TextEditingController(text: rental.customerName);
    final phoneCtrl = TextEditingController(text: rental.customerPhone);
    final notesCtrl = TextEditingController(text: rental.notes);
    DateTime selectedDate = rental.eventDate;
    String selectedStatus = rental.status;
    List<RentalComponent> editedItems = List.from(rental.items);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Edit Transaksi Reservasi'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Tanggal Acara', border: OutlineInputBorder()),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd MMMM yyyy', 'id').format(selectedDate)),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'booked', child: Text('Dipesan (Booked)')),
                        DropdownMenuItem(value: 'picked_up', child: Text('Diambil (Picked Up)')),
                        DropdownMenuItem(value: 'returned', child: Text('Dikembalikan (Returned)')),
                        DropdownMenuItem(value: 'cancelled', child: Text('Dibatalkan (Cancelled)')),
                        DropdownMenuItem(value: 'void', child: Text('Void')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedStatus = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Catatan Internal', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pakaian Sewa (Items)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // List of items
                    ...List.generate(editedItems.length, (index) {
                      final item = editedItems[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: item.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  item.imageUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                ),
                              )
                            : const Icon(Icons.image),
                        title: Text(item.name ?? 'Unknown item', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: Text('${item.sku ?? ''} - ${item.size ?? ''} / ${item.color ?? ''}', style: const TextStyle(fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setModalState(() {
                              editedItems.removeAt(index);
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final selectedItem = await _showSelectItemDialog();
                        if (selectedItem != null) {
                          setModalState(() {
                            editedItems.add(
                              RentalComponent(
                                id: 0,
                                inventoryItemId: selectedItem.id,
                                name: selectedItem.name,
                                sku: selectedItem.sku,
                                type: selectedItem.type,
                                size: selectedItem.size,
                                color: selectedItem.color,
                                imageUrl: selectedItem.imageUrl,
                                rentalPrice: selectedItem.rentalRate,
                              ),
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah Pakaian'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[50],
                        foregroundColor: Colors.purple[900],
                        elevation: 0,
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
                    if (nameCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama pelanggan wajib diisi')),
                      );
                      return;
                    }
                    if (editedItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pemesanan harus memiliki minimal 1 pakaian')),
                      );
                      return;
                    }

                    final provider = Provider.of<RentalProvider>(context, listen: false);
                    final itemsParam = editedItems.map((item) => {
                      'inventory_item_id': item.inventoryItemId,
                      'rental_price': item.rentalPrice,
                    }).toList();

                    final success = await provider.updateRentalDetails(
                      rental.id,
                      customerName: nameCtrl.text,
                      customerPhone: phoneCtrl.text,
                      eventDate: selectedDate,
                      status: selectedStatus,
                      notes: notesCtrl.text,
                      items: itemsParam,
                    );

                    if (context.mounted) {
                      Navigator.of(context).pop();
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaksi berhasil diperbarui')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Gagal memperbarui: ${provider.error}')),
                        );
                      }
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show dialog to confirm voiding transaction
  void _confirmVoidRental(Rental rental) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Void Transaksi'),
          content: Text('Apakah Anda yakin ingin melakukan void untuk transaksi ${rental.invoiceNumber}?\n\nTransaksi ini akan dibatalkan, dan item pakaian di dalamnya akan tersedia kembali pada kalender.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final provider = Provider.of<RentalProvider>(context, listen: false);
                final success = await provider.updateRentalDetails(
                  rental.id,
                  status: 'void',
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaksi berhasil di-void')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal melakukan void: ${provider.error}')),
                    );
                  }
                }
              },
              child: const Text('Void', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rentalProvider = Provider.of<RentalProvider>(context);
    final isOwner = Provider.of<AuthProvider>(context).user?.isOwner == true;
    final primaryColor = Colors.purple[900]!;

    // Filtered rentals list
    final filteredRentals = rentalProvider.rentals.where((rental) {
      final matchesSearch = rental.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          rental.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _statusFilter == 'all' || rental.status == _statusFilter;
      
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Filter & Search Controls
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                // Search Input
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari berdasarkan nama atau invoice...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 12),
                
                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Semua'),
                      const SizedBox(width: 8),
                      _buildFilterChip('booked', 'Dipesan'),
                      const SizedBox(width: 8),
                      _buildFilterChip('picked_up', 'Diambil'),
                      const SizedBox(width: 8),
                      _buildFilterChip('returned', 'Kembali'),
                      const SizedBox(width: 8),
                      _buildFilterChip('cancelled', 'Batal'),
                      const SizedBox(width: 8),
                      _buildFilterChip('void', 'Void'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Rental List View
          Expanded(
            child: rentalProvider.isLoading && rentalProvider.rentals.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredRentals.isEmpty
                    ? const Center(child: Text('Tidak ada transaksi penyewaan.'))
                    : RefreshIndicator(
                        onRefresh: () => rentalProvider.fetchRentals(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredRentals.length,
                          itemBuilder: (context, index) {
                            final rental = filteredRentals[index];
                            final statusColor = _getStatusColor(rental.status);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: statusColor.withOpacity(0.1),
                                  child: Icon(Icons.receipt_long, color: statusColor),
                                ),
                                title: Text(
                                  rental.invoiceNumber,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rental.customerName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                    ),
                                    Text(
                                      DateFormat('dd MMM yyyy', 'id').format(rental.eventDate),
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: statusColor.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    _translateStatus(rental.status).toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        
                                        // Phone & Group Details
                                        if (rental.customerPhone != null && rental.customerPhone!.isNotEmpty)
                                          _buildDetailRow(Icons.phone, 'Telepon', rental.customerPhone!),
                                        if (rental.groupOrderName != null && rental.groupOrderName!.isNotEmpty)
                                          _buildDetailRow(Icons.tag_faces, 'Grup Order', rental.groupOrderName!),
                                        if (rental.notes != null && rental.notes!.isNotEmpty)
                                          _buildDetailRow(Icons.notes, 'Catatan', rental.notes!),
                                        
                                        // Total Price (Owner Only)
                                        if (isOwner && rental.totalAmount != null)
                                          _buildDetailRow(
                                            Icons.monetization_on_outlined, 
                                            'Total Amount', 
                                            NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)
                                                .format(rental.totalAmount),
                                            textStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                                          ),
                                        
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Daftar Pakaian (Items):',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(height: 6),
                                        
                                        // Items List
                                        ...rental.items.map((item) {
                                          return Card(
                                            color: Colors.grey[50],
                                            elevation: 0,
                                            margin: const EdgeInsets.only(bottom: 6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              side: BorderSide(color: Colors.grey[200]!),
                                            ),
                                            child: ListTile(
                                              leading: item.imageUrl != null
                                                  ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(4),
                                                      child: Image.network(
                                                        item.imageUrl!,
                                                        width: 40,
                                                        height: 40,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                                      ),
                                                    )
                                                  : const Icon(Icons.image),
                                              title: Text(item.name ?? 'Unknown item', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                              subtitle: Text('${item.sku ?? ''} - ${item.size ?? ''} / ${item.color ?? ''}', style: const TextStyle(fontSize: 11)),
                                            ),
                                          );
                                        }).toList(),
                                        
                                        const SizedBox(height: 16),
                                        
                                        // Action buttons (Edit & Void)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            // Edit Button
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.edit, size: 16),
                                              label: const Text('Edit'),
                                              onPressed: () => _showEditRentalDialog(rental),
                                            ),
                                            const SizedBox(width: 8),
                                            
                                            // Void Button (Only if not already voided or cancelled)
                                            if (rental.status != 'void' && rental.status != 'cancelled')
                                              ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red[700],
                                                  foregroundColor: Colors.white,
                                                ),
                                                icon: const Icon(Icons.cancel_presentation, size: 16),
                                                label: const Text('Void'),
                                                onPressed: () => _confirmVoidRental(rental),
                                              ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
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

  // Helper row widget
  Widget _buildDetailRow(IconData icon, String label, String value, {TextStyle? textStyle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black54)),
          Expanded(
            child: Text(
              value,
              style: textStyle ?? const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Filter chip builder
  Widget _buildFilterChip(String value, String label) {
    final isSelected = _statusFilter == value;
    final primaryColor = Colors.purple[900]!;
    
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 11)),
      selected: isSelected,
      selectedColor: primaryColor,
      backgroundColor: Colors.grey[200],
      onSelected: (selected) {
        if (selected) {
          setState(() => _statusFilter = value);
        }
      },
    );
  }
}
