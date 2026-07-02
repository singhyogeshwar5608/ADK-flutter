import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import 'safe_network_image.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  late final PageController _pageController;

  static const _autoPlayInterval = Duration(seconds: 5);

  /// Shown when API fails, is empty, or returns no usable slides.
  static const List<_BannerData> _fallbackBanners = [
    _BannerData(
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuCNES-N6nAEUoiY4qmg7xA5FSsCiP_2kXiEL4lWvv6vQmda-H2TT7vfrwvGSdpHK9UdsTb3mnFLqb9oytZWIbAXOTIGuzxVqnDtzAAzx9bdCfOt1fD_jZi9eN8HcPfM1T4qUbHzNEBl7sd_IIRlZAMKZFCsBMbCvyYnkPckk7oMEV0wA1SUxEx-twDTQfJh9Rnk-gTZnliizbh5cyQhONi0fFqLIkpnAEzBkYEJ5VCT_-FBBcXcqvQw83t5wMWBvYID3Hetp3EEUiI',
    ),
    _BannerData(
      imageUrl:
          'https://images.unsplash.com/photo-1470246973918-29a93221c455?auto=format&fit=crop&w=1400&q=80',
    ),
    _BannerData(
      imageUrl:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1400&q=80',
    ),
  ];

  List<_BannerData> _banners = const [];
  bool _loading = true;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _loadSlides();
  }

  Future<void> _loadSlides() async {
    try {
      final slides = await ApiClient.instance.fetchActiveHeroSlides();
      if (!mounted) return;
      final mapped = slides
          .map((s) => _BannerData(imageUrl: s.imageUrl))
          .toList(growable: false);
      setState(() {
        _banners = mapped;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _banners = [];
        _loading = false;
      });
    }
    _restartAutoPlay();
  }

  void _restartAutoPlay() {
    _timer?.cancel();
    _timer = null;
    if (!mounted || _banners.length <= 1) return;
    _timer = Timer.periodic(_autoPlayInterval, (_) {
      if (!mounted || _banners.isEmpty) return;
      if (!_pageController.hasClients) return;
      setState(() {
        _currentPage = (_currentPage + 1) % _banners.length;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 380;
        final requiresMinHeight = width < 560;
        final minHeight = isCompact ? 190.0 : 220.0;

        if (_loading) {
          return SizedBox(
            height: minHeight,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (_banners.isEmpty) {
          return SizedBox(
            height: minHeight,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No banners yet uploaded from admin panel',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        Widget buildBanner(int index, _BannerData data) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = (_pageController.page! - index).abs();
                value = (1 - (value * 0.08)).clamp(0.92, 1.0);
              } else {
                value = index == _currentPage ? 1.0 : 0.92;
              }
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeNetworkImage(src: data.imageUrl, fit: BoxFit.fill),
                  ],
                ),
              ),
            ),
          );
        }

        final slider = Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _banners.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (_, index) => buildBanner(index, _banners[index]),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < _banners.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _currentPage ? 14 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

        if (requiresMinHeight) {
          return SizedBox(height: minHeight, child: slider);
        }

        return AspectRatio(aspectRatio: 21 / 9, child: slider);
      },
    );
  }
}

class _BannerData {
  const _BannerData({required this.imageUrl});

  final String imageUrl;
}
