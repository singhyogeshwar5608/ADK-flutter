import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/product_entry.dart';
import '../state/product_catalog_state.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/category_slider.dart';
import '../widgets/header_widget.dart';
import '../widgets/hero_banner.dart';
import '../widgets/product_card.dart';
import 'all_products_screen.dart';
import 'product_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _allCategory = 'All Products';
  late String _selectedCategory;
  late final TextEditingController _searchController;
  String _searchQuery = '';
  /// `true` = two-column grid; `false` = single-column list.
  bool _featuredGridView = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _allCategory;
    _searchController = TextEditingController();
    _searchController.addListener(_handleSearchChanged);
  }

  void _handleSearchChanged() {
    final nextQuery = _searchController.text.trim();
    if (nextQuery == _searchQuery) return;
    setState(() => _searchQuery = nextQuery);
  }

  List<ProductCatalogEntry> _filteredProducts(
      List<ProductCatalogEntry> source) {
    final categoryFiltered = _selectedCategory == _allCategory
        ? source
        : source.where((entry) => entry.category == _selectedCategory).toList();

    if (_searchQuery.isEmpty) return categoryFiltered;

    final query = _searchQuery.toLowerCase();
    return categoryFiltered.where((entry) {
      final title = entry.product.title.toLowerCase();
      final brand = entry.brand.toLowerCase();
      final description = entry.product.description.toLowerCase();
      return title.contains(query) ||
          brand.contains(query) ||
          description.contains(query);
    }).toList();
  }

  int _countProductsFor(
      String categoryLabel, List<ProductCatalogEntry> source) {
    if (categoryLabel == _allCategory) return source.length;
    return source.where((entry) => entry.category == categoryLabel).length;
  }

  List<CategoryCardData> _buildCategoryCards(
    List<Category> remoteCategories,
    List<ProductCatalogEntry> source,
  ) {
    final cards = <CategoryCardData>[
      CategoryCardData(
        label: _allCategory,
        icon: Icons.auto_awesome,
        heroImage: '',
        productCount: _countProductsFor(_allCategory, source),
      ),
    ];

    if (remoteCategories.isEmpty) {
      cards.addAll(_fallbackCategoryCards.map((card) =>
          card.copyWith(productCount: _countProductsFor(card.label, source))));
      return cards;
    }

    for (final category in remoteCategories) {
      final label = category.name.trim().isEmpty
          ? 'Category ${category.id}'
          : category.name.trim();
      cards.add(CategoryCardData(
        label: label,
        icon: _iconForCategory(label),
        heroImage: category.logoUrl ?? '',
        productCount: _countProductsFor(label, source),
      ));
    }

    return cards;
  }

  IconData _iconForCategory(String label) {
    final normalized = label.toLowerCase();
    if (normalized.contains('tech') || normalized.contains('digital')) {
      return Icons.devices_other_rounded;
    }
    if (normalized.contains('health') || normalized.contains('wellness')) {
      return Icons.health_and_safety;
    }
    if (normalized.contains('beauty') || normalized.contains('care')) {
      return Icons.face_5;
    }
    if (normalized.contains('home') || normalized.contains('decor')) {
      return Icons.other_houses;
    }
    if (normalized.contains('footwear')) {
      return Icons.hiking;
    }
    if (normalized.contains('food') || normalized.contains('grocery')) {
      return Icons.lunch_dining;
    }
    if (normalized.contains('access')) {
      return Icons.watch;
    }
    if (normalized.contains('agri') || normalized.contains('farm')) {
      return Icons.agriculture;
    }
    return Icons.category_outlined;
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _clearSearchInput() {
    if (_searchQuery.isEmpty) return;
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalogState = ProductCatalogProvider.of(context);
    final sourceEntries = catalogState.entries;
    final remoteCategories = catalogState.categories;
    final filteredProducts = _filteredProducts(sourceEntries);
    final categoriesWithCounts =
        _buildCategoryCards(remoteCategories, sourceEntries);
    final isLoading = catalogState.isLoading && sourceEntries.isEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBody: false,
      bottomNavigationBar: const BottomNavBar(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            HeaderSliver(
              searchController: _searchController,
              searchQuery: _searchQuery,
              onClearSearch: _clearSearchInput,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HeroBanner(),
                    const SizedBox(height: 16),
                    CategorySlider(
                      categories: categoriesWithCounts,
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() => _selectedCategory = category.label);
                      },
                      onViewAllTap: () => Navigator.of(context)
                          .pushNamed(AllProductsScreen.routeName),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured Products',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        _SectionIconButton(
                          icon: Icons.view_list_rounded,
                          selected: !_featuredGridView,
                          tooltip: 'List view',
                          onPressed: () {
                            if (_featuredGridView) {
                              setState(() => _featuredGridView = false);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        _SectionIconButton(
                          icon: Icons.grid_view_rounded,
                          selected: _featuredGridView,
                          tooltip: 'Grid view',
                          onPressed: () {
                            if (!_featuredGridView) {
                              setState(() => _featuredGridView = true);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(11, 12, 11, 120),
              sliver: SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    const spacing = 6.0;
                    final itemWidth = _featuredGridView
                        ? (availableWidth - spacing) / 2
                        : availableWidth;

                    Widget productTile(ProductCatalogEntry entry) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailsScreen(
                                    product: entry.product),
                              ),
                            );
                          },
                          child: ProductCard(
                            product: entry.product,
                            rating: entry.rating,
                          ),
                        ),
                      );
                    }

                    if (isLoading) {
                      return SizedBox(
                        width: availableWidth,
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }
                    if (filteredProducts.isEmpty) {
                      return SizedBox(
                        width: availableWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No products for this category yet.'
                                : "No products match '$_searchQuery'.",
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (_featuredGridView) {
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final entry in filteredProducts)
                            SizedBox(
                              width: itemWidth,
                              child: productTile(entry),
                            ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < filteredProducts.length; i++) ...[
                          if (i > 0) const SizedBox(height: spacing),
                          productTile(filteredProducts[i]),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderSliver extends StatelessWidget {
  const HeaderSliver({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.onClearSearch,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 100,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: const HeaderWidget(),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: SizedBox(
            height: 48,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search products or brands...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                        onPressed: onClearSearch,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionIconButton extends StatelessWidget {
  const _SectionIconButton({
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final button = DecoratedBox(
      decoration: BoxDecoration(
        color: selected
            ? primary.withValues(alpha: isDark ? 0.28 : 0.18)
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? primary.withValues(alpha: 0.65)
              : Colors.transparent,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: Theme.of(context).colorScheme.onSurface,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(40, 40),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

const List<CategoryCardData> _fallbackCategoryCards = [
  CategoryCardData(
    label: 'All Products',
    icon: Icons.auto_awesome,
    heroImage: '',
    productCount: 0,
  ),
  CategoryCardData(
    label: 'Smart Tech',
    icon: Icons.devices_other_rounded,
    heroImage:
        'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=900&q=80',
    productCount: 0,
  ),
  CategoryCardData(
    label: 'Health & Wellness',
    icon: Icons.health_and_safety,
    heroImage:
        'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&w=900&q=80',
    productCount: 0,
  ),
  CategoryCardData(
    label: 'Beauty & Care',
    icon: Icons.face_5,
    heroImage:
        'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=900&q=80',
    productCount: 0,
  ),
  CategoryCardData(
    label: 'Home & Decor',
    icon: Icons.other_houses,
    heroImage:
        'https://images.unsplash.com/photo-1493666438817-866a91353ca9?auto=format&fit=crop&w=900&q=80',
    productCount: 0,
  ),
  CategoryCardData(
    label: 'Accessories',
    icon: Icons.watch,
    heroImage:
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?auto=format&fit=crop&w=900&q=80',
    productCount: 0,
  ),
];
