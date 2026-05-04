import '../models/product.dart';

class CheckoutArguments {
  const CheckoutArguments({required this.product, this.quantity = 1})
      : assert(quantity > 0);

  final Product product;
  final int quantity;
}

class ShippingDetailsPayload {
  const ShippingDetailsPayload({
    required this.fullName,
    required this.primaryPhone,
    this.secondaryPhone,
    required this.state,
    required this.city,
    required this.zipCode,
    required this.shippingAddress,
    this.billingAddress,
  });

  final String fullName;
  final String primaryPhone;
  final String? secondaryPhone;
  final String state;
  final String city;
  final String zipCode;
  final String shippingAddress;
  final String? billingAddress;
}
