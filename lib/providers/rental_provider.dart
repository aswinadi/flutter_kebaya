import 'dart:io';
import 'package:flutter/material.dart';
import '../models/rental.dart';
import '../services/api_service.dart';

class RentalProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<Rental> _rentals = [];
  bool _isLoading = false;
  String? _error;
  int _dateLockingPeriod = 7;

  List<Rental> get rentals => _rentals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get dateLockingPeriod => _dateLockingPeriod;

  Future<void> fetchSettings() async {
    try {
      final settings = await _api.getSettings();
      if (settings.containsKey('date_locking_period')) {
        _dateLockingPeriod = settings['date_locking_period'] as int;
        notifyListeners();
      }
    } catch (_) {
      // Fallback to default if load fails
    }
  }

  Future<bool> updateDateLockingPeriod(int days) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.updateDateLockingPeriod(days);
      _dateLockingPeriod = days;
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

  Future<void> fetchRentals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await fetchSettings();
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
    List<File>? clientPicFiles,
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
        clientPicFiles: clientPicFiles,
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
    List<File>? clientPicFiles,
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
        clientPicFiles: clientPicFiles,
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
