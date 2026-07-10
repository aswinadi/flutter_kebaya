class RentalComponent {
  final int id;
  final int inventoryItemId;
  final String? name;
  final String? sku;
  final String? type;
  final String? size;
  final String? color;
  final String? imageUrl;
  final String? imagePath;
  final double? rentalPrice; // Nullable for workers

  RentalComponent({
    required this.id,
    required this.inventoryItemId,
    this.name,
    this.sku,
    this.type,
    this.size,
    this.color,
    this.imageUrl,
    this.imagePath,
    this.rentalPrice,
  });

  factory RentalComponent.fromJson(Map<String, dynamic> json) {
    return RentalComponent(
      id: json['id'] as int,
      inventoryItemId: json['inventory_item_id'] as int,
      name: json['name'] as String?,
      sku: json['sku'] as String?,
      type: json['type'] as String?,
      size: json['size'] as String?,
      color: json['color'] as String?,
      imageUrl: json['image_url'] as String?,
      imagePath: json['image_path'] as String?,
      rentalPrice: json['rental_price'] != null ? double.tryParse(json['rental_price'].toString()) : null,
    );
  }
}

class Rental {
  final int id;
  final String invoiceNumber;
  final String customerName;
  final String? customerPhone;
  final DateTime eventDate;
  final String status; // 'booked', 'picked_up', 'returned', 'cancelled', 'void'
  final String? groupOrderName;
  final double? totalAmount; // Nullable for workers
  final String? clientPicUrl;
  final String? clientPicPath;
  final List<Map<String, dynamic>> beforePhotos;
  final List<Map<String, dynamic>> afterPhotos;
  final List<RentalComponent> items;
  final DateTime createdAt;
  final bool isActive;
  final String? notes;

  Rental({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    this.customerPhone,
    required this.eventDate,
    required this.status,
    this.groupOrderName,
    this.totalAmount,
    this.clientPicUrl,
    this.clientPicPath,
    required this.beforePhotos,
    required this.afterPhotos,
    required this.items,
    required this.createdAt,
    this.isActive = true,
    this.notes,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<RentalComponent> itemList = rawItems.map((item) => RentalComponent.fromJson(item)).toList();

    var rawBefore = json['before_photos'] as List? ?? [];
    List<Map<String, dynamic>> beforeList = rawBefore.map((b) => Map<String, dynamic>.from(b)).toList();

    var rawAfter = json['after_photos'] as List? ?? [];
    List<Map<String, dynamic>> afterList = rawAfter.map((a) => Map<String, dynamic>.from(a)).toList();

    return Rental(
      id: json['id'] as int,
      invoiceNumber: json['invoice_number'] as String,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String?,
      eventDate: DateTime.parse(json['event_date'] as String).toLocal(),
      status: json['status'] as String,
      groupOrderName: json['group_order_name'] as String?,
      totalAmount: json['total_amount'] != null ? double.tryParse(json['total_amount'].toString()) : null,
      clientPicUrl: json['client_pic_url'] as String?,
      clientPicPath: json['client_pic_path'] as String?,
      beforePhotos: beforeList,
      afterPhotos: afterList,
      items: itemList,
      createdAt: DateTime.parse(json['created_at'] as String),
      isActive: json['is_active'] ?? true,
      notes: json['notes'] as String?,
    );
  }
}
