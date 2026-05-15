import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../models/event_media_item.dart';
import '../models/social_link.dart';
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
  List<SocialLink> _socialLinks = const [];
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

  List<dynamic> get _allFilteredItems {
    try {
      final query = _searchQuery.toLowerCase();
      
      debugPrint('Filtering items: mediaCount=${_rawItems.length}, socialCount=${_socialLinks.length}');

      final filteredMedia = _rawItems.where((item) {
        // Show if it's a video OR if it has a video-like category
        final isVideo = item.isVideo;
        if (!isVideo) return false;

        final matchesSearch =
            query.isEmpty || item.title.toLowerCase().contains(query);
        final matchesCategory = _selectedCategories.isEmpty ||
            _selectedCategories.contains(item.categoryLabel);
        return matchesSearch && matchesCategory;
      }).toList();

      final filteredSocial = _socialLinks.where((link) {
        // Show if it has any URL
        final hasUrl = link.link.trim().isNotEmpty;
        if (!hasUrl) return false;

        final matchesSearch = query.isEmpty ||
            (link.title?.toLowerCase().contains(query) ?? false) ||
            link.platform.toLowerCase().contains(query);
        return matchesSearch;
      }).toList();

      final all = [...filteredSocial, ...filteredMedia];
      debugPrint('Final filtered count: ${all.length}');
      return all;
    } catch (e, st) {
      debugPrint('Error in _allFilteredItems: $e');
      debugPrint('$st');
      return [];
    }
  }

  Set<String> get _availableCategories {
    final derived = _rawItems
        .where((item) => item.isVideo)
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
      // Load both in parallel but handle them as they come
      _apiClient.fetchEventMedia(
        page: 1,
        limit: 50,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        sort: 'recent',
      ).then((mediaResponse) {
        if (!mounted) return;
        setState(() {
          _rawItems = mediaResponse.items;
          _meta = mediaResponse.meta;
          // If social links are also done (or not needed), stop loading
          if (_socialLinks.isNotEmpty || _isLoading == false) {
             _isLoading = false;
          }
        });
      }).catchError((error) {
        debugPrint('Media fetch error: $error');
      });

      _apiClient.fetchSocialLinks().then((socialLinks) {
        if (!mounted) return;
        setState(() {
          _socialLinks = socialLinks;
          _isLoading = false; // Social links are usually faster/smaller
        });
      }).catchError((error) {
        debugPrint('Social links fetch error: $error');
        if (!mounted) return;
        setState(() => _isLoading = false);
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
    _launchUrl(item.fileUrl);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _allFilteredItems;
    final totalCount = items.length;

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
                      : items.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.video_library_outlined,
                                      size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  const Text('No videos found',
                                      style: TextStyle(
                                          color: Colors.black54, fontSize: 16)),
                                ],
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
                              if (item is SocialLink) {
                                return _SocialLinkCard(
                                  link: item,
                                  onTap: () => _launchUrl(item.link),
                                );
                              }
                              return _MediaCard(
                                item: item as EventMediaItem,
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

class _SocialLinkCard extends StatelessWidget {
  const _SocialLinkCard({required this.link, required this.onTap});
  final SocialLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.black,
                      child: _SocialVideoEmbed(link: link.link),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              link.isYouTube 
                                ? Icons.play_circle_fill 
                                : link.isFacebook 
                                  ? Icons.facebook 
                                  : Icons.camera_alt,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              link.platform.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          link.title ?? link.platform,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Featured Video',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: theme.colorScheme.primary,
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

class _SocialVideoEmbed extends StatefulWidget {
  const _SocialVideoEmbed({required this.link});
  final String link;

  @override
  State<_SocialVideoEmbed> createState() => _SocialVideoEmbedState();
}

class _SocialVideoEmbedState extends State<_SocialVideoEmbed> {
  late String _viewId;
  late String _embedUrl;

  @override
  void initState() {
    super.initState();
    _setupEmbed();
  }

  @override
  void didUpdateWidget(_SocialVideoEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.link != widget.link) {
      _setupEmbed();
    }
  }

  void _setupEmbed() {
    if (!kIsWeb) return;
    
    _viewId = 'social-video-${widget.link.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    _embedUrl = _getEmbedUrl(widget.link);

    // IFrame registration is handled here only for web to avoid compilation errors on mobile
    // In a real multi-platform app, you would use conditional exports for this
  }

  String _getEmbedUrl(String url) {
    try {
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        final videoId = _extractYoutubeId(url);
        if (videoId.isEmpty) return url;
        // Added autoplay=1, mute=1, and other params for a better experience
        return 'https://www.youtube.com/embed/$videoId?autoplay=1&mute=1&rel=0&modestbranding=1&controls=1&showinfo=0';
      } else if (url.contains('facebook.com')) {
        // Facebook video embed with autoplay
        return 'https://www.facebook.com/plugins/video.php?href=${Uri.encodeComponent(url)}&show_text=0&width=560&autoplay=true&mute=true';
      } else if (url.contains('instagram.com')) {
        final cleanUrl = url.split('?').first;
        final base = cleanUrl.endsWith('/') ? cleanUrl : '$cleanUrl/';
        return '${base}embed';
      }
    } catch (e) {
      debugPrint('Error parsing embed URL: $e');
    }
    return url;
  }

  String _extractYoutubeId(String url) {
    final regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    if (match != null && match.group(7) != null && match.group(7)!.length == 11) {
      return match.group(7)!;
    }
    
    // Try short format youtu.be/ID
    if (url.contains('youtu.be/')) {
      final parts = url.split('youtu.be/');
      if (parts.length > 1) {
        return parts[1].split('?').first.split('/').first;
      }
    }
    
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.web_asset_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Video embedding is only available on Web.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => launchUrl(Uri.parse(widget.link)),
              child: const Text('Open in Browser'),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink(); // This part would need conditional imports to work properly on web
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
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.black,
                      child: item.isVideo
                          ? _InlineVideoPlayer(
                              url: item.fileUrl, thumbnail: item.thumbOrFile)
                          : Image.network(item.thumbOrFile ?? item.fileUrl,
                              fit: BoxFit.cover),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.isVideo ? Icons.videocam : Icons.image,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.isVideo ? 'VIDEO' : 'IMAGE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (item.isVideo)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.volume_off, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'MUTED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (item.categoryLabel.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              item.categoryLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: theme.colorScheme.primary,
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
