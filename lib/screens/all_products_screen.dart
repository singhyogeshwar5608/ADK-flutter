import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/product_entry.dart';
import '../state/product_catalog_state.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';
import 'product_details_screen.dart';

enum ProductSort { priceLowHigh, priceHighLow, rating }

class _FilterResult {
  const _FilterResult({
    required this.brands,
    required this.categories,
    required this.priceRange,
  });

  final Set<String> brands;
  final Set<String> categories;
  final RangeValues priceRange;
}

enum _FilterSheetPage { main, brand, category }

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.entries,
    required this.initialBrands,
    required this.initialCategories,
    required this.initialPriceRange,
  });

  final List<ProductCatalogEntry> entries;
  final Set<String> initialBrands;
  final Set<String> initialCategories;
  final RangeValues initialPriceRange;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final List<String> _availableBrands;
  late final List<String> _availableCategories;

  _FilterSheetPage _page = _FilterSheetPage.main;
  late RangeValues _priceRange;
  late Set<String> _selectedBrands;
  late Set<String> _selectedCategories;
  final TextEditingController _brandSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _availableBrands = <String>{
      for (final entry in widget.entries) entry.brand,
    }.toList()
      ..sort();
    _availableCategories = <String>{
      for (final entry in widget.entries) entry.category,
    }.toList()
      ..sort();
    _priceRange = widget.initialPriceRange;
    _selectedBrands = Set<String>.from(widget.initialBrands);
    _selectedCategories = Set<String>.from(widget.initialCategories);
  }

  @override
  void dispose() {
    _brandSearchController.dispose();
    super.dispose();
  }

  List<String> get _filteredBrands {
    final query = _brandSearchController.text.trim().toLowerCase();
    if (query.isEmpty) return _availableBrands;
    return _availableBrands
        .where((brand) => brand.toLowerCase().contains(query))
        .toList();
  }

  void _goTo(_FilterSheetPage page) => setState(() => _page = page);

  void _clearAll() {
    setState(() {
      _priceRange = const RangeValues(0, 10000);
      _selectedBrands.clear();
      _selectedCategories.clear();
    });
  }

  void _clearBrands() => setState(() => _selectedBrands.clear());

  void _clearCategories() => setState(() => _selectedCategories.clear());

  int get _appliedCount {
    var count = 0;
    if (_selectedBrands.isNotEmpty) count++;
    if (_selectedCategories.isNotEmpty) count++;
    if (_priceRange.start > 0 || _priceRange.end < 10000) count++;
    return count;
  }

  int get _matchingProductsCount {
    return widget.entries.where((entry) {
      final price = entry.product.price;
      final matchesPrice =
          price >= _priceRange.start && price <= _priceRange.end;
      final matchesBrand =
          _selectedBrands.isEmpty || _selectedBrands.contains(entry.brand);
      final matchesCategory = _selectedCategories.isEmpty ||
          _selectedCategories.contains(entry.category);
      return matchesPrice && matchesBrand && matchesCategory;
    }).length;
  }

  void _applyAndClose() {
    Navigator.of(context).pop(_FilterResult(
      brands: _selectedBrands,
      categories: _selectedCategories,
      priceRange: _priceRange,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBrandPage = _page == _FilterSheetPage.brand;
    final isCategoryPage = _page == _FilterSheetPage.category;
    final leftLabel = isBrandPage
        ? 'Clear filter'
        : isCategoryPage
            ? 'Clear filter'
            : 'Clear all ($_appliedCount)';
    final rightLabel = 'Show ${_matchingProductsCount.toString()}';
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.96),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 30,
                    offset: Offset(0, -10)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FilterSheetHeader(
                      page: _page,
                      onClose: () => Navigator.of(context).maybePop(),
                      onBack: () => _goTo(_FilterSheetPage.main),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) =>
                            SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(
                                _page == _FilterSheetPage.main ? 0.2 : -0.2, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child:
                              FadeTransition(opacity: animation, child: child),
                        ),
                        child: _buildActivePage(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FilterSheetActions(
                      leftLabel: leftLabel,
                      rightLabel: rightLabel,
                      onClear: isBrandPage
                          ? _clearBrands
                          : isCategoryPage
                              ? _clearCategories
                              : _clearAll,
                      onApply: _applyAndClose,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivePage() {
    switch (_page) {
      case _FilterSheetPage.main:
        return _FilterMainView(
          key: const ValueKey('main'),
          priceRange: _priceRange,
          onPriceChanged: (value) => setState(() => _priceRange = value),
          onShowCategory: () => _goTo(_FilterSheetPage.category),
          onShowBrand: () => _goTo(_FilterSheetPage.brand),
        );
      case _FilterSheetPage.brand:
        return _BrandFilterView(
          key: const ValueKey('brand'),
          controller: _brandSearchController,
          filteredBrands: _filteredBrands,
          selected: _selectedBrands,
          onSearch: (_) => setState(() {}),
          onToggle: (brand) {
            setState(() {
              if (!_selectedBrands.add(brand)) {
                _selectedBrands.remove(brand);
              }
            });
          },
        );
      case _FilterSheetPage.category:
        return _CategoryFilterView(
          key: const ValueKey('category'),
          categories: _availableCategories,
          selected: _selectedCategories,
          onToggle: (category) {
            setState(() {
              if (!_selectedCategories.add(category)) {
                _selectedCategories.remove(category);
              }
            });
          },
        );
    }
  }
}

class _FilterSheetHeader extends StatelessWidget {
  const _FilterSheetHeader({
    required this.page,
    required this.onClose,
    required this.onBack,
  });

  final _FilterSheetPage page;
  final VoidCallback onClose;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showBack = page != _FilterSheetPage.main;
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: showBack
              ? IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          child: Text(
            page == _FilterSheetPage.main
                ? 'Filter'
                : page == _FilterSheetPage.brand
                    ? 'Brand'
                    : 'Category',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          width: 48,
          child: IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}

class _FilterMainView extends StatelessWidget {
  const _FilterMainView({
    super.key,
    required this.priceRange,
    required this.onPriceChanged,
    required this.onShowCategory,
    required this.onShowBrand,
  });

  final RangeValues priceRange;
  final ValueChanged<RangeValues> onPriceChanged;
  final VoidCallback onShowCategory;
  final VoidCallback onShowBrand;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _FilterOptionTile(
            label: 'Category',
            subtitle: 'Skincare · Hair · Personal care',
            onTap: onShowCategory,
          ),
          const SizedBox(height: 12),
          _PriceRangeCard(values: priceRange, onChanged: onPriceChanged),
        ],
      ),
    );
  }
}

