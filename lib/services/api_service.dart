import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/user.dart';
import '../models/inventory_item.dart';
import '../models/rental.dart';
import '../models/job_order.dart';

class ApiService {
  String baseUrl = 'https://biogeographic-raylan-interdentally.ngrok-free.dev'; // Default development Ngrok host
  String? token;
  User? currentUser;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  void updateBaseUrl(String newUrl) {
    if (newUrl.endsWith('/')) {
      baseUrl = newUrl.substring(0, newUrl.length - 1);
    } else {
      baseUrl = newUrl;
    }
  }

  void setToken(String? newToken) {
    token = newToken;
  }

  Map<String, String> _getHeaders() {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String getMediaUrl(String? serverPath) {
    if (serverPath == null) return '';
    if (serverPath.startsWith('http://') || serverPath.startsWith('https://')) {
      return serverPath;
    }
    return '$baseUrl$serverPath';
  }

  // --- Auth Endpoints ---

  Future<User> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data['access_token'];
      currentUser = User.fromJson(data['user']);
      return currentUser!;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? error['errors']?['username']?[0] ?? 'Login failed');
    }
  }

  Future<void> logout() async {
    if (token == null) return;
    try {
      await http.post(
        Uri.parse('$baseUrl/api/logout'),
        headers: _getHeaders(),
      );
    } catch (_) {}
    token = null;
    currentUser = null;
  }

  Future<void> changePassword(String currentPassword, String newPassword, String newPasswordConfirmation) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/change-password'),
      headers: _getHeaders(),
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? error['errors']?.toString() ?? 'Failed to change password');
    }
  }

  Future<List<Map<String, dynamic>>> getWorkers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/workers'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List raw = jsonDecode(response.body);
      return raw.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      throw Exception('Failed to load workers list');
    }
  }

  Future<List<User>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/users'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List raw = jsonDecode(response.body);
      return raw.map((item) => User.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<User> createUser({
    required String name,
    required String username,
    required String email,
    required String password,
    required List<String> roles,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/users'),
      headers: _getHeaders(),
      body: jsonEncode({
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'roles': roles,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['user']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? error['errors']?.toString() ?? 'Failed to create user');
    }
  }

  Future<List<String>> getRoles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/roles'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List raw = jsonDecode(response.body);
      return raw.map((item) => item.toString()).toList();
    } else {
      throw Exception('Failed to fetch roles');
    }
  }

  // --- Inventory Endpoints ---

  Future<List<InventoryItem>> getInventory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/inventory'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List raw = jsonDecode(response.body);
      return raw.map((item) => InventoryItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch inventory catalog');
    }
  }

  Future<InventoryItem> createInventoryItem({
    required String name,
    required String type,
    required String size,
    required String color,
    required String description,
    double? rentalRate,
    File? imageFile,
  }) async {
    var uri = Uri.parse('$baseUrl/api/inventory');
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    request.fields['name'] = name;
    request.fields['type'] = type;
    request.fields['size'] = size;
    request.fields['color'] = color;
    request.fields['description'] = description;
    if (rentalRate != null) {
      request.fields['rental_rate'] = rentalRate.toString();
    }

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return InventoryItem.fromJson(data['item']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? error['errors']?.toString() ?? 'Failed to create inventory item');
    }
  }

  Future<InventoryItem> updateInventoryItem(
    int id, {
    required String name,
    required String type,
    required String size,
    required String color,
    required String description,
    double? rentalRate,
    File? imageFile,
  }) async {
    // Standard multipart PUT requests sometimes parse incorrectly in PHP/Laravel.
    // So we POST to the endpoint with the original URL because routes/api.php is set to POST /inventory/{id}
    var uri = Uri.parse('$baseUrl/api/inventory/$id');
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    request.fields['name'] = name;
    request.fields['type'] = type;
    request.fields['size'] = size;
    request.fields['color'] = color;
    request.fields['description'] = description;
    if (rentalRate != null) {
      request.fields['rental_rate'] = rentalRate.toString();
    }

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return InventoryItem.fromJson(data['item']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? error['errors']?.toString() ?? 'Failed to update inventory item');
    }
  }

  Future<void> deactivateInventoryItem(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/inventory/$id'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to deactivate item');
    }
  }

  // --- Rentals POS Endpoints ---

  Future<List<Rental>> getRentals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/rentals'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List raw = jsonDecode(response.body);
      return raw.map((item) => Rental.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch rentals');
    }
  }

  Future<Rental> createRental({
    required String customerName,
    String? customerPhone,
    required DateTime eventDate,
    required String status,
    String? groupOrderName,
    required List<Map<String, dynamic>> items,
    File? clientPicFile,
    List<File>? beforePhotos,
  }) async {
    var uri = Uri.parse('$baseUrl/api/rentals');
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    request.fields['customer_name'] = customerName;
    if (customerPhone != null) request.fields['customer_phone'] = customerPhone;
    request.fields['event_date'] = eventDate.toIso8601String();
    request.fields['status'] = status;
    if (groupOrderName != null) request.fields['group_order_name'] = groupOrderName;

    // Send nested items array parameters in PHP array formats
    for (int i = 0; i < items.length; i++) {
      request.fields['items[$i][inventory_item_id]'] = items[i]['inventory_item_id'].toString();
      if (items[i]['rental_price'] != null) {
        request.fields['items[$i][rental_price]'] = items[i]['rental_price'].toString();
      }
    }

    if (clientPicFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'client_pic',
          clientPicFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    if (beforePhotos != null) {
      for (var file in beforePhotos) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'before_photos[]',
            file.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Rental.fromJson(data['rental']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? error['errors']?.toString() ?? 'Failed to create rental');
    }
  }

  Future<Rental> updateRental(
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
    // Send as POST for multipart file loading support in PHP.
    var uri = Uri.parse('$baseUrl/api/rentals/$id');
    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    });

    if (status != null) request.fields['status'] = status;
    if (customerName != null) request.fields['customer_name'] = customerName;
    if (customerPhone != null) request.fields['customer_phone'] = customerPhone;
    if (eventDate != null) request.fields['event_date'] = eventDate.toIso8601String();
    if (groupOrderName != null) request.fields['group_order_name'] = groupOrderName;
    if (notes != null) request.fields['notes'] = notes;

    if (clientPicFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'client_pic',
          clientPicFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    if (beforePhotos != null) {
      for (var file in beforePhotos) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'before_photos[]',
            file.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
    }

    if (afterPhotos != null) {
      for (var file in afterPhotos) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'after_photos[]',
            file.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Rental.fromJson(data['rental']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? error['errors']?.toString() ?? 'Failed to update rental status/media');
    }
  }

  Future<void> deactivateRental(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/rentals/$id'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to deactivate rental');
    }
  }

  // --- Job Orders / Production Endpoints ---

  Future<List<JobOrder>> getJobOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/job-orders'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List raw = jsonDecode(response.body);
      return raw.map((item) => JobOrder.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch job orders');
    }
  }

  Future<JobOrder> updateJobOrder(
    int id, {
    required String status,
    required String instructions,
    DateTime? dueDate,
  }) async {
    final body = {
      'status': status,
      'instructions': instructions,
      if (dueDate != null) 'due_date': dueDate.toIso8601String(),
    };

    final response = await http.put(
      Uri.parse('$baseUrl/api/job-orders/$id'),
      headers: _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return JobOrder.fromJson(data['job']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? error['errors']?.toString() ?? 'Failed to update job order');
    }
  }

  Future<JobOrder> addLaborLog(
    int jobOrderId, {
    required int workerId,
    required int days,
    required int hours,
    required List<String> crafts,
    required String description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/job-orders/$jobOrderId/labor-logs'),
      headers: _getHeaders(),
      body: jsonEncode({
        'worker_id': workerId,
        'days': days,
        'hours': hours,
        'crafts': crafts,
        'description': description,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return JobOrder.fromJson(data['job']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? error['errors']?.toString() ?? 'Failed to add labor log');
    }
  }

  Future<JobOrder> deleteLaborLog(int laborLogId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/labor-logs/$laborLogId'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return JobOrder.fromJson(data['job']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to delete labor log');
    }
  }

  Future<List<int>> getUnavailableItemIds(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final response = await http.get(
      Uri.parse('$baseUrl/api/rentals/availability?date=$dateStr'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List rawIds = data['unavailable_item_ids'] ?? [];
      return rawIds.map((id) => id as int).toList();
    } else {
      throw Exception('Failed to fetch availability data');
    }
  }
}
