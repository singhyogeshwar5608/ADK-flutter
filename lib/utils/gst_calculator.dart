import '../state/cart_state.dart';

class GstCalculator {
  static double calculateAverageGstPercent(CartState cart) {
    final selectedItems = cart.items.where((item) => item.isSelected);
    if (selectedItems.isEmpty) return 0.0;
    
    double totalGst = 0.0;
    double totalValue = 0.0;
    
    for (final item in selectedItems) {
      totalGst += item.totalGst();
      totalValue += item.totalPrice();
    }
    
    // Calculate average GST percentage
    if (totalValue <= 0) return 0.0;
    return (totalGst / totalValue) * 100;
  }
  
  static String getGstPercentLabel(CartState cart) {
    final avgPercent = calculateAverageGstPercent(cart);
    if (avgPercent <= 0) return '0%';
    return '${avgPercent.toStringAsFixed(1)}%';
  }
}
