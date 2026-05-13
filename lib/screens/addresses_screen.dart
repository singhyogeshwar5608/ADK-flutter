import 'package:flutter/material.dart';

import '../models/stored_address.dart';
import '../services/address_storage_service.dart';
import '../state/profile_state.dart';
import '../theme/app_theme.dart';
import 'address_form_screen.dart';

class AddressesScreenArgs {
  const AddressesScreenArgs({this.selectForCheckout = false});

  /// When true, each card shows "Use for checkout" (writes override + pops).
  final bool selectForCheckout;
}

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  static const routeName = '/addresses';

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<StoredAddress> _list = [];
  bool _loading = true;

  String? get _userId {
    final id = ProfileProvider.of(context, listen: false).data.partnerId.trim();
    return id.isEmpty ? null : id;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final next = await AddressStorageService.instance.listForUserId(_userId);
    if (!mounted) return;
    setState(() {
      _list = next;
      _loading = false;
    });
  }

  bool get _selectMode {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is AddressesScreenArgs && args.selectForCheckout;
  }

  Future<void> _openForm([StoredAddress? existing]) async {
    final changed = await Navigator.of(context).pushNamed(
      AddressFormScreen.routeName,
      arguments: AddressFormRouteArgs(
        existing: existing,
        userId: _userId,
      ),
    );
    if (changed == true && mounted) await _reload();
  }

  Future<void> _delete(StoredAddress a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete address'),
        content: Text('Remove "${a.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AddressStorageService.instance.deleteAddress(a.id, userId: _userId);
    await _reload();
  }

  Future<void> _setDefault(StoredAddress a) async {
    final uid = _userId;
    if (uid == null) return;
    await AddressStorageService.instance.setDefaultAddress(a.id, uid);
    await _reload();
  }

  Future<void> _useForCheckout(StoredAddress a) async {
    await AddressStorageService.instance
        .writeCheckoutShippingOverride(a.toShippingDetailsPayload());
    await AddressStorageService.instance.markAddressUsed(a.id, userId: _userId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checkout delivery address updated.')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor:
          theme.brightness == Brightness.dark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Saved addresses'),
        centerTitle: true,
      ),
      floatingActionButton: _list.length >= AddressStorageService.maxSavedAddresses
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openForm(null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add address'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reload,
              child: _list.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 48),
                        Icon(Icons.location_off_outlined,
                            size: 56, color: cs.onSurface.withValues(alpha: 0.35)),
                        const SizedBox(height: 16),
                        Text(
                          'No saved addresses yet',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add at least two addresses to continue to checkout.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.65),
                            height: 1.4,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final a = _list[index];
                        return _AddressCard(
                          address: a,
                          showDefaultToggle: _userId != null,
                          selectMode: _selectMode,
                          onEdit: () => _openForm(a),
                          onDelete: () => _delete(a),
                          onSetDefault: () => _setDefault(a),
                          onUseCheckout: () => _useForCheckout(a),
                        );
                      },
                    ),
            ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.showDefaultToggle,
    required this.selectMode,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
    required this.onUseCheckout,
  });

  final StoredAddress address;
  final bool showDefaultToggle;
  final bool selectMode;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;
  final VoidCallback onUseCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final border = isDark ? const Color(0xFF2A3A52) : const Color(0xFFE2E8F0);

    final n = address.name.trim();
    final initials =
        n.isEmpty ? '?' : n.substring(0, 1).toUpperCase();

    return Material(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: cs.primary.withValues(alpha: 0.15),
                  foregroundColor: cs.primary,
                  child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              address.name,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (address.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Default',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${address.addressLine}\n${address.city}, ${address.state} ${address.pincode}\n${address.phone}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.45,
                          color: cs.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (selectMode)
                  FilledButton.tonal(
                    onPressed: onUseCheckout,
                    child: const Text('Use for checkout'),
                  ),
                if (showDefaultToggle)
                  TextButton(
                    onPressed: address.isDefault ? null : onSetDefault,
                    child: const Text('Set default'),
                  ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                  label: Text('Delete', style: TextStyle(color: cs.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
