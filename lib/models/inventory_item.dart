class InventoryItem {
  final int id;
  final String name;
  final String sku;
  final String type; // 'top' or 'bottom'
  final String size; // 'S', 'M', 'L', 'XL', 'XXL', 'Custom'
  final String color;
  final double? rentalRate; // Nullable for workers
  final String? description;
  final String? imageUrl;
  final String? imagePath;
  final bool isActive;
  final List<String> tags;

  InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.type,
    required this.size,
    required this.color,
    this.rentalRate,
    this.description,
    this.imageUrl,
    this.imagePath,
    this.isActive = true,
    this.tags = const [],
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as int,
      name: json['name'] as String,
      sku: json['sku'] as String,
      type: json['type'] as String,
      size: json['size'] as String,
      color: json['color'] as String,
      rentalRate: json['rental_rate'] != null ? double.tryParse(json['rental_rate'].toString()) : null,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      imagePath: json['image_path'] as String?,
      isActive: json['is_active'] ?? true,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'type': type,
      'size': size,
      'color': color,
      'rental_rate': rentalRate,
      'description': description,
      'image_url': imageUrl,
      'image_path': imagePath,
      'is_active': isActive,
      'tags': tags,
    };
  }
}
