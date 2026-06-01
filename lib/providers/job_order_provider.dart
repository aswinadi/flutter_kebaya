import 'package:flutter/material.dart';
import '../models/job_order.dart';
import '../services/api_service.dart';

class JobOrderProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<JobOrder> _jobs = [];
  List<Map<String, dynamic>> _workers = [];
  bool _isLoading = false;
  String? _error;

  List<JobOrder> get jobs => _jobs;
  List<Map<String, dynamic>> get workers => _workers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchJobOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobs = await _api.getJobOrders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWorkers() async {
    try {
      _workers = await _api.getWorkers();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateJob(
    int id, {
    required String status,
    required String instructions,
    DateTime? dueDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _api.updateJobOrder(
        id,
        status: status,
        instructions: instructions,
        dueDate: dueDate,
      );

      final index = _jobs.indexWhere((element) => element.id == id);
      if (index != -1) {
        _jobs[index] = updated;
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

  Future<bool> logLabor(
    int jobOrderId, {
    required int workerId,
    required int days,
    required int hours,
    required List<String> crafts,
    required String description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _api.addLaborLog(
        jobOrderId,
        workerId: workerId,
        days: days,
        hours: hours,
        crafts: crafts,
        description: description,
      );

      final index = _jobs.indexWhere((element) => element.id == jobOrderId);
      if (index != -1) {
        _jobs[index] = updated;
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

  Future<bool> removeLaborLog(int jobOrderId, int laborLogId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _api.deleteLaborLog(laborLogId);

      final index = _jobs.indexWhere((element) => element.id == jobOrderId);
      if (index != -1) {
        _jobs[index] = updated;
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
}
