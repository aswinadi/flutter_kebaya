import 'dart:io';
import 'package:flutter/material.dart';
import '../models/rental.dart';
import '../services/api_service.dart';

class RentalProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<Rental> _rentals = [];
  bool _isLoading = false;
  String? _error;

  List<Rental> get rentals => _rentals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRentals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _rentals = await _api.getRentals();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkout({
    required String customerName,
    String? customerPhone,
    required DateTime eventDate,
    required String status,
    String? groupOrderName,
    required List<Map<String, dynamic>> items,
    File? clientPicFile,
    List<File>? beforePhotos,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newRental = await _api.createRental(
        customerName: customerName,
        customerPhone: customerPhone,
        eventDate: eventDate,
        status: status,
        groupOrderName: groupOrderName,
        items: items,
        clientPicFile: clientPicFile,
        beforePhotos: beforePhotos,
      );
      _rentals.insert(0, newRental);
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

  Future<bool> updateRentalDetails(
    int id, {
    String? status,
    String? customerName,
    String? customerPhone,
    DateTime? eventDate,
    String? groupOrderName,
    String? notes,
    File? clientPicFile,
    List<File>? beforePhotos,
    List<File>? afterPhotos,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _api.updateRental(
        id,
        status: status,
        customerName: customerName,
        customerPhone: customerPhone,
        eventDate: eventDate,
        groupOrderName: groupOrderName,
        notes: notes,
        clientPicFile: clientPicFile,
        beforePhotos: beforePhotos,
        afterPhotos: afterPhotos,
      );

      final index = _rentals.indexWhere((element) => element.id == id);
      if (index != -1) {
        _rentals[index] = updated;
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

  Future<bool> deactivateRental(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.deactivateRental(id);
      _rentals.removeWhere((element) => element.id == id);
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
