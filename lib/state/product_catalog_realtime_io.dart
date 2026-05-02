import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pusher_client/pusher_client.dart';

/// Mobile / desktop: Reverb / Pusher realtime for catalog updates.
class ProductCatalogRealtime {
  PusherClient? _pusher;
  Channel? _channel;
  bool _connected = false;
  List<String> _boundEvents = const [];

  Future<bool> connect({
    required void Function() onProductEvent,
    required Iterable<String> eventNames,
  }) async {
    if (_connected) return true;

    final appKey = dotenv.env['REVERB_APP_KEY'];
    if (appKey == null || appKey.isEmpty) {
      debugPrint('REVERB_APP_KEY missing; realtime disabled.');
      return false;
    }

    final host = dotenv.env['REVERB_HOST'] ?? '127.0.0.1';
    final port = int.tryParse(dotenv.env['REVERB_PORT'] ?? '80') ?? 80;
    final scheme = dotenv.env['REVERB_SCHEME'] ?? 'http';
    final encrypted = scheme == 'https';
    final options = PusherOptions(
      host: host,
      wsPort: port,
      wssPort: port,
      encrypted: encrypted,
      cluster: 'mt1',
    );

    final pusher = PusherClient(
      appKey,
      options,
      autoConnect: false,
      enableLogging: false,
    );

    pusher.onConnectionStateChange((state) {
      debugPrint('Pusher state: ${state?.currentState}');
    });

    pusher.onConnectionError((error) {
      debugPrint('Pusher connection error: $error');
    });

    pusher.connect();

    final channel = pusher.subscribe('members.products');
    _boundEvents = eventNames.map((e) => e.toString()).toList(growable: false);
    for (final eventName in _boundEvents) {
      channel.bind(eventName, (PusherEvent? event) {
        final name = event?.eventName ?? '';
        if (name.startsWith('products.')) {
          onProductEvent();
        }
      });
    }

    _pusher = pusher;
    _channel = channel;
    _connected = true;
    return true;
  }

  void dispose() {
    if (!_connected) return;
    const channelName = 'members.products';
    for (final name in _boundEvents) {
      _channel?.unbind(name);
    }
    _pusher?.unsubscribe(channelName);
    _pusher?.disconnect();
    _pusher = null;
    _channel = null;
    _boundEvents = const [];
    _connected = false;
  }
}
