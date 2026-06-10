import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/inventory_item.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../services/api_service.dart';

class InventoryFormScreen extends StatefulWidget {
  final InventoryItem? item; // Null for creation, non-null for editing
  final bool isEmbedded; // If true, rendering side-by-side on tablet
  final VoidCallback? onSaved; // Optional callback for updating state in parent

  const InventoryFormScreen({
    Key? key,
    this.item,
    this.isEmbedded = false,
    this.onSaved,
  }) : super(key: key);

  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _colorController;
  late TextEditingController _rateController;
  late TextEditingController _descController;
  late TextEditingController _sizeController;
  late TextEditingController _tagsController;
  
  String _selectedType = 'top';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _colorController = TextEditingController(text: widget.item?.color ?? '');
    _rateController = TextEditingController(
      text: widget.item?.rentalRate != null ? widget.item!.rentalRate!.toStringAsFixed(0) : '',
    );
    _descController = TextEditingController(text: widget.item?.description ?? '');
    _sizeController = TextEditingController(text: widget.item?.size ?? 'M');
    _tagsController = TextEditingController(text: widget.item?.tags.join(', ') ?? '');
    
    if (widget.item != null) {
      _selectedType = widget.item!.type;
    }
  }

  @override
  void didUpdateWidget(covariant InventoryFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the selected item changes in embedded mode, update the fields
    if (widget.item != oldWidget.item) {
      _nameController.text = widget.item?.name ?? '';
      _colorController.text = widget.item?.color ?? '';
      _rateController.text = widget.item?.rentalRate != null ? widget.item!.rentalRate!.toStringAsFixed(0) : '';
      _descController.text = widget.item?.description ?? '';
      _sizeController.text = widget.item?.size ?? 'M';
      _tagsController.text = widget.item?.tags.join(', ') ?? '';
      _selectedType = widget.item?.type ?? 'top';
      _imageFile = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _rateController.dispose();
    _descController.dispose();
    _sizeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil gambar: $e')),
      );
    }
  }

  void _showImagePickerOptions() {
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
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    final provider = Provider.of<InventoryProvider>(context, listen: false);
    final isOwner = Provider.of<AuthProvider>(context, listen: false).user?.isOwner ?? false;
    
    final name = _nameController.text.trim();
    final type = _selectedType;
    final size = _sizeController.text.trim();
    final color = _colorController.text.trim();
    final description = _descController.text.trim();
    final rentalRate = isOwner ? double.tryParse(_rateController.text.trim()) : null;
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    bool success = false;
    
    if (widget.item == null) {
      // Create new
      success = await provider.createItem(
        name: name,
        type: type,
        size: size,
        color: color,
        description: description,
        rentalRate: rentalRate,
        imageFile: _imageFile,
        tags: tags,
      );
    } else {
      // Update existing
      success = await provider.updateItem(
        widget.item!.id,
        name: name,
        type: type,
        size: size,
        color: color,
        description: description,
        rentalRate: rentalRate,
        imageFile: _imageFile,
        tags: tags,
      );
    }

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.item == null
              ? 'Komponen gown berhasil dibuat!'
              : 'Komponen gown berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
      if (widget.onSaved != null) {
        widget.onSaved!();
      }
      if (!widget.isEmbedded) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal menyimpan item'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _deleteItem() async {
    if (widget.item == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Komponen Gown?'),
        content: Text('Apakah Anda yakin ingin menghapus ${widget.item!.name}? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    final success = await Provider.of<InventoryProvider>(context, listen: false).deleteItem(widget.item!.id);
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item berhasil dihapus'), backgroundColor: Colors.green),
      );
      if (widget.onSaved != null) {
        widget.onSaved!();
      }
      if (!widget.isEmbedded) {
        Navigator.pop(context);
      }
    } else {
      final err = Provider.of<InventoryProvider>(context, listen: false).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Gagal menghapus item'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = Provider.of<AuthProvider>(context).user?.isOwner ?? false;
    final primaryColor = Colors.purple[900]!;

    Widget formContent() {
      return Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker Area
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : widget.item?.imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.network(
                                Provider.of<InventoryProvider>(context).items.firstWhere((e) => e.id == widget.item!.id).imagePath != null
                                    ? ApiService().getMediaUrl(widget.item!.imagePath)
                                    : '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.add_a_photo_outlined, size: 40),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 40, color: primaryColor),
                                const SizedBox(height: 8),
                                Text(
                                  'Ketuk untuk menambahkan atau mengambil foto gown',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 24),

              // Layout container for SKU (left) & Name (right)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SKU Display on the left
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SKU (Otomatis)',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.item?.sku ?? 'AUTO-GEN',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: widget.item != null ? Colors.black87 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Item Name on the right
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Komponen Gown',
                        hintText: 'Misal: Kebaya Velvet Premium',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Nama wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Type & Size inputs side by side
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Kategori Garmen',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'top', child: Text('Atasan (Top)')),
                        DropdownMenuItem(value: 'bottom', child: Text('Bawahan (Bottom)')),
                      ],
                      onChanged: (value) => setState(() => _selectedType = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sizeController,
                      decoration: InputDecoration(
                        labelText: 'Ukuran Gown',
                        hintText: 'Misal: S, M, L, Custom, P: 100',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Ukuran wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Color & Rental Rate side by side (rate only for Owner)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _colorController,
                      decoration: InputDecoration(
                        labelText: 'Warna Kain',
                        hintText: 'Misal: Hijau Zamrud',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Warna wajib diisi' : null,
                    ),
                  ),
                  if (isOwner) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _rateController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Tarif Sewa (Rp)',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Tarif sewa wajib diisi' : null,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Tags
              TextFormField(
                controller: _tagsController,
                decoration: InputDecoration(
                  labelText: 'Tag / Kata Kunci (Dipisahkan koma)',
                  hintText: 'Misal: modern, premium, satin, batik',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Item & Batasan Permak',
                  hintText: 'Jelaskan detail, renda, payet, batas ukuran...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),

              // Save & Delete buttons
              Row(
                children: [
                  if (widget.item != null && isOwner) ...[
                    IconButton(
                      onPressed: _isSaving ? null : _deleteItem,
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Hapus Gown',
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              widget.item == null ? 'Tambah ke Katalog' : 'Perbarui Detail Item',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (widget.isEmbedded) {
      return Card(
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
        child: Column(
          children: [
            AppBar(
              title: Text(widget.item == null ? 'Buat Komponen Gown' : 'Ubah: ${widget.item!.name}'),
              automaticallyImplyLeading: false,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0.5,
              actions: [
                if (widget.item != null)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.black54),
                    onPressed: widget.onSaved, // Using callback as clear action
                  )
              ],
            ),
            Expanded(child: formContent()),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Tambah Gown ke Katalog' : 'Ubah Komponen Gown'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: formContent(),
    );
  }
}
