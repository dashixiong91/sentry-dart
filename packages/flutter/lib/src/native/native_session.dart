// ignore_for_file: invalid_use_of_internal_member

import 'package:uuid/uuid.dart';

import '../../sentry_flutter.dart';

enum SessionState { ok, exited, crashed, abnormal }

// 会话模型，移除原生依赖之后，不再依赖原生发送会话
class Session {
  final DateTime started;
  DateTime? timestamp;
  int errorCount;
  final String distinctId;
  final String sessionId;
  bool? init;
  SessionState status;
  int? sequence;
  double? duration;
  String? ipAddress;
  String? userAgent;
  final String? environment;
  final String release;
  String? abnormalMechanism;
  Map<String, dynamic>? unknown;

  Session({
    required this.status,
    required this.started,
    this.timestamp,
    required this.errorCount,
    required this.distinctId,
    required this.sessionId,
    this.init,
    this.sequence,
    this.duration,
    this.ipAddress,
    this.userAgent,
    this.environment,
    required this.release,
    this.abnormalMechanism,
  });

  factory Session.initial({
    required String distinctId,
    SentryUser? user,
    String? environment,
    required String release,
  }) {
    final now = getUtcDateTime();
    return Session(
      status: SessionState.ok,
      started: now,
      timestamp: now,
      errorCount: 0,
      distinctId: distinctId,
      sessionId: const Uuid().v4().replaceAll('-', ''),
      init: true,
      ipAddress: user?.ipAddress,
      environment: environment,
      release: release,
    );
  }

  bool get isTerminated => status != SessionState.ok;

  void end([DateTime? timestamp]) {
    init = false;
    if (status == SessionState.ok) {
      status = SessionState.exited;
    }

    this.timestamp = timestamp ?? getUtcDateTime();

    if (this.timestamp != null) {
      duration = _calculateDuration(this.timestamp!);
      sequence = _getSequenceTimestamp(this.timestamp!);
    }
  }

  double _calculateDuration(DateTime timestamp) {
    return timestamp.difference(started).inSeconds.abs().toDouble();
  }

  bool update({
    SessionState? status,
    String? userAgent,
    bool addErrorsCount = false,
    String? abnormalMechanism,
    SentryUser? user,
  }) {
    var updated = false;

    if (status != null) {
      this.status = status;
      updated = true;
    }

    if (userAgent != null) {
      this.userAgent = userAgent;
      updated = true;
    }

    if (addErrorsCount) {
      errorCount++;
      updated = true;
    }

    if (abnormalMechanism != null) {
      this.abnormalMechanism = abnormalMechanism;
      updated = true;
    }
    if (user != null && user.ipAddress != null) {
      ipAddress = user.ipAddress;
      updated = true;
    }

    if (updated) {
      init = false;
      timestamp = getUtcDateTime();
      if (timestamp != null) {
        sequence = _getSequenceTimestamp(timestamp!);
      }
    }
    return updated;
  }

  int _getSequenceTimestamp(DateTime timestamp) {
    return timestamp.millisecondsSinceEpoch.abs();
  }

  Session clone() => Session(
        status: status,
        started: started,
        timestamp: timestamp,
        errorCount: errorCount,
        distinctId: distinctId,
        sessionId: sessionId,
        init: init,
        sequence: sequence,
        duration: duration,
        ipAddress: ipAddress,
        userAgent: userAgent,
        environment: environment,
        release: release,
        abnormalMechanism: abnormalMechanism,
      );

  Map<String, dynamic> toJson() {
    return {
      'sid': sessionId,
      'did': distinctId,
      if (init != null) 'init': init,
      'started': formatDateAsIso8601WithMillisPrecision(started),
      'status': status.name,
      if (sequence != null) 'seq': sequence,
      'errors': errorCount,
      if (duration != null) 'duration': duration,
      if (timestamp != null)
        'timestamp': formatDateAsIso8601WithMillisPrecision(timestamp!),
      if (abnormalMechanism != null) 'abnormal_mechanism': abnormalMechanism,
      'attrs': {
        'release': release,
        if (environment != null) 'environment': environment,
        if (ipAddress != null) 'ip_address': ipAddress,
        if (userAgent != null) 'user_agent': userAgent,
      },
      ...?unknown,
    };
  }
}
