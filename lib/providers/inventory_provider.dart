import 'dart:io';
import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../services/api_service.dart';

class InventoryProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<InventoryItem> _items = [];
  bool _isLoading = false;
  String? _error;

  String _searchQuery = '';
  String? _selectedType; // 'top', 'bottom', or null (all)
  String? _selectedTag; // Tag name or null (all)

  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  String get searchQuery => _searchQuery;
  String? get selectedType => _selectedType;
  String? get selectedTag => _selectedTag;

  List<InventoryItem> get filteredItems {
    final tokens = _searchQuery.toLowerCase().split(RegExp(r'\s+')).where((token) => token.isNotEmpty).toList();

    return _items.where((item) {
      bool matchesSearch = true;
      if (tokens.isNotEmpty) {
        matchesSearch = tokens.every((token) {
          final matchesName = item.name.toLowerCase().contains(token);
          final matchesSku = item.sku.toLowerCase().contains(token);
          final matchesColor = item.color.toLowerCase().contains(token);
          final matchesDesc = (item.description ?? '').toLowerCase().contains(token);
          final matchesSize = item.size.toLowerCase() == token;
          final matchesTag = item.tags.any((tag) => tag.toLowerCase().contains(token));
          return matchesName || matchesSku || matchesColor || matchesDesc || matchesSize || matchesTag;
        });
      }
      
      final matchesType = _selectedType == null || item.type == _selectedType;
      final matchesTag = _selectedTag == null || item.tags.any((tag) => tag.toLowerCase() == _selectedTag!.toLowerCase());
      
      return matchesSearch && matchesType && matchesTag;
    }).toList();
  }

  Map<String, int> get activeTagsWithCounts {
    final Map<String, int> counts = {};
    for (var item in _items) {
      for (var tag in item.tags) {
        final normalizedTag = tag.trim();
        if (normalizedTag.isNotEmpty) {
          counts[normalizedTag] = (counts[normalizedTag] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterType(String? type) {
    _selectedType = type;
    notifyListeners();
  }

  void setSelectedTag(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedType = null;
    _selectedTag = null;
    notifyListeners();
  }

  Future<void> fetchInventory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _api.getInventory();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createItem({
    required String name,
    required String type,
    required String size,
    required String color,
    required String description,
    double? rentalRate,
    File? imageFile,
    List<String>? tags,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newItem = await _api.createInventoryItem(
        name: name,
        type: type,
        size: size,
        color: color,
        description: description,
        rentalRate: rentalRate,
        imageFile: imageFile,
        tags: tags,
      );
      _items.insert(0, newItem);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateItem(
    int id, {
    required String name,
    required String type,
    required String size,
    required String color,
    required String description,
    double? rentalRate,
    File? imageFile,
    List<String>? tags,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedItem = await _api.updateInventoryItem(
        id,
        name: name,
        type: type,
        size: size,
        color: color,
        description: description,
        rentalRate: rentalRate,
        imageFile: imageFile,
        tags: tags,
      );
      
      final index = _items.indexWhere((element) => element.id == id);
      if (index != -1) {
        _items[index] = updatedItem;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.deactivateInventoryItem(id);
      _items.removeWhere((element) => element.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
