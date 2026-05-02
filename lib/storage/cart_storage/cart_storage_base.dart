abstract class CartStorage {
  Future<String?> read();
  Future<void> write(String data);
  Future<void> clear();
}

const String cartStorageKey = 'cart_state_items';
