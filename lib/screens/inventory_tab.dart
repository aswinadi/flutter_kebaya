import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory_item.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/gown_card.dart';
import '../widgets/responsive_layout.dart';
import 'inventory_form_screen.dart';

class InventoryTab extends StatefulWidget {
  const InventoryTab({Key? key}) : super(key: key);

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  InventoryItem? _selectedItem; // Side-by-side mode only
  bool _isCreatingNew = false; // Side-by-side mode only

  @override
  void initState() {
    super.initState();
    // Fetch inventory data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchInventory();
    });
  }

  void _clearRightPane() {
    setState(() {
      _selectedItem = null;
      _isCreatingNew = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InventoryProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final isMobile = ResponsiveLayout.isMobile(context);
    final primaryColor = Colors.purple[900]!;

    Widget searchAndFilters() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => provider.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Cari berdasarkan SKU, nama, warna, ukuran, atau tag...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      suffixIcon: provider.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedItem = null;
                        _isCreatingNew = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Komponen', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Type Filter dropdown
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: provider.selectedType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Semua Kategori')),
                      DropdownMenuItem(value: 'top', child: Text('Atasan (Tops)')),
                      DropdownMenuItem(value: 'bottom', child: Text('Bawahan (Bottoms)')),
                    ],
                    onChanged: (value) => provider.setFilterType(value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: provider.selectedTag == null,
                    onSelected: (selected) {
                      if (selected) {
                        provider.setSelectedTag(null);
                      }
                    },
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(
                      color: provider.selectedTag == null ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...provider.activeTagsWithCounts.entries.map((entry) {
                    final tag = entry.key;
                    final count = entry.value;
                    final isSelected = provider.selectedTag == tag;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text('$tag ($count)'),
                        selected: isSelected,
                        onSelected: (selected) {
                          provider.setSelectedTag(selected ? tag : null);
                        },
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget catalogGrid(int columns) {
      if (provider.isLoading && provider.items.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      
      final items = provider.filteredItems;

      if (items.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[350]),
                const SizedBox(height: 16),
                const Text(
                  'Gown Tidak Ditemukan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coba ubah filter Anda atau tambah komponen baru.',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemCount: items.size,
        itemBuilder: (context, index) {
          final item = items[index];
          return GownCard(
            item: item,
            isOwner: user?.isOwner ?? false,
            onTap: () {
              if (isMobile) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InventoryFormScreen(item: item),
                  ),
                );
              } else {
                setState(() {
                  _selectedItem = item;
                  _isCreatingNew = false;
                });
              }
            },
          );
        },
      );
    }

    // Standard Mobile view: Full width grid
    Widget buildMobileBody() {
      return Scaffold(
        body: Column(
          children: [
            searchAndFilters(),
            Expanded(child: catalogGrid(2)),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const InventoryFormScreen(),
              ),
            );
          },
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      );
    }

    // Tablet/Desktop view: Split layout side-by-side
    Widget buildTabletBody() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left catalog panel
          Expanded(
            flex: 6,
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  searchAndFilters(),
                  const Divider(height: 1),
                  Expanded(child: catalogGrid(3)),
                ],
              ),
            ),
          ),
          
          // Right edit/create form panel
          Expanded(
            flex: 4,
            child: _isCreatingNew
                ? InventoryFormScreen(
                    isEmbedded: true,
                    onSaved: () {
                      _clearRightPane();
                      provider.fetchInventory();
                    },
                  )
                : _selectedItem != null
                    ? InventoryFormScreen(
                        item: _selectedItem,
                        isEmbedded: true,
                        onSaved: () {
                          _clearRightPane();
                          provider.fetchInventory();
                        },
                      )
                    : Card(
                        margin: const EdgeInsets.all(16),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.store_mall_directory_outlined,
                                  size: 72,
                                  color: Colors.purple[100],
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Manajemen Komponen Gown',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Pilih item dari katalog di sebelah kiri untuk mengubah detailnya, atau klik "Tambah Komponen" di atas untuk menambahkan bagian gown baru.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _selectedItem = null;
                                      _isCreatingNew = true;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Tambah Komponen Gown Baru', style: TextStyle(fontWeight: FontWeight.bold)),
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

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: provider.fetchInventory,
        child: ResponsiveLayout(
          mobileBody: buildMobileBody(),
          tabletBody: buildTabletBody(),
        ),
      ),
    );
  }
}
extension on List {
  get size => length;
}
