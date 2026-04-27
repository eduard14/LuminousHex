import 'package:flutter/foundation.dart';

class LightcoreWebForegroundSubscription {
  const LightcoreWebForegroundSubscription();

  void cancel() {}
}

LightcoreWebForegroundSubscription listenForLightcoreWebForeground(
  VoidCallback onForeground,
) {
  return const LightcoreWebForegroundSubscription();
}
