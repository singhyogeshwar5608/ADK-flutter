import '../models/product.dart';
import '../models/product_entry.dart';

final List<ProductCatalogEntry> productCatalog = [
  ProductCatalogEntry(
    category: 'Smart Tech',
    brand: 'Paragon',
    rating: 4.8,
    popularityScore: 95,
    publishedAt: DateTime(2025, 10, 12),
    product: Product(
      id: 'p-001',
      title: 'Quantum Smart Watch',
      price: 199.00,
      totalPrice: 239.00,
      bv: 45,
      stock: 40,
      weight: 52,
      weightUnit: 'g',
      shippingCharge: 12.0,
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuC7yamOTR5RaF_OZYptLRpXZCzHnFmqEGffmYTJ3SkUuavITk-JgwEl5KR8Zl2Hsz8In5y13Sd8SwEylSJ9FJRHD1s5EhlAUsAUiId-xyWQztbIhrSRQxl1nnhVHZq9eKBGpcU0G58qBhPHwIrC-jiy56-kIz4IonWSB34cVHJzoWbGKnwtaee6bKU_eurvDf3FGPe1D12AmU65z-sj7K3f9l96kQsTtSUWtCcU-3BrRKWDTw9uFfMqwyC_yyIz0M1BvfXxf5-v6hE',
      description:
          'Track performance metrics, calls, and wellness stats with an elegant AMOLED Quantum display and week-long battery life.',
    ),
  )
];
