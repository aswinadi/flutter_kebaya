import 'labor_log.dart';

class JobOrderItem {
  final int id;
  final int inventoryItemId;
  final String? name;
  final String? sku;
  final String? type;
  final String? size;
  final String? color;
  final String? imageUrl;
  final String? imagePath;

  JobOrderItem({
    required this.id,
    required this.inventoryItemId,
    this.name,
    this.sku,
    this.type,
    this.size,
    this.color,
    this.imageUrl,
    this.imagePath,
  });

  factory JobOrderItem.fromJson(Map<String, dynamic> json) {
    return JobOrderItem(
      id: json['id'] as int,
      inventoryItemId: json['inventory_item_id'] as int,
      name: json['name'] as String?,
      sku: json['sku'] as String?,
      type: json['type'] as String?,
      size: json['size'] as String?,
      color: json['color'] as String?,
      imageUrl: json['image_url'] as String?,
      imagePath: json['image_path'] as String?,
    );
  }
}

class JobOrder {
  final int id;
  final int rentalId;
  final String? rentalInvoice;
  final String? customerName;
  final String? customerPhone;
  final String? clientPicUrl;
  final String? clientPicPath;
  final int? inventoryItemId;
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
  final List<JobOrderItem> items;

  JobOrder({
    required this.id,
    required this.rentalId,
    this.rentalInvoice,
    this.customerName,
    this.customerPhone,
    this.clientPicUrl,
    this.clientPicPath,
    this.inventoryItemId,
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
    required this.items,
  });

  factory JobOrder.fromJson(Map<String, dynamic> json) {
    var rawLogs = json['labor_logs'] as List? ?? [];
    List<LaborLog> logList = rawLogs.map((log) => LaborLog.fromJson(log)).toList();

    var rawItems = json['items'] as List? ?? [];
    List<JobOrderItem> itemList = rawItems.map((item) => JobOrderItem.fromJson(item)).toList();

    return JobOrder(
      id: json['id'] as int,
      rentalId: json['rental_id'] as int,
      rentalInvoice: json['rental_invoice'] as String?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      clientPicUrl: json['client_pic_url'] as String?,
      clientPicPath: json['client_pic_path'] as String?,
      inventoryItemId: json['inventory_item_id'] as int?,
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
      items: itemList,
    );
  }
}
