import 'inventory_item.dart';

class CartItem {
  final InventoryItem item;
  double customPrice;

  CartItem({
    required this.item,
    required this.customPrice,
  });
}
