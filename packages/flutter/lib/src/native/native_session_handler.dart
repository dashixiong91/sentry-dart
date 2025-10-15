// ignore_for_file: invalid_use_of_internal_member, implementation_imports

import "package:sentry/src/sentry_envelope_header.dart";
import "package:sentry/src/sentry_envelope_item_header.dart";

import '../../sentry_flutter.dart';
import 'native_session.dart';

class NativeSessionHandler {
  final Hub _hub;
  NativeSessionHandler(this._hub);

  Session? _session;

  SentryFlutterOptions get _options => _hub.options as SentryFlutterOptions;

  void startSession() {
    if (_session != null) {
      return;
    }
    final release = _options.release;
    if (release == null) {
      return;
    }
    _session =
        Session.initial(environment: _options.environment, release: release);
    _captureSession(_session!);
  }

  Future<void> updateSessionFromEvent(SentryEvent event) async {
    final session = _session;
    if (session == null) {
      return;
    }
    final user = event.user;
    if (user != null) {
      session.update(user: user);
    }
    final exceptions = event.exceptions;
    if (exceptions == null || exceptions.isEmpty) {
      return;
    }

    bool crashed = event.level == SentryLevel.fatal;
    for (final exception in exceptions) {
      if (exception.mechanism?.handled == false) {
        crashed = true;
        break;
      }
    }
    session.update(
        status: crashed ? SessionState.crashed : null, addErrorsCount: true);
  }

  void endSession() {
    final session = _session;
    if (session == null) {
      return;
    }
    session.end();
    _session = null;
    _captureSession(session);
  }

  Future<void> _captureSession(Session session) async {
    if (!_hub.isEnabled) {
      _options.log(
        SentryLevel.warning,
        "hub is disabled and this 'captureSession' call is a no-op.",
      );
      return;
    }
    if (session.release.isEmpty) {
      _options.log(SentryLevel.warning,
          "Sessions can't be captured without setting a release.");
      return;
    }
    try {
      final envelope = _fromSession(session);
      await _captureEnvelope(envelope);
    } catch (exception, stackTrace) {
      _options.log(
        SentryLevel.error,
        'Failed to capture session.',
        exception: exception,
        stackTrace: stackTrace,
      );
      if (_options.automatedTestMode) {
        rethrow;
      }
    }
  }

  Future<SentryId?> _captureEnvelope(SentryEnvelope envelope) {
    return _options.transport.send(envelope);
  }

  SentryEnvelope _fromSession(Session session) {
    return SentryEnvelope(SentryEnvelopeHeader(null, _options.sdk), [
      SentryEnvelopeItem(
        SentryEnvelopeItemHeader("session", contentType: 'application/json'),
        () => utf8JsonEncoder.convert(session.toJson()),
      )
    ]);
  }
}
