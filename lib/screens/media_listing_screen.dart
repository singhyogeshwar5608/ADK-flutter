import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/event_media_item.dart';
import '../services/api_client.dart';
import '../widgets/social_media_links_bar.dart';

class MediaListingScreen extends StatefulWidget {
  const MediaListingScreen({super.key});

  static const routeName = '/media';

  @override
  State<MediaListingScreen> createState() => _MediaListingScreenState();
}

class _MediaListingScreenState extends State<MediaListingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiClient _apiClient = ApiClient.instance;

  List<EventMediaItem> _rawItems = const [];
  PaginationMeta? _meta;
  String _searchQuery = '';
  Set<String> _selectedCategories = {};
  Timer? _searchDebounce;
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadMedia(initial: true);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  List<EventMediaItem> get _filteredItems {
    final query = _searchQuery.toLowerCase();
    return _rawItems.where((item) {
      final matchesSearch =
          query.isEmpty || item.title.toLowerCase().contains(query);
      final matchesCategory = _selectedCategories.isEmpty ||
          _selectedCategories.contains(item.categoryLabel);
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Set<String> get _availableCategories {
    final derived = _rawItems
        .map((item) => item.categoryLabel.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (derived.isNotEmpty) return derived;
    return {
      'Agriculture',
      'CSR',
      'Footwear',
      'Home Delivery',
      'KeySoul',
      'Product Insider',
    };
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      setState(() => _searchQuery = _searchController.text.trim());
      _loadMedia();
    });
  }

  Future<void> _loadMedia({bool initial = false}) async {
    if (initial) {
      setState(() {
        _isLoading = true;
        _isError = false;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isError = false;
        _errorMessage = null;
      });
    }

    try {
      final response = await _apiClient.fetchEventMedia(
        page: 1,
        limit: 50,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        sort: 'recent',
      );
      if (!mounted) return;
      setState(() {
        _rawItems = response.items;
        _meta = response.meta;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _openFilters() async {
    final categories = _availableCategories.toList()..sort();
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final tempSelection = {..._selectedCategories};
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Filters',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w700)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 320,
                      child: Row(
                        children: [
                          Container(
                            width: 120,
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.06),
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Categories',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700)),
                                SizedBox(height: 8),
                                Text('Choose segments',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              itemCount: categories.length,
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                final checked =
                                    tempSelection.contains(category);
                                return CheckboxListTile(
                                  value: checked,
                                  title: Text(category),
                                  onChanged: (value) {
                                    setSheetState(() {
                                      if (value == true) {
                                        tempSelection.add(category);
                                      } else {
                                        tempSelection.remove(category);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setSheetState(() => tempSelection.clear());
                            },
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('Reset'),
                          ),
                          const Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: const StadiumBorder(),
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 12),
                            ),
                            onPressed: () =>
                                Navigator.of(context).pop(tempSelection),
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() => _selectedCategories = result);
    }
  }

  void _resetFilters() {
    setState(() => _selectedCategories.clear());
  }

  void _openMediaPreview(EventMediaItem item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _MediaPreviewDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final totalCount = _meta?.total ?? _rawItems.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Media',
                                style: TextStyle(
                                    fontSize: 19, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('$totalCount Items found',
                                style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SocialMediaLinksBar(),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 4,
                      itemBuilder: (_, index) => Container(
                        height: 220,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    )
                  : _isError
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.wifi_off,
                                    size: 42, color: Colors.redAccent),
                                const SizedBox(height: 12),
                                Text(
                                  'Unable to load media',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _errorMessage ??
                                      'Please check your connection and try again.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => _loadMedia(initial: true),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadMedia(initial: true),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return _MediaCard(
                                item: item,
                                onTap: () => _openMediaPreview(item),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedCategories.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Reset filters'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MediaCard extends StatefulWidget {
  const _MediaCard({required this.item, required this.onTap});

  final EventMediaItem item;
  final VoidCallback onTap;

  @override
  State<_MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends State<_MediaCard> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: item.isVideo
                        ? _InlineVideoPlayer(
                            url: item.fileUrl, thumbnail: item.thumbOrFile)
                        : Image.network(item.thumbOrFile ?? item.fileUrl,
                            fit: BoxFit.cover),
                  ),
                ),
                if (item.isVideo)
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.volume_off,
                                size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Auto-play',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  if (item.categoryLabel.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.categoryLabel,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  const _InlineVideoPlayer({required this.url, this.thumbnail});

  final String url;
  final String? thumbnail;

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  @override
  void didUpdateWidget(covariant _InlineVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller?.dispose();
      _setupController();
    }
  }

  void _setupController() {
    if (widget.url.isEmpty) return;
    final uri = Uri.tryParse(widget.url);
    if (uri == null) {
      _hasError = true;
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri)
      ..setLooping(true)
      ..setVolume(0);
    _initializeFuture = controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _hasError = false);
      controller.play();
    }).catchError((error) {
      debugPrint('Inline video failed: $error');
      if (mounted) setState(() => _hasError = true);
    });
    _controller = controller;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _controller == null) {
      return _VideoPlaceholder(thumbnail: widget.thumbnail);
    }

    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        final controller = _controller!;
        if (snapshot.connectionState == ConnectionState.done &&
            controller.value.isInitialized) {
          return GestureDetector(
            onTap: () {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
              setState(() {});
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
                AnimatedOpacity(
                  opacity: controller.value.isPlaying ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Colors.white70,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 30,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return _VideoPlaceholder(thumbnail: widget.thumbnail);
        }

        return Container(
          color: const Color(0xFFE2E8F0),
          child:
              const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
        );
      },
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({this.thumbnail});

  final String? thumbnail;

  @override
  Widget build(BuildContext context) {
    if (thumbnail != null && thumbnail!.isNotEmpty) {
      return Image.network(
        thumbnail!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback,
      );
    }
    return _fallback;
  }

  Widget get _fallback => Container(
        color: const Color(0xFFE2E8F0),
        alignment: Alignment.center,
        child: const Icon(Icons.videocam_off, size: 32, color: Colors.black45),
      );
}

class _MediaPreviewDialog extends StatefulWidget {
  const _MediaPreviewDialog({required this.item});

  final EventMediaItem item;

  @override
  State<_MediaPreviewDialog> createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<_MediaPreviewDialog> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;

  @override
  void initState() {
    super.initState();
    if (widget.item.isVideo) {
      final uri = Uri.tryParse(widget.item.fileUrl);
      if (uri != null) {
        final controller = VideoPlayerController.networkUrl(uri)
          ..setLooping(true)
          ..setVolume(1);
        _initializeFuture = controller.initialize().then((_) {
          if (mounted) {
            setState(() {});
            controller.play();
          }
        });
        _controller = controller;
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: widget.item.isVideo
                  ? _buildVideo()
                  : Image.network(
                      widget.item.thumbOrFile ?? widget.item.fileUrl,
                      fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 18)),
                if (widget.item.description != null &&
                    widget.item.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(widget.item.description!,
                        style: const TextStyle(color: Colors.black54)),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideo() {
    final controller = _controller;
    if (controller == null) {
      return _VideoPlaceholder(thumbnail: widget.item.thumbOrFile);
    }

    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            controller.value.isInitialized) {
          return Stack(
            children: [
              Positioned.fill(child: VideoPlayer(controller)),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        shape: const CircleBorder(),
                      ),
                      icon: Icon(
                          controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white),
                      onPressed: () {
                        setState(() {
                          if (controller.value.isPlaying) {
                            controller.pause();
                          } else {
                            controller.play();
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                            playedColor: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return _VideoPlaceholder(thumbnail: widget.item.thumbOrFile);
        }

        return Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: Colors.white),
        );
      },
    );
  }
}
