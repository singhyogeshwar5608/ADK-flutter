import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pusher_reverb_flutter/pusher_reverb_flutter.dart';

/// Mobile / desktop: Laravel Reverb realtime for catalog updates (Pusher protocol).
class ProductCatalogRealtime {
  static const _channelName = 'members.products';

  Channel? _channel;
  final Map<String, ChannelEventListener> _handlers = {};
  bool _connected = false;

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

    final reverbHost = dotenv.env['REVERB_HOST'] ?? '127.0.0.1';
    final port = int.tryParse(dotenv.env['REVERB_PORT'] ?? '80') ?? 80;
    final scheme = dotenv.env['REVERB_SCHEME'] ?? 'http';
    final useTLS = scheme == 'https';

    ReverbClient.resetInstance();

    try {
      final client = ReverbClient.instance(
        host: reverbHost,
        port: port,
        appKey: appKey,
        useTLS: useTLS,
        onError: (error) {
          debugPrint('Reverb connection error: $error');
        },
      );

      await client.connect();

      await client.onConnectionStateChange
          .firstWhere((s) => s == ConnectionState.connected)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Reverb handshake'),
          );

      _channel = client.subscribeToChannel(_channelName);

      for (final eventName in eventNames) {
        final name = eventName.toString();
        void listener(String event, dynamic data) {
          if (event.startsWith('products.')) {
            onProductEvent();
          }
        }

        _channel!.bind(name, listener);
        _handlers[name] = listener;
      }

      _connected = true;
      return true;
    } catch (e, stack) {
      debugPrint('Reverb realtime connect failed: $e');
      debugPrintStack(stackTrace: stack);
      ReverbClient.resetInstance();
      _channel = null;
      _handlers.clear();
      return false;
    }
  }

  void dispose() {
    if (!_connected) return;

    final client = ReverbClient.instance();

    if (_channel != null) {
      for (final e in _handlers.entries) {
        _channel!.unbind(e.key, e.value);
      }
    }
    _handlers.clear();

    client.unsubscribeFromChannel(_channelName);
    _channel = null;
    client.disconnect();
    ReverbClient.resetInstance();

    _connected = false;
  }
}
