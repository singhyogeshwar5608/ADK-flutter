import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/product_entry.dart';
import '../state/product_catalog_state.dart';
import '../state/profile_state.dart';
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
      List<ProductCatalogEntry> source,
      List<Category> remoteCategories) {
    final profileState = ProfileProvider.of(context);
    final isPartner = profileState.isAuthenticated && profileState.data.partnerId.trim().isNotEmpty;

    final baseFiltered = source.where((entry) {
      if (entry.product.isMlm && !isPartner) {
        return false;
      }
      return true;
    }).toList();

    final categoryFiltered = _selectedCategory == _allCategory
        ? baseFiltered
        : () {
            final selectedName = _selectedCategory.trim().toLowerCase();
            final matchIds = <String>{};
            final matchNames = <String>{selectedName};
            final matchSlugs = <String>{};
            for (final cat in remoteCategories) {
              final name = cat.name.trim().toLowerCase();
              if (name == selectedName) {
                matchIds.add(cat.id.toString());
                matchSlugs.add(cat.slug.trim().toLowerCase());
              }
            }
            return baseFiltered.where((entry) {
              final entryCat = entry.category.trim().toLowerCase();
              if (matchNames.contains(entryCat)) return true;
              if (matchSlugs.contains(entryCat)) return true;
              if (matchIds.contains(entryCat)) return true;
              return false;
            }).toList();
          }();

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

  bool _matchesCategory(ProductCatalogEntry entry, String categoryLabel, List<Category> remoteCategories) {
    final entryCat = entry.category.trim().toLowerCase();
    final label = categoryLabel.trim().toLowerCase();
    if (entryCat == label) return true;
    if (entryCat == categoryLabel.trim().toLowerCase()) return true;
    for (final cat in remoteCategories) {
      if (cat.name.trim().toLowerCase() == label) {
        if (entryCat == cat.id.toString()) return true;
        if (entryCat == cat.slug.trim().toLowerCase()) return true;
      }
    }
    return false;
  }

  int _countProductsFor(
      String categoryLabel, List<ProductCatalogEntry> source, List<Category> remoteCategories) {
    final profileState = ProfileProvider.of(context);
    final isPartner = profileState.isAuthenticated && profileState.data.partnerId.trim().isNotEmpty;

    final filteredSource = source.where((entry) {
      if (entry.product.isMlm && !isPartner) return false;
      return true;
    });

    if (categoryLabel == _allCategory) return filteredSource.length;
    return filteredSource.where((entry) => _matchesCategory(entry, categoryLabel, remoteCategories)).length;
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
        productCount: _countProductsFor(_allCategory, source, remoteCategories),
      ),
    ];

    if (remoteCategories.isEmpty) {
      cards.add(CategoryCardData(
        label: 'No categories yet uploaded from admin panel',
        icon: Icons.inbox_outlined,
        heroImage: '',
        productCount: 0,
      ));
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
        productCount: _countProductsFor(label, source, remoteCategories),
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
    final filteredProducts = _filteredProducts(sourceEntries, remoteCategories);
    final categoriesWithCounts =
        _buildCategoryCards(remoteCategories, sourceEntries);
    final isLoading = catalogState.isLoading && sourceEntries.isEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBody: false,
      bottomNavigationBar: const BottomNavBar(),
      body: RefreshIndicator(
          onRefresh: catalogState.refresh,
          displacement: 20,
          color: theme.colorScheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              HeaderSliver(
                searchController: _searchController,
                searchQuery: _searchQuery,
                onClearSearch: _clearSearchInput,
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HeroBanner(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: CategorySlider(
                        categories: categoriesWithCounts,
                        selectedCategory: _selectedCategory,
                        onCategorySelected: (category) {
                          setState(() => _selectedCategory = category.label);
                        },
                        onViewAllTap: () => Navigator.of(context)
                            .pushNamed(AllProductsScreen.routeName),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
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
              padding: const EdgeInsets.fromLTRB(11, 12, 11, 25),
              sliver: SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    const spacing = 16.0;
                    final itemWidth = _featuredGridView
                        ? (availableWidth - spacing) / 2
                        : availableWidth;

                    Widget productTile(ProductCatalogEntry entry) {
                      return ProductCard(
                        product: entry.product,
                        rating: entry.rating,
                        onProductTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsScreen(
                                product: entry.product,
                              ),
                            ),
                          );
                        },
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
      toolbarHeight: 68,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: const HeaderWidget(),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SizedBox(
            height: 38,
            child: Builder(
              builder: (context) {
                final th = Theme.of(context);
                final body = th.textTheme.bodyLarge;
                final fs = (body?.fontSize ?? 16) - 3;
                return TextField(
                  controller: searchController,
                  style: body?.copyWith(fontSize: fs, height: 1.15),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search products or brands...',
                    hintStyle: body?.copyWith(
                      fontSize: fs,
                      color: th.colorScheme.onSurface.withValues(alpha: 0.45),
                      height: 1.15,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 40, maxHeight: 38),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Align(
                        alignment: Alignment.center,
                        widthFactor: 1,
                        heightFactor: 1,
                        child: Icon(Icons.search,
                            color: Color(0xFF94A3B8), size: 20),
                      ),
                    ),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            iconSize: 20,
                            icon: const Icon(Icons.close,
                                color: Color(0xFF94A3B8)),
                            onPressed: onClearSearch,
                          ),
                  ),
                );
              },
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected
              ? primary.withValues(alpha: 0.65)
              : Colors.transparent,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 17),
        color: Theme.of(context).colorScheme.onSurface,
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(34, 34),
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
