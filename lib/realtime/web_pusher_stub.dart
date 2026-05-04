class WebPusherHandle {}

Future<WebPusherHandle?> initWebPusher({
  required String appKey,
  required String channelName,
  required Iterable<String> eventNames,
  required String host,
  required int port,
  required bool encrypted,
  required void Function(String eventName) onEvent,
}) async {
  return null;
}

void disposeWebPusher(WebPusherHandle? handle) {}
