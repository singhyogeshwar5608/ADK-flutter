import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;

/// Real implementation for web platform view registration.
void registerWebView(String viewId, String url) {
  ui.platformViewRegistry.registerViewFactory(
    viewId,
    (int viewId) => web.HTMLIFrameElement()
      ..src = url
      ..style.border = 'none'
      ..width = '100%'
      ..height = '100%'
      ..allow = "autoplay; encrypted-media; fullscreen"
  );
}
