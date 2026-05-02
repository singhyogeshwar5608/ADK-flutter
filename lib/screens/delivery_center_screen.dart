import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/delivery_center.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class DeliveryCenterScreen extends StatefulWidget {
  const DeliveryCenterScreen({super.key});

  static const routeName = '/delivery-center';

  @override
  State<DeliveryCenterScreen> createState() => _DeliveryCenterScreenState();
}

class _DeliveryCenterScreenState extends State<DeliveryCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiClient _apiClient = ApiClient.instance;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isError = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedLocation = '';
  List<DeliveryCenter> _deliveryCenters = [];
  DeliveryCenterMeta? _meta;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadDeliveryCenters(initial: true);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final newQuery = _searchController.text.trim();
      if (newQuery != _searchQuery) {
        setState(() {
          _searchQuery = newQuery;
        });
        _loadDeliveryCenters(initial: true);
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (currentScroll >= maxScroll - 200 && !_isLoadingMore && _meta != null) {
      if (_meta!.page < _meta!.pages) {
        _loadDeliveryCenters(loadMore: true);
      }
    }
  }

  Future<void> _loadDeliveryCenters({
    bool initial = false,
    bool loadMore = false,
  }) async {
    if (initial) {
      setState(() {
        _isLoading = true;
        _isError = false;
        _errorMessage = null;
        if (!loadMore) {
          _deliveryCenters = [];
        }
      });
    } else if (loadMore) {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final page = loadMore ? (_meta?.page ?? 0) + 1 : 1;
      final response = await _apiClient.getDeliveryCenters(
        page: page,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        location: _selectedLocation.isNotEmpty ? _selectedLocation : null,
      );

      setState(() {
        if (loadMore) {
          _deliveryCenters.addAll(response.data);
        } else {
          _deliveryCenters = response.data;
        }
        _meta = response.meta;
        _isLoading = false;
        _isLoadingMore = false;
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _isError = true;

        // Handle authentication errors specifically
        if (e.toString().contains('401') ||
            e.toString().contains('Unauthorized') ||
            e.toString().contains('Not authenticated')) {
          _errorMessage =
              'Authentication required. Please login to access delivery centers.';
        } else {
          _errorMessage = e.toString();
        }
      });
    }
  }

  Future<void> _refresh() async {
    await _loadDeliveryCenters(initial: true);
  }

  void _callDeliveryCenter(String mobileNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: mobileNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _buildFilterCountText() {
    final totalCenters = _meta?.total ?? _deliveryCenters.length;
    final currentPageCount = _deliveryCenters.length;
    final hasSearch = _searchQuery.isNotEmpty;
    final hasLocation = _selectedLocation.isNotEmpty;

    if (!hasSearch && !hasLocation) {
      return 'Showing all $totalCenters delivery centers';
    }

    final filters = <String>[];
    if (hasSearch) filters.add('search: "$_searchQuery"');
    if (hasLocation) filters.add('location: $_selectedLocation');

    final filterText = filters.join(', ');

    // If we have pagination and showing less than total
    if (currentPageCount < totalCenters) {
      return 'Showing $currentPageCount of $totalCenters centers filtered by $filterText';
    }

    return 'Found $totalCenters centers filtered by $filterText';
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedLocation = '';
      _searchController.clear();
    });
    _loadDeliveryCenters(initial: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Delivery Centers',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search delivery centers...',
                  prefixIcon:
                      Icon(Icons.search, color: theme.colorScheme.outline),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Location Filter
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedLocation.isEmpty ? null : _selectedLocation,
                decoration: InputDecoration(
                  hintText: 'Filter by location/state...',
                  prefixIcon:
                      Icon(Icons.location_on, color: theme.colorScheme.outline),
                  suffixIcon: _selectedLocation.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _selectedLocation = '';
                            });
                            _loadDeliveryCenters(initial: true);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Andhra Pradesh', child: Text('Andhra Pradesh')),
                  DropdownMenuItem(
                      value: 'Arunachal Pradesh',
                      child: Text('Arunachal Pradesh')),
                  DropdownMenuItem(value: 'Assam', child: Text('Assam')),
                  DropdownMenuItem(value: 'Bihar', child: Text('Bihar')),
                  DropdownMenuItem(
                      value: 'Chhattisgarh', child: Text('Chhattisgarh')),
                  DropdownMenuItem(value: 'Goa', child: Text('Goa')),
                  DropdownMenuItem(value: 'Gujarat', child: Text('Gujarat')),
                  DropdownMenuItem(value: 'Haryana', child: Text('Haryana')),
                  DropdownMenuItem(
                      value: 'Himachal Pradesh',
                      child: Text('Himachal Pradesh')),
                  DropdownMenuItem(
                      value: 'Jharkhand', child: Text('Jharkhand')),
                  DropdownMenuItem(
                      value: 'Karnataka', child: Text('Karnataka')),
                  DropdownMenuItem(value: 'Kerala', child: Text('Kerala')),
                  DropdownMenuItem(
                      value: 'Madhya Pradesh', child: Text('Madhya Pradesh')),
                  DropdownMenuItem(
                      value: 'Maharashtra', child: Text('Maharashtra')),
                  DropdownMenuItem(value: 'Manipur', child: Text('Manipur')),
                  DropdownMenuItem(
                      value: 'Meghalaya', child: Text('Meghalaya')),
                  DropdownMenuItem(value: 'Mizoram', child: Text('Mizoram')),
                  DropdownMenuItem(value: 'Nagaland', child: Text('Nagaland')),
                  DropdownMenuItem(value: 'Odisha', child: Text('Odisha')),
                  DropdownMenuItem(value: 'Punjab', child: Text('Punjab')),
                  DropdownMenuItem(
                      value: 'Rajasthan', child: Text('Rajasthan')),
                  DropdownMenuItem(value: 'Sikkim', child: Text('Sikkim')),
                  DropdownMenuItem(
                      value: 'Tamil Nadu', child: Text('Tamil Nadu')),
                  DropdownMenuItem(
                      value: 'Telangana', child: Text('Telangana')),
                  DropdownMenuItem(value: 'Tripura', child: Text('Tripura')),
                  DropdownMenuItem(
                      value: 'Uttar Pradesh', child: Text('Uttar Pradesh')),
                  DropdownMenuItem(
                      value: 'Uttarakhand', child: Text('Uttarakhand')),
                  DropdownMenuItem(
                      value: 'West Bengal', child: Text('West Bengal')),
                  DropdownMenuItem(value: 'Delhi', child: Text('Delhi')),
                  DropdownMenuItem(
                      value: 'Jammu & Kashmir', child: Text('Jammu & Kashmir')),
                  DropdownMenuItem(value: 'Ladakh', child: Text('Ladakh')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value ?? '';
                  });
                  _loadDeliveryCenters(initial: true);
                },
              ),
            ),

            // Filter Results Count
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.mlmGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.mlmGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: AppColors.mlmGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildFilterCountText(),
                      style: const TextStyle(
                        color: AppColors.mlmGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty || _selectedLocation.isNotEmpty)
                    InkWell(
                      onTap: _clearAllFilters,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.mlmGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.clear,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Clear All',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _buildContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_isError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading delivery centers',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_errorMessage?.contains('Authentication required') == true) ...[
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamed('/login'),
                icon: const Icon(Icons.login),
                label: const Text('Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _refresh,
                child: const Text('Try Again'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _refresh,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      );
    }

    if (_deliveryCenters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No delivery centers found'
                  : 'No delivery centers available',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isNotEmpty)
              Text(
                'Try adjusting your search terms',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _deliveryCenters.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _deliveryCenters.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final deliveryCenter = _deliveryCenters[index];
        return _DeliveryCenterCard(
          deliveryCenter: deliveryCenter,
          onCall: () => _callDeliveryCenter(deliveryCenter.mobileNumber),
        );
      },
    );
  }
}

class _DeliveryCenterCard extends StatelessWidget {
  const _DeliveryCenterCard({
    required this.deliveryCenter,
    required this.onCall,
  });

  final DeliveryCenter deliveryCenter;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    deliveryCenter.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: deliveryCenter.isActive
                        ? AppColors.mlmGreen
                        : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    deliveryCenter.isActive ? 'Active' : 'Inactive',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Owner Name
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Owner',
              value: deliveryCenter.ownerName,
              theme: theme,
            ),
            const SizedBox(height: 8),

            // Location
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: deliveryCenter.location,
              theme: theme,
            ),
            const SizedBox(height: 8),

            // Mobile Number with call button
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    deliveryCenter.mobileNumber,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onCall,
                  icon: Icon(
                    Icons.call,
                    color: AppColors.primary,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
