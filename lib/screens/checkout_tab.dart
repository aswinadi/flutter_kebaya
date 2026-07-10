import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_provider.dart';
import '../providers/rental_provider.dart';
import '../widgets/responsive_layout.dart';
import '../services/api_service.dart';

class CheckoutTab extends StatefulWidget {
  const CheckoutTab({Key? key}) : super(key: key);

  @override
  State<CheckoutTab> createState() => _CheckoutTabState();
}

class _CartItem {
  final InventoryItem item;
  double customPrice;

  _CartItem({required this.item, required this.customPrice});
}

class _CheckoutTabState extends State<CheckoutTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _groupController = TextEditingController();
  
  DateTime? _selectedDate;
  final List<File> _clientPicFiles = [];
  final List<File> _beforePhotos = [];
  
  final List<_CartItem> _cart = [];
  final ImagePicker _imagePicker = ImagePicker();
  String _catalogSearchQuery = '';
  List<int> _unavailableItemIds = [];
  bool _checkingAvailability = false;
  StateSetter? _modalSetState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchInventory();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailability(DateTime date) async {
    setState(() {
      _checkingAvailability = true;
    });
    try {
      final ids = await ApiService().getUnavailableItemIds(date);
      setState(() {
        _unavailableItemIds = ids;
      });
      if (_modalSetState != null) {
        _modalSetState!(() {});
      }

      // If any item already in the cart is now unavailable, show warning
      final conflictNames = _cart
          .where((cartItem) => ids.contains(cartItem.item.id))
          .map((cartItem) => cartItem.item.name)
          .toList();

      if (conflictNames.isNotEmpty && mounted) {
        final lockPeriod = Provider.of<RentalProvider>(context, listen: false).dateLockingPeriod;
        final blockDays = lockPeriod * 2;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Konflik Ketersediaan!'),
            content: Text(
              'Item berikut dalam keranjang Anda sudah dipesan (termasuk aturan pemblokiran $blockDays hari) pada tanggal ini:\n\n'
              '${conflictNames.map((n) => '• $n').join('\n')}\n\n'
              'Silakan hapus item tersebut atau pilih tanggal lain.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memeriksa ketersediaan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _checkingAvailability = false;
        });
        if (_modalSetState != null) {
          _modalSetState!(() {});
        }
      }
    }
  }

  void _addItemToCart(InventoryItem item) {
    if (_selectedDate != null && _unavailableItemIds.contains(item.id)) {
      final lockPeriod = Provider.of<RentalProvider>(context, listen: false).dateLockingPeriod;
      final blockDays = lockPeriod * 2;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item ini tidak tersedia pada tanggal yang dipilih! (Blokir $blockDays hari)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_cart.any((element) => element.item.id == item.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item sudah ada di keranjang!'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }
    setState(() {
      _cart.add(_CartItem(
        item: item,
        customPrice: item.rentalRate ?? 0.0,
      ));
    });
    if (_modalSetState != null) {
      _modalSetState!(() {});
    }
  }

  void _removeItemFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
    if (_modalSetState != null) {
      _modalSetState!(() {});
    }
  }

  Future<void> _pickImage(ImageSource source, bool isClientPic) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
          imageQuality: 70,
        );
        if (pickedFiles.isNotEmpty) {
          setState(() {
            if (isClientPic) {
              _clientPicFiles.addAll(pickedFiles.map((x) => File(x.path)));
            } else {
              _beforePhotos.addAll(pickedFiles.map((x) => File(x.path)));
            }
          });
        }
      } else {
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
        );
        if (pickedFile != null) {
          setState(() {
            if (isClientPic) {
              _clientPicFiles.add(File(pickedFile.path));
            } else {
              _beforePhotos.add(File(pickedFile.path));
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil gambar: $e')),
      );
    }
  }

  void _showImagePickerOptions(bool isClientPic) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Ambil Foto dengan Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, isClientPic);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, isClientPic);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 5)),
      firstDate: DateTime.now(),
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
        initialTime: _selectedDate != null
            ? TimeOfDay.fromDateTime(_selectedDate!)
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
        _selectedDate = finalDateTime;
      });
      _fetchAvailability(finalDateTime);
    }
  }

  double get _totalAmount {
    return _cart.fold(0.0, (sum, element) => sum + element.customPrice);
  }

  void _submitCheckout() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih tanggal acara!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    
    // Check conflicts again
    final unavailableInCart = _cart.where((cartItem) => _unavailableItemIds.contains(cartItem.item.id)).toList();
    if (unavailableInCart.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat checkout: ${unavailableInCart.first.item.name} tidak tersedia.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang belanja Anda kosong! Tambahkan setidaknya satu komponen gown.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final rentalProvider = Provider.of<RentalProvider>(context, listen: false);

    final success = await rentalProvider.checkout(
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      eventDate: _selectedDate!,
      status: 'booked',
      groupOrderName: _groupController.text.trim().isEmpty ? null : _groupController.text.trim(),
      items: _cart.map((cartItem) => {
        'inventory_item_id': cartItem.item.id,
        'rental_price': cartItem.customPrice,
      }).toList(),
      clientPicFiles: _clientPicFiles.isEmpty ? null : _clientPicFiles,
      beforePhotos: _beforePhotos.isEmpty ? null : _beforePhotos,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pemesanan Sewa Berhasil Dibuat!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _cart.clear();
        _nameController.clear();
        _phoneController.clear();
        _groupController.clear();
        _selectedDate = null;
        _clientPicFiles.clear();
        _beforePhotos.clear();
        _unavailableItemIds.clear();
      });
      if (_modalSetState != null) {
        _modalSetState!(() {});
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rentalProvider.error ?? 'Gagal melakukan checkout'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final primaryColor = Colors.purple[900]!;

    // Left Form Panel Widget
    Widget buildFormPanel() {
      return Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                        '1. Detail Pelanggan & Acara',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap Pelanggan',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Masukkan nama pelanggan'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Telepon Pelanggan (misal +628...)',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _groupController,
                        decoration: InputDecoration(
                          labelText: 'Nama Pemesanan Grup / Fitting (Opsional)',
                          hintText: 'misal: Grup Wisuda Petra',
                          prefixIcon: const Icon(Icons.group_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: primaryColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDate == null
                                      ? 'Pilih Tanggal & Waktu Acara'
                                      : 'Tanggal Acara: ${DateFormat('EEEE, d MMMM y • HH:mm', 'id').format(_selectedDate!)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
                                    color: _selectedDate == null ? Colors.grey[600] : Colors.black87,
                                  ),
                                ),
                              ),
                              if (_checkingAvailability)
                                const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                        '2. Foto Fitting Gown Klien',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showImagePickerOptions(true),
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Tambah Foto Fitting'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (_clientPicFiles.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _clientPicFiles.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _clientPicFiles[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _clientPicFiles.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                        '3. Foto Kondisi Gown (Audit Trail)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ambil foto kondisi kain yang ada atau masalah kecocokan sebelum penyewaan.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showImagePickerOptions(false),
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Tambah Foto Kondisi'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (_beforePhotos.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _beforePhotos.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _beforePhotos[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _beforePhotos.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Consumer<RentalProvider>(
                builder: (context, rentalProv, _) {
                  return ElevatedButton(
                    onPressed: rentalProv.isLoading ? null : _submitCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: rentalProv.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Selesaikan Pemesanan & Checkout (Rp ${NumberFormat('#,###').format(_totalAmount)})',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      );
    }

    // Right Cart/Inventory Picker Panel
    Widget buildCartPanel() {
      final invProvider = Provider.of<InventoryProvider>(context);
      final tokens = _catalogSearchQuery.toLowerCase().split(RegExp(r'\s+')).where((token) => token.isNotEmpty).toList();
      final searchResults = invProvider.items.where((item) {
        if (tokens.isEmpty) return true;
        return tokens.every((token) {
          final matchesName = item.name.toLowerCase().contains(token);
          final matchesSku = item.sku.toLowerCase().contains(token);
          final matchesColor = item.color.toLowerCase().contains(token);
          final matchesDesc = (item.description ?? '').toLowerCase().contains(token);
          final matchesSize = item.size.toLowerCase() == token;
          final matchesTag = item.tags.any((tag) => tag.toLowerCase().contains(token));
          return matchesName || matchesSku || matchesColor || matchesDesc || matchesSize || matchesTag;
        });
      }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cart list
          Expanded(
            flex: 5,
            child: Card(
              margin: const EdgeInsets.all(16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Item Padu Padan Terpilih',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_cart.length} Bagian Terpilih',
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: _cart.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Keranjang kosong',
                                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Tambahkan atasan atau bawahan dari pencarian katalog di bawah',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _cart.length,
                              itemBuilder: (context, index) {
                                final cartItem = _cart[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey[200]!),
                                  ),
                                  color: Colors.grey[50],
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        // Category Icon badge
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: cartItem.item.type == 'top'
                                                ? Colors.orange[50]
                                                : Colors.blue[50],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            cartItem.item.type == 'top'
                                                ? Icons.checkroom_outlined
                                                : Icons.accessibility_new_outlined,
                                            color: cartItem.item.type == 'top'
                                                ? Colors.orange[800]
                                                : Colors.blue[800],
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cartItem.item.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${cartItem.item.sku} • Ukuran: ${cartItem.item.size} • ${cartItem.item.color}',
                                                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Edit Price field
                                        SizedBox(
                                          width: 100,
                                          child: TextFormField(
                                            initialValue: cartItem.customPrice.toStringAsFixed(0),
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              prefixText: 'Rp ',
                                              labelText: 'Harga Sewa',
                                              labelStyle: const TextStyle(fontSize: 10),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                            onChanged: (val) {
                                              final parsed = double.tryParse(val);
                                              if (parsed != null) {
                                                setState(() {
                                                  cartItem.customPrice = parsed;
                                                });
                                                if (_modalSetState != null) {
                                                  _modalSetState!(() {});
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: () => _removeItemFromCart(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimasi Total:',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Rp ${NumberFormat('#,###').format(_totalAmount)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Inventory Catalog search
          Expanded(
            flex: 4,
            child: Card(
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              elevation: 0.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      onChanged: (val) {
                        setState(() {
                          _catalogSearchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari stok untuk ditambahkan (SKU, nama, warna, ukuran, tag)...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: invProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : searchResults.isEmpty
                              ? Center(
                                  child: Text(
                                    'Tidak ada gown yang cocok ditemukan di inventaris.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, index) {
                                    final item = searchResults[index];
                                    final isUnavailable = _selectedDate != null && _unavailableItemIds.contains(item.id);
                                    return ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                      leading: CircleAvatar(
                                        backgroundColor: isUnavailable
                                            ? Colors.grey[200]
                                            : (item.type == 'top' ? Colors.orange[50] : Colors.blue[50]),
                                        radius: 16,
                                        child: Text(
                                          item.type == 'top' ? 'T' : 'B',
                                          style: TextStyle(
                                            color: isUnavailable
                                                ? Colors.grey
                                                : (item.type == 'top' ? Colors.orange[800] : Colors.blue[800]),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isUnavailable ? Colors.grey : Colors.black87,
                                        ),
                                      ),
                                      subtitle: isUnavailable
                                          ? Text(
                                              'Dipesan / Diblokir (Blokir ${Provider.of<RentalProvider>(context, listen: false).dateLockingPeriod * 2} hari)',
                                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 10),
                                            )
                                          : Text('${item.sku} • Uk: ${item.size} • Rp ${NumberFormat('#,###').format(item.rentalRate ?? 0)}'),
                                      trailing: IconButton(
                                        icon: Icon(
                                          isUnavailable ? Icons.block : Icons.add_circle,
                                          color: isUnavailable ? Colors.grey : primaryColor,
                                        ),
                                        onPressed: isUnavailable ? null : () => _addItemToCart(item),
                                      ),
                                    );
                                  },
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

    if (isMobile) {
      // Mobile layout: Single page with forms, custom bottom drawer for Cart picker
      return Scaffold(
        body: buildFormPanel(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setModalState) {
                    _modalSetState = setModalState;
                    return FractionallySizedBox(
                      heightFactor: 0.8,
                      child: buildCartPanel(),
                    );
                  },
                );
              },
            ).then((_) {
              _modalSetState = null;
            });
          },
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.shopping_cart),
          label: Text('Keranjang (${_cart.length}) - Rp ${NumberFormat('#,###').format(_totalAmount)}'),
        ),
      );
    } else {
      // Tablet/Desktop: Split layout side-by-side
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: buildFormPanel(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            flex: 5,
            child: buildCartPanel(),
          ),
        ],
      );
    }
  }
}
