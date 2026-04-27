// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

class LightcoreWebForegroundSubscription {
  LightcoreWebForegroundSubscription(this._subscriptions);

  final List<StreamSubscription<dynamic>> _subscriptions;

  void cancel() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
  }
}

LightcoreWebForegroundSubscription listenForLightcoreWebForeground(
  VoidCallback onForeground,
) {
  var lastForegroundAt = DateTime.fromMillisecondsSinceEpoch(0);

  void notifyForeground() {
    if (html.document.visibilityState == 'hidden') {
      return;
    }
    final now = DateTime.now();
    if (now.difference(lastForegroundAt) < const Duration(milliseconds: 400)) {
      return;
    }
    lastForegroundAt = now;
    onForeground();
  }

  return LightcoreWebForegroundSubscription(<StreamSubscription<dynamic>>[
    html.window.onFocus.listen((_) => notifyForeground()),
    html.window.onPageShow.listen((_) => notifyForeground()),
    html.document.onVisibilityChange.listen((_) => notifyForeground()),
  ]);
}
