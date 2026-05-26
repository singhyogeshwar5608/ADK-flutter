import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for web to handle IFrame registration
import '../utils/web_platform_stub.dart'
    if (dart.library.js_interop) '../utils/web_platform_real.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

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

      final filteredMedia = _rawItems.where((item) {
        // Must be a video to show on this screen
        if (!item.isVideo) return false;

        if (query.isNotEmpty && !item.title.toLowerCase().contains(query)) {
          return false;
        }

        if (_selectedCategories.isNotEmpty &&
            !_selectedCategories.contains(item.categoryLabel)) {
          return false;
        }

        return true;
      }).toList();

      final filteredSocial = _socialLinks.where((link) {
        // Show if it has any URL
        if (link.link.trim().isEmpty) return false;

        if (query.isNotEmpty) {
          final matches =
              (link.title?.toLowerCase().contains(query) ?? false) ||
                  link.platform.toLowerCase().contains(query);
          if (!matches) return false;
        }

        return true;
      }).toList();

      return [...filteredSocial, ...filteredMedia];
    } catch (e) {
      debugPrint('Error filtering items: $e');
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
    }

    // Use a counter to track finished requests
    int finishedRequests = 0;
    const totalRequests = 2;

    void checkDone() {
      finishedRequests++;
      if (finishedRequests >= totalRequests && mounted) {
        setState(() => _isLoading = false);
      }
    }

    // Load Media Items
    _apiClient
        .fetchEventMedia(
      page: 1,
      limit: 50,
      sort: 'recent',
      search: _searchQuery.isEmpty ? null : _searchQuery,
    )
        .then((mediaResponse) {
      if (!mounted) return;
      debugPrint('Loaded ${mediaResponse.items.length} raw items from backend');

      // Filter items to ensure we only have videos and handle cases where mediaType might be missing
      final videosOnly = mediaResponse.items.where((item) {
        final isV = item.isVideo;
        debugPrint(
            'Item ID: ${item.id}, Title: ${item.title}, isVideo: $isV, URL: ${item.fileUrl}');
        return isV;
      }).toList();
      debugPrint('Found ${videosOnly.length} items identified as videos');

      setState(() {
        _rawItems = mediaResponse.items; // Keep all for local filtering
        _meta = mediaResponse.meta;
      });
    }).catchError((error) {
      debugPrint('Media fetch error: $error');
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = 'Connection Error: $error';
        });
      }
    }).whenComplete(checkDone);

    // Load Social Links
    _apiClient.fetchSocialLinks().then((socialLinks) {
      if (!mounted) return;
      setState(() {
        _socialLinks = socialLinks;
      });
    }).catchError((error) {
      debugPrint('Social links fetch error: $error');
      // We don't mark as error if only social links fail
    }).whenComplete(checkDone);
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
    if (item.isExternalVideo) {
      _launchUrl(item.fileUrl);
    } else {
      showDialog(
        context: context,
        builder: (context) => _MediaPreviewDialog(item: item),
      );
    }
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
                      ? _buildErrorState()
                      : items.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: () => _loadMedia(initial: true),
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  if (item is SocialLink) {
                                    return _SocialLinkCard(
                                      link: item,
                                      onTap: () => _launchUrl(item.link),
                                    );
                                  } else if (item is EventMediaItem) {
                                    return _MediaCard(
                                      item: item,
                                      onTap: () => _openMediaPreview(item),
                                    );
                                  }
                                  return const SizedBox.shrink();
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Failed to load media',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadMedia(initial: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            const Text(
              'No videos found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'We couldn\'t find any videos matching your filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            if (_selectedCategories.isNotEmpty || _searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategories.clear();
                      _searchController.clear();
                      _searchQuery = '';
                    });
                    _loadMedia();
                  },
                  child: const Text('Clear all filters'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ========================================================
// FACEBOOK HELPERS & PREVIEW (Production Ready)
// ========================================================

bool isFacebookUrl(String url) {
  final lower = url.toLowerCase();
  return lower.contains('facebook.com') || lower.contains('fb.watch');
}

String? getFacebookThumbnail(String url) {
  // Production Note: Facebook thumbnails are restricted without Graph API.
  // We return null to trigger the high-quality fallback UI.
  return null;
}

class _FacebookVideoPreview extends StatefulWidget {
  const _FacebookVideoPreview({required this.url});
  final String url;

  @override
  State<_FacebookVideoPreview> createState() => _FacebookVideoPreviewState();
}

class _FacebookVideoPreviewState extends State<_FacebookVideoPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching FB: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumb = getFacebookThumbnail(widget.url);

    return InkWell(
      onTap: _handleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background / Thumbnail
          if (thumb != null)
            Image.network(thumb, fit: BoxFit.cover)
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1877F2), Color(0xFF0751AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.facebook,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ),

          // Glassmorphism Overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
            ),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Animated Play Button
          Center(
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 40,
                  color: Color(0xFF1877F2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialLinkCard extends StatelessWidget {
  const _SocialLinkCard({required this.link, required this.onTap});
  final SocialLink link;
  final VoidCallback onTap;

  String? get _youtubeThumb {
    if (!link.isYouTube) return null;
    final regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(link.link);
    if (match != null &&
        match.group(7) != null &&
        match.group(7)!.length == 11) {
      final videoId = match.group(7)!;
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumb = _youtubeThumb;

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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.black,
                      child: isFacebookUrl(link.link)
                          ? _FacebookVideoPreview(url: link.link)
                          : _SocialVideoEmbed(link: link.link),
                    ),
                  ),
                ),
                if (thumb != null)
                  const Positioned.fill(
                    child: Center(
                      child: Icon(Icons.play_circle_filled_rounded,
                          size: 54, color: Colors.white70),
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
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.8),
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
  WebViewController? _webController;

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

  @override
  void dispose() {
    _webController = null;
    super.dispose();
  }

  void _setupEmbed() {
    _embedUrl = _getEmbedUrl(widget.link);

    if (kIsWeb) {
      _viewId =
          'social-video-${widget.link.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
      // Register the IFrame using the conditional utility
      registerWebView(_viewId, _embedUrl);
    } else {
      late final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      final controller = WebViewController.fromPlatformCreationParams(params)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(
            "Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.181 Mobile Safari/537.36")
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) {
              // Inject JS to attempt autoplay for Facebook and Instagram
              _webController?.runJavaScript('''
                (function() {
                  function tryPlay() {
                    // Try playing native video elements
                    var videos = document.getElementsByTagName('video');
                    for (var i = 0; i < videos.length; i++) {
                      videos[i].muted = true;
                      videos[i].setAttribute('muted', 'true');
                      videos[i].play().catch(function(e) { console.log('Autoplay blocked:', e); });
                    }
                    
                    // Specific for FB embeds - they often use a specific play button class
                    // var fbPlayButtons = document.querySelectorAll('button[aria-label="Play"], button[title="Play"], ._4-u2 ._4-u3 button, ._s99');
                    // for (var j = 0; j < fbPlayButtons.length; j++) {
                    //   fbPlayButtons[j].click();
                    // }

                    // Instagram specific
                    var igPlayButtons = document.querySelectorAll('article div[role="button"]');
                    for (var k = 0; k < igPlayButtons.length; k++) {
                      if (igPlayButtons[k].innerText.toLowerCase().includes('play')) {
                         igPlayButtons[k].click();
                      }
                    }
                  }
                  
                  // Run multiple times as social embeds load in stages
                  setTimeout(tryPlay, 1000);
                  setTimeout(tryPlay, 2500);
                  setTimeout(tryPlay, 5000);
                })();
              ''');
            },
            onWebResourceError: (error) =>
                debugPrint('Web resource error: ${error.description}'),
          ),
        );

      if (!kIsWeb &&
          (widget.link.contains('facebook.com') ||
              widget.link.contains('fb.watch'))) {
        final cleanUrl = _getCleanFacebookUrl(widget.link);
        final html = '''
<!DOCTYPE html>
<html>

<head>

<meta name="viewport"
content="width=device-width, initial-scale=1.0">

<style>

html, body {
  margin: 0;
  padding: 0;
  background: black;
  overflow: hidden;
  width: 100%;
  height: 100%;
}

#fb-root {
  display: none;
}

.fb-video {
  width: 100%;
  height: 100%;
}

</style>

<script async defer crossorigin="anonymous"
src="https://connect.facebook.net/en_US/sdk.js#xfbml=1&version=v19.0">
</script>

</head>

<body>

<div id="fb-root"></div>

<div class="fb-video"
     data-href="$cleanUrl"
     data-width="500"
     data-show-text="false"
     data-autoplay="true"
     data-allowfullscreen="true">
</div>

</body>
</html>
''';
        controller.loadHtmlString(html, baseUrl: 'https://www.facebook.com');
      } else {
        controller.loadRequest(Uri.parse(_embedUrl));
      }

      // Enable autoplay for social embeds
      final platform = controller.platform;
      if (platform is AndroidWebViewController) {
        platform.setMediaPlaybackRequiresUserGesture(false);
      }

      _webController = controller;
    }
  }

  String _getCleanFacebookUrl(String url) {
    try {
      final uri = Uri.parse(
        url.replaceFirst('m.facebook.com', 'www.facebook.com'),
      );

      // fb.watch support
      if (uri.host.contains('fb.watch')) {
        return url;
      }

      String? videoId;

      // Query parameter se video id
      videoId = uri.queryParameters['v'];

      // Path segments se extract
      if (videoId == null || videoId.isEmpty) {
        final segments = uri.pathSegments.where((e) => e.isNotEmpty).toList();

        for (int i = 0; i < segments.length; i++) {
          if ((segments[i] == 'videos' ||
                  segments[i] == 'reel' ||
                  segments[i] == 'watch') &&
              i + 1 < segments.length) {
            videoId = segments[i + 1];
            break;
          }
        }
      }

      // Stable canonical URL
      if (videoId != null && videoId.isNotEmpty) {
        return 'https://www.facebook.com/video.php?v=$videoId';
      }

      return url;
    } catch (e) {
      debugPrint('Facebook URL parse error: $e');
      return url;
    }
  }

  String _getEmbedUrl(String url) {
    try {
      // =========================
      // YOUTUBE
      // =========================
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        final videoId = _extractYoutubeId(url);

        if (videoId.isEmpty) return url;

        return 'https://www.youtube.com/embed/$videoId'
            '?autoplay=1'
            '&mute=1'
            '&enablejsapi=1'
            '&rel=0'
            '&modestbranding=1'
            '&controls=1'
            '&loop=1'
            '&playlist=$videoId';
      }

      // =========================
      // FACEBOOK
      // =========================
      else if (url.contains('facebook.com') || url.contains('fb.watch')) {
        // =========================
        // BLOCK UNSUPPORTED SHARE URLS
        // =========================
        if (url.contains('/share/r/') || url.contains('/share/v/')) {
          debugPrint(
            'Unsupported Facebook share URL: $url',
          );

          return '''
data:text/html,
<html>
<body style="
background:black;
display:flex;
justify-content:center;
align-items:center;
height:100vh;
color:white;
font-family:sans-serif;
text-align:center;
padding:20px;">

<div>
Facebook share links are not embeddable.
<br><br>
Please use actual Facebook video URL.
</div>

</body>
</html>
''';
        }

        String cleanUrl =
            url.replaceFirst('m.facebook.com', 'www.facebook.com').trim();

        String? videoId;

        try {
          final uri = Uri.parse(cleanUrl);

          // =========================
          // WATCH URL
          // =========================
          videoId = uri.queryParameters['v'];

          // =========================
          // PATH SEGMENTS
          // =========================
          if (videoId == null || videoId.isEmpty) {
            final segments =
                uri.pathSegments.where((e) => e.isNotEmpty).toList();

            for (int i = 0; i < segments.length; i++) {
              final segment = segments[i];

              if ((segment == 'videos' ||
                      segment == 'reel' ||
                      segment == 'watch' ||
                      segment == 'v') &&
                  i + 1 < segments.length) {
                videoId = segments[i + 1];
                break;
              }
            }
          }

          // =========================
          // FB.WATCH SUPPORT
          // =========================
          if ((videoId == null || videoId.isEmpty) &&
              uri.host.contains('fb.watch')) {
            final segments =
                uri.pathSegments.where((e) => e.isNotEmpty).toList();

            if (segments.isNotEmpty) {
              cleanUrl = 'https://fb.watch/${segments.first}/';
            }
          }
        } catch (e) {
          debugPrint('Facebook parse error: $e');
        }

        // =========================
        // STABLE FACEBOOK URL
        // =========================
        if (videoId != null && videoId.isNotEmpty) {
          cleanUrl = 'https://www.facebook.com/video.php?v=$videoId';
        }

        final embedUrl = 'https://www.facebook.com/plugins/video.php'
            '?href=${Uri.encodeComponent(cleanUrl)}'
            '&show_text=false'
            '&autoplay=true'
            '&mute=true'
            '&controls=true'
            '&allowfullscreen=true';

        debugPrint('========================');
        debugPrint('Facebook Original URL: $url');
        debugPrint('Facebook Clean URL: $cleanUrl');
        debugPrint('Facebook Embed URL: $embedUrl');
        debugPrint('========================');

        return embedUrl;
      }

      // =========================
      // INSTAGRAM
      // =========================
      else if (url.contains('instagram.com')) {
        final cleanUrl = url.split('?').first;

        final base = cleanUrl.endsWith('/') ? cleanUrl : '$cleanUrl/';

        return '${base}embed';
      }
    } catch (e) {
      debugPrint('Embed URL Error: $e');
    }

    return url;
  }

  String _extractYoutubeId(String url) {
    final regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    if (match != null &&
        match.group(7) != null &&
        match.group(7)!.length == 11) {
      return match.group(7)!;
    }

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
    if (kIsWeb) {
      return HtmlElementView(viewType: _viewId);
    }

    if (_webController != null) {
      return WebViewWidget(controller: _webController!);
    }

    return Container(
      color: Colors.black87,
      child: const Center(
        child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 48),
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.black,
                      child: item.isVideo
                          ? (item.isExternalVideo
                              ? (isFacebookUrl(item.fileUrl)
                                  ? _FacebookVideoPreview(url: item.fileUrl)
                                  : _SocialVideoEmbed(link: item.fileUrl))
                              : _InlineVideoPlayer(
                                  url: item.fileUrl,
                                  thumbnail: item.thumbOrFile))
                          : Image.network(item.thumbOrFile ?? item.fileUrl,
                              fit: BoxFit.cover),
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
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.8),
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

class _ExternalVideoPreview extends StatelessWidget {
  const _ExternalVideoPreview({required this.item});
  final EventMediaItem item;

  @override
  Widget build(BuildContext context) {
    final thumb = item.thumbnailUrl ?? item.youtubeThumbnail;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumb != null)
          Image.network(thumb, fit: BoxFit.cover)
        else
          Container(color: Colors.black87),
        Container(
          color: Colors.black26,
          child: Center(
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Colors.white70,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.isYouTube
                    ? Icons.play_circle_filled_rounded
                    : item.isFacebook
                        ? Icons.facebook
                        : Icons.play_arrow_rounded,
                size: 36,
                color: item.isYouTube ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.open_in_new_rounded,
                    size: 10, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  item.isYouTube ? 'WATCH ON YOUTUBE' : 'OPEN VIDEO',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
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

  String? _errorDetail;

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
      _errorDetail = null;
      _setupController();
    }
  }

  void _setupController() {
    if (widget.url.isEmpty) return;
    final uri = Uri.tryParse(widget.url);
    if (uri == null) {
      _hasError = true;
      _errorDetail = 'Invalid URL';
      return;
    }
    final controller = VideoPlayerController.networkUrl(uri)
      ..setLooping(true)
      ..setVolume(0);
    _initializeFuture = controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _hasError = false;
        _errorDetail = null;
      });
      controller.play();
    }).catchError((error) {
      debugPrint('Inline video failed: $error');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorDetail = error.toString();
        });
      }
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
      return _VideoPlaceholder(
        thumbnail: widget.thumbnail,
        error: _errorDetail,
      );
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
  const _VideoPlaceholder({this.thumbnail, this.error});

  final String? thumbnail;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumbnail != null && thumbnail!.isNotEmpty)
          Image.network(
            thumbnail!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(context),
          )
        else
          _fallback(context),
        if (error != null)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.white, fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _fallback(BuildContext context) => Container(
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
  String? _errorDetail;

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
            setState(() {
              _errorDetail = null;
            });
            controller.play();
          }
        }).catchError((error) {
          debugPrint('Preview video failed: $error');
          if (mounted) {
            setState(() {
              _errorDetail = error.toString();
            });
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
    if (controller == null || _errorDetail != null) {
      return _VideoPlaceholder(
        thumbnail: widget.item.thumbOrFile,
        error: _errorDetail,
      );
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
