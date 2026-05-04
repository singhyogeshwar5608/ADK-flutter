import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../screens/cart_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../state/cart_state.dart';
import '../state/profile_state.dart';
import '../services/api_client.dart';

class HeaderWidget extends StatefulWidget {
  const HeaderWidget({super.key});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget>
    with SingleTickerProviderStateMixin {
  final GlobalKey _menuButtonKey = GlobalKey();
  final LayerLink _menuLayerLink = LayerLink();
  OverlayEntry? _menuOverlay;
  late final AnimationController _menuController;
  static const double _menuWidth = 220;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _dismissMenu(removeOverlay: true);
    _menuController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_menuOverlay != null) {
      _dismissMenu();
    } else {
      _showMenu();
    }
  }

  void _showMenu() {
    final overlay = Overlay.of(context);
    final renderBox =
        _menuButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final buttonSize = renderBox.size;
    final origin = renderBox.localToGlobal(Offset.zero);
    final screenWidth = MediaQuery.of(context).size.width;
    final initialDx = -_menuWidth + buttonSize.width;
    final menuLeft = origin.dx + initialDx;
    const horizontalMargin = 16.0;
    final maxLeft = screenWidth - horizontalMargin - _menuWidth;
    final clampedLeft = menuLeft.clamp(horizontalMargin, maxLeft);
    final dx = clampedLeft - origin.dx;
    final offset = Offset(dx, buttonSize.height + 8);

    final profileState = ProfileProvider.of(context, listen: false);
    final menuOptions = _menuOptions(profileState.isAuthenticated);

    _menuController.forward(from: 0);
    _menuOverlay = OverlayEntry(
      builder: (context) {
        final slideAnimation =
            Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: _menuController, curve: Curves.easeOut));
        final fadeAnimation =
            CurvedAnimation(parent: _menuController, curve: Curves.easeOut);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _dismissMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _menuLayerLink,
              showWhenUnlinked: false,
              offset: offset,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: _KebabMenu(
                    onItemTap: _handleMenuAction,
                    width: _menuWidth,
                    options: menuOptions,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_menuOverlay!);
  }

  void _dismissMenu({bool removeOverlay = false}) {
    if (_menuOverlay == null) return;
    if (removeOverlay) {
      _menuOverlay!.remove();
      _menuOverlay = null;
      return;
    }
    _menuController.reverse().whenCompleteOrCancel(() {
      _menuOverlay?.remove();
      _menuOverlay = null;
    });
  }

  Future<void> _handleMenuAction(MenuOption option) async {
    _dismissMenu();
    switch (option) {
      case MenuOption.profile:
        Navigator.of(context).pushNamed(ProfileScreen.routeName);
        return;
      case MenuOption.login:
        Navigator.of(context).pushNamed(LoginScreen.routeName);
        return;
      case MenuOption.signup:
        Navigator.of(context).pushNamed(SignupScreen.routeName);
        return;
      case MenuOption.logout:
        await ApiClient.instance.logout();
        if (!mounted) return;
        ProfileProvider.of(context, listen: false).resetToGuest();
        Navigator.of(context)
            .pushNamedAndRemoveUntil(LoginScreen.routeName, (route) => false);
        return;
    }
  }

  List<MenuOption> _menuOptions(bool isAuthenticated) {
    if (isAuthenticated) {
      return const [MenuOption.profile, MenuOption.logout];
    }
    return const [MenuOption.login, MenuOption.signup];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cartCount = CartProvider.of(context).totalItems;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/img2.png',
                    fit: BoxFit.cover, // fills the circle
                    width: 44,
                    height: 44,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ADK',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  Text(
                    'Asli Desi Kishan',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _IconBadgeButton(
                icon: Icons.shopping_cart_outlined,
                onPressed: () =>
                    Navigator.of(context).pushNamed(CartScreen.routeName),
                badgeCount: cartCount,
              ),
              const SizedBox(width: 12),
              CompositedTransformTarget(
                link: _menuLayerLink,
                child: _IconBadgeButton(
                  icon: Icons.more_vert,
                  onPressed: _toggleMenu,
                  buttonKey: _menuButtonKey,
                  semanticLabel: 'Open quick actions menu',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBadgeButton extends StatelessWidget {
  const _IconBadgeButton({
    required this.icon,
    this.onPressed,
    this.buttonKey,
    this.semanticLabel,
    this.badgeCount,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Key? buttonKey;
  final String? semanticLabel;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final button = Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        key: buttonKey,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(icon),
          color: Theme.of(context).colorScheme.onSurface,
          onPressed: onPressed ?? () {},
        ),
      ),
    );

    final count = badgeCount;
    if (count == null || count <= 0) {
      return button;
    }

    final text = count > 99 ? '99+' : '$count';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KebabMenu extends StatelessWidget {
  const _KebabMenu(
      {required this.onItemTap, required this.width, required this.options});

  final ValueChanged<MenuOption> onItemTap;
  final double width;
  final List<MenuOption> options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = options;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.5 : 0.15),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final option in entries)
              _MenuEntry(
                option: option,
                onTap: () => onItemTap(option),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuEntry extends StatefulWidget {
  const _MenuEntry({required this.option, required this.onTap});

  final MenuOption option;
  final VoidCallback onTap;

  @override
  State<_MenuEntry> createState() => _MenuEntryState();
}

class _MenuEntryState extends State<_MenuEntry> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = _isHovered
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(widget.option.icon,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                widget.option.label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum MenuOption { profile, login, signup, logout }

extension on MenuOption {
  String get label {
    switch (this) {
      case MenuOption.profile:
        return 'Profile';
      case MenuOption.login:
        return 'Login';
      case MenuOption.signup:
        return 'Sign up';
      case MenuOption.logout:
        return 'Logout';
    }
  }

  IconData get icon {
    switch (this) {
      case MenuOption.profile:
        return Icons.person_outline;
      case MenuOption.login:
        return Icons.login;
      case MenuOption.signup:
        return Icons.person_add_alt_1;
      case MenuOption.logout:
        return Icons.logout;
    }
  }
}