class _FilterOptionTile extends StatelessWidget {
  const _FilterOptionTile({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceRangeCard extends StatelessWidget {
  const _PriceRangeCard({required this.values, required this.onChanged});

  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
              '₹${values.start.toStringAsFixed(0)} - ₹${values.end.toStringAsFixed(0)}',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF0F9A6B),
              inactiveTrackColor: theme.dividerColor.withValues(alpha: 0.4),
              rangeThumbShape:
                  const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
              thumbColor: Colors.white,
              overlayColor: const Color(0x330F9A6B),
            ),
            child: RangeSlider(
              values: RangeValues(
                values.start.clamp(0, 10000),
                values.end.clamp(0, 10000),
              ),
              min: 0,
              max: 10000,
              divisions: 50,
              labels: RangeLabels(
                '₹${values.start.clamp(0, 10000).toStringAsFixed(0)}',
                '₹${values.end.clamp(0, 10000).toStringAsFixed(0)}',
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandFilterView extends StatelessWidget {
  const _BrandFilterView({
    super.key,
    required this.controller,
    required this.filteredBrands,
    required this.selected,
    required this.onSearch,
    required this.onToggle,
  });

  final TextEditingController controller;
  final List<String> filteredBrands;
  final Set<String> selected;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Search brand',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
          ),
          onChanged: onSearch,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            itemCount: filteredBrands.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final brand = filteredBrands[index];
              final isSelected = selected.contains(brand);
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (_) => onToggle(brand),
                  title: Text(brand),
                  activeColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryFilterView extends StatelessWidget {
  const _CategoryFilterView({
    super.key,
    required this.categories,
    required this.selected,
    required this.onToggle,
  });

  final List<String> categories;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxChipWidth = (constraints.maxWidth - 12) / 2;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            children: [
              for (final category in categories)
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: maxChipWidth.clamp(0, constraints.maxWidth)),
                  child: FilterChip(
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(category, overflow: TextOverflow.ellipsis),
                    ),
                    selected: selected.contains(category),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    selectedColor:
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                    checkmarkColor: theme.colorScheme.primary,
                    onSelected: (_) => onToggle(category),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterSheetActions extends StatelessWidget {
  const _FilterSheetActions({
    required this.leftLabel,
    required this.rightLabel,
    required this.onClear,
    required this.onApply,
  });

  final String leftLabel;
  final String rightLabel;
  final VoidCallback onClear;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              side:
                  BorderSide(color: theme.dividerColor.withValues(alpha: 0.6)),
            ),
            child: Text(leftLabel, style: theme.textTheme.labelLarge),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: onApply,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
            ),
            child: Text(rightLabel,
                style:
                    theme.textTheme.labelLarge?.copyWith(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  static const routeName = '/products';

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedBrands = {};
  Set<String> _selectedCategories = {};
  RangeValues _priceRange = const RangeValues(0, 10000);

  List<ProductCatalogEntry> _applyFilters(List<ProductCatalogEntry> entries) {
    final searchQuery = _searchController.text.trim().toLowerCase();
    return entries.where((entry) {
      final price = entry.product.price;
      final matchesPrice =
          price >= _priceRange.start && price <= _priceRange.end;
      final matchesBrand =
          _selectedBrands.isEmpty || _selectedBrands.contains(entry.brand);
      final matchesCategory = _selectedCategories.isEmpty ||
          _selectedCategories.contains(entry.category);
      final matchesSearch = searchQuery.isEmpty ||
          entry.product.title.toLowerCase().contains(searchQuery) ||
          entry.category.toLowerCase().contains(searchQuery);
      return matchesPrice && matchesBrand && matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _openFilterSheet(List<ProductCatalogEntry> entries) async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.45,
        child: _FilterSheet(
          entries: List<ProductCatalogEntry>.from(entries),
          initialBrands: _selectedBrands,
          initialCategories: _selectedCategories,
          initialPriceRange: _priceRange,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedBrands = result.brands;
        _selectedCategories = result.categories;
        _priceRange = result.priceRange;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalogState = ProductCatalogProvider.of(context);
    final sourceEntries = catalogState.entries;
    final entries = _applyFilters(sourceEntries);
    final isLoading = catalogState.isLoading && sourceEntries.isEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      bottomNavigationBar: const _ProductsFooterNav(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              leadingWidth: 56,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: () => _openFilterSheet(sourceEntries),
                  ),
                ),
              ],
              title: Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    height: 40,
                    width: double.infinity,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search product name or category',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) - 3),
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) - 2),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              sliver: SliverToBoxAdapter(
                child: Builder(builder: (context) {
                  if (isLoading) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator()));
                  }
                  if (entries.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Text(
                        'No products match your filters yet.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      const spacing = 16.0;
                      final itemWidth = (availableWidth - spacing) / 2;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final entry in entries)
                            SizedBox(
                              width: itemWidth,
                              child: _ProductTile(entry: entry),
                            ),
                        ],
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsFooterNav extends StatelessWidget {
  const _ProductsFooterNav();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
              top:
                  BorderSide(color: theme.dividerColor.withValues(alpha: 0.6))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FooterNavItem(
              icon: Icons.home_filled,
              label: 'Home',
              onTap: () => Navigator.of(context).pushReplacementNamed('/'),
            ),
            _FooterNavItem(
              icon: Icons.favorite_border,
              label: 'Wishlist',
              onTap: () =>
                  Navigator.of(context).pushNamed(WishlistScreen.routeName),
            ),
            _FooterNavItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Cart',
              onTap: () =>
                  Navigator.of(context).pushNamed(CartScreen.routeName),
            ),
            _FooterNavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () =>
                  Navigator.of(context).pushNamed(ProfileScreen.routeName),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterNavItem extends StatelessWidget {
  const _FooterNavItem(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.onSurface),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.entry});

  final ProductCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(product: entry.product),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.sell_outlined,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      entry.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ProductCard(
          product: entry.product,
          rating: entry.rating,
          onProductTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: entry.product),
            ),
          ),
        ),
      ],
    );
  }
}
