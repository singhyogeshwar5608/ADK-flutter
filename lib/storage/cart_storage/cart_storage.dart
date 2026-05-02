import 'cart_storage_base.dart';
import 'cart_storage_stub.dart'
    if (dart.library.io) 'cart_storage_io.dart'
    if (dart.library.html) 'cart_storage_web.dart';

export 'cart_storage_base.dart';

CartStorage createCartStorage() => buildCartStorage();
