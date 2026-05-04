import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';

import '../models/catalogue_page.dart';
import '../services/api_client.dart';

class ProductCatalogueScreen extends StatefulWidget {
  const ProductCatalogueScreen({super.key});

  static const routeName = '/product-catalogue';

  @override
  State<ProductCatalogueScreen> createState() => _ProductCatalogueScreenState();
}

class _ProductCatalogueScreenState extends State<ProductCatalogueScreen> {
  final GlobalKey<PageFlipWidgetState> _pageFlipKey = GlobalKey<PageFlipWidgetState>();
  final ApiClient _apiClient = ApiClient.instance;
  late Future<List<CataloguePage>> _catalogueFuture;

  void _reloadCatalogue() {
    setState(() {
      _catalogueFuture = _fetchCataloguePages();
    });
  }

  @override
  void initState() {
    super.initState();
    _catalogueFuture = _fetchCataloguePages();
  }

  Future<List<CataloguePage>> _fetchCataloguePages() async {
    final response = await _apiClient.fetchCataloguePages(limit: 40, isActive: true);
    final pages = List<CataloguePage>.from(response.data);
    pages.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Product Catalogue'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _reloadCatalogue,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: FutureBuilder<List<CataloguePage>>(
            future: _catalogueFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _CatalogueError(
                  message: snapshot.error.toString(),
                  onRetry: _reloadCatalogue,
                );
              }

              final pages = snapshot.data ?? const [];
              if (pages.isEmpty) {
                return _CatalogueEmpty(onRetry: _reloadCatalogue);
              }

              return _CatalogueViewer(pageFlipKey: _pageFlipKey, pages: pages);
            },
          ),
        ),
      ),
    );
  }
}

class _CatalogueViewer extends StatelessWidget {
  const _CatalogueViewer({required this.pageFlipKey, required this.pages});

  final GlobalKey<PageFlipWidgetState> pageFlipKey;
  final List<CataloguePage> pages;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: PageFlipWidget(
          key: pageFlipKey,
          backgroundColor: Theme.of(context).colorScheme.surface,
          initialIndex: 0,
          duration: const Duration(milliseconds: 650),
          children: pages
              .map((page) => _CataloguePage(imageUrl: page.imageUrl, title: page.title))
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _CataloguePage extends StatelessWidget {
  const _CataloguePage({required this.imageUrl, required this.title});

  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xCC000000), Colors.transparent],
                    ),
                  ),
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogueEmpty extends StatelessWidget {
  const _CatalogueEmpty({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade500),
        const SizedBox(height: 16),
        Text(
          'No catalogue pages yet',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Reload'),
        ),
      ],
    );
  }
}

class _CatalogueError extends StatelessWidget {
  const _CatalogueError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
        const SizedBox(height: 16),
        Text(
          'Failed to load catalogue',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ],
    );
  }
}
