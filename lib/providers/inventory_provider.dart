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
  String? _selectedSize; // 'S', 'M', 'L', 'XL', 'XXL', 'Custom', or null (all)

  List<InventoryItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  String get searchQuery => _searchQuery;
  String? get selectedType => _selectedType;
  String? get selectedSize => _selectedSize;

  List<InventoryItem> get filteredItems {
    return _items.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.color.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesType = _selectedType == null || item.type == _selectedType;
      final matchesSize = _selectedSize == null || item.size == _selectedSize;
      
      return matchesSearch && matchesType && matchesSize;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilterType(String? type) {
    _selectedType = type;
    notifyListeners();
  }

  void setFilterSize(String? size) {
    _selectedSize = size;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedType = null;
    _selectedSize = null;
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
