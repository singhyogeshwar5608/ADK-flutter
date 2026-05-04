import '../models/product.dart';

import 'product_share_mobile.dart'
    if (dart.library.html) 'product_share_web.dart' as impl;

Future<bool> shareProductDetails(Product product) =>
    impl.shareProductDetails(product);
