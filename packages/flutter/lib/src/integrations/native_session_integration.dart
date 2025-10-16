// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';

import 'package:meta/meta.dart';

import '../../sentry_flutter.dart';
import '../native/native_session_handler.dart';

/// 原生会话跟踪插件，移除原生依赖以后需自行实现
class NativeSessionIntegration implements Integration<SentryFlutterOptions> {
  static const integrationName = 'NativeSessionIntegration';
  SentryFlutterOptions? _options;
  NativeSessionHandler? _nativeSessionHandler;
  NativeSessionHandler? get nativeSessionHandler => _nativeSessionHandler;
  SdkLifecycleCallback<OnBeforeSendEvent>? _onBeforeSendEventCallback;
  @visibleForTesting
  SdkLifecycleCallback<OnBeforeSendEvent>? get onBeforeSendEventCallback =>
      _onBeforeSendEventCallback;
  @override
  void call(Hub hub, SentryFlutterOptions options) {
    if (!options.enableAutoSessionTracking) {
      return;
    }
    _options = options;
    _nativeSessionHandler = NativeSessionHandler(options,hub);
    _onBeforeSendEventCallback = (lifecycleEvent) {
      _nativeSessionHandler?.updateSessionFromEvent(lifecycleEvent.event);
    };
    _options?.lifecycleRegistry
        .registerCallback<OnBeforeSendEvent>(_onBeforeSendEventCallback!);
    _options?.sdk.addIntegration(integrationName);
    _nativeSessionHandler?.startSession();
  }

  @override
  FutureOr<void> close() {
    if (_onBeforeSendEventCallback != null) {
      _options?.lifecycleRegistry
          .removeCallback<OnBeforeSendEvent>(_onBeforeSendEventCallback!);
    }
  }
}
