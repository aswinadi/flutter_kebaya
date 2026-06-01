import 'labor_log.dart';

class JobOrder {
  final int id;
  final int rentalId;
  final String? rentalInvoice;
  final String? customerName;
  final String? customerPhone;
  final String? clientPicUrl;
  final String? clientPicPath;
  final int inventoryItemId;
  final String? itemName;
  final String? itemSku;
  final String? itemSize;
  final String? itemColor;
  final String? itemType;
  final String? itemImageUrl;
  final String? itemImagePath;
  final DateTime dueDate;
  final String status; // 'pending', 'in_progress', 'completed'
  final String? instructions;
  final double totalManDays;
  final List<LaborLog> laborLogs;

  JobOrder({
    required this.id,
    required this.rentalId,
    this.rentalInvoice,
    this.customerName,
    this.customerPhone,
    this.clientPicUrl,
    this.clientPicPath,
    required this.inventoryItemId,
    this.itemName,
    this.itemSku,
    this.itemSize,
    this.itemColor,
    this.itemType,
    this.itemImageUrl,
    this.itemImagePath,
    required this.dueDate,
    required this.status,
    this.instructions,
    required this.totalManDays,
    required this.laborLogs,
  });

  factory JobOrder.fromJson(Map<String, dynamic> json) {
    var rawLogs = json['labor_logs'] as List? ?? [];
    List<LaborLog> logList = rawLogs.map((log) => LaborLog.fromJson(log)).toList();

    return JobOrder(
      id: json['id'] as int,
      rentalId: json['rental_id'] as int,
      rentalInvoice: json['rental_invoice'] as String?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      clientPicUrl: json['client_pic_url'] as String?,
      clientPicPath: json['client_pic_path'] as String?,
      inventoryItemId: json['inventory_item_id'] as int,
      itemName: json['item_name'] as String?,
      itemSku: json['item_sku'] as String?,
      itemSize: json['item_size'] as String?,
      itemColor: json['item_color'] as String?,
      itemType: json['item_type'] as String?,
      itemImageUrl: json['item_image_url'] as String?,
      itemImagePath: json['item_image_path'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      status: json['status'] as String,
      instructions: json['instructions'] as String?,
      totalManDays: double.parse(json['total_man_days'].toString()),
      laborLogs: logList,
    );
  }
}
