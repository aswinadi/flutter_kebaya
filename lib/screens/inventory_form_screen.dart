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
  
  String _selectedType = 'top';
  String _selectedSize = 'M';
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
    
    if (widget.item != null) {
      _selectedType = widget.item!.type;
      _selectedSize = widget.item!.size;
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
      _selectedType = widget.item?.type ?? 'top';
      _selectedSize = widget.item?.size ?? 'M';
      _imageFile = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _rateController.dispose();
    _descController.dispose();
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
        SnackBar(content: Text('Failed to pick image: $e')),
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
                title: const Text('Take Photo with Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
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
    final size = _selectedSize;
    final color = _colorController.text.trim();
    final description = _descController.text.trim();
    final rentalRate = isOwner ? double.tryParse(_rateController.text.trim()) : null;

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
      );
    }

    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.item == null
              ? 'Inventory item created successfully!'
              : 'Inventory item updated successfully!'),
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
          content: Text(provider.error ?? 'Failed to save item'),
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
        title: const Text('Delete Inventory Item?'),
        content: Text('Are you sure you want to delete ${widget.item!.name}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
        const SnackBar(content: Text('Item deleted successfully'), backgroundColor: Colors.green),
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
        SnackBar(content: Text(err ?? 'Failed to delete item'), backgroundColor: Colors.redAccent),
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
                                  'Tap to add or capture gown photo',
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
                            'SKU (Auto)',
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
                        labelText: 'Gown Component Name',
                        hintText: 'e.g., Premium Velvet Kebaya',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Name is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Type & Size dropdowns side by side
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Garment Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'top', child: Text('Top (Atasan)')),
                        DropdownMenuItem(value: 'bottom', child: Text('Bottom (Bawahan)')),
                      ],
                      onChanged: (value) => setState(() => _selectedType = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSize,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Size',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const ['S', 'M', 'L', 'XL', 'XXL', 'Custom']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedSize = value!),
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
                        labelText: 'Fabric Color',
                        hintText: 'e.g., Emerald Green',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Color is required' : null,
                    ),
                  ),
                  if (isOwner) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _rateController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Rental Rate (Rp)',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Rate is required' : null,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Item Description & Permak Limits',
                  hintText: 'Describe details, lace work, beading style, sizing limits...',
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
                      tooltip: 'Delete Gown',
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
                              widget.item == null ? 'Add to Catalog' : 'Update Item Details',
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
              title: Text(widget.item == null ? 'Create Gown Component' : 'Edit: ${widget.item!.name}'),
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
        title: Text(widget.item == null ? 'Add Gown to Catalog' : 'Edit Gown Components'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: formContent(),
    );
  }
}
